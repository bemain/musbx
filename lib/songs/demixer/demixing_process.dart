import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/musbx_api/client.dart';
import 'package:musbx/songs/musbx_api/jobs/demix.dart';
import 'package:musbx/songs/musbx_api/jobs/job.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/process.dart';

enum DemixingStep {
  /// The cache is being checked to see if stem files are available there.
  checkingCache,

  /// The API is looking for an available host with the correct version.
  findingHost,

  /// The song is being uploaded to the server.
  uploading,

  /// The server has begun separating the song into stems.
  separating,

  /// The server is compressing the stem files.
  compressing,

  /// The stem files are being downloaded.
  downloading,
}

class DemixingProcess extends Process<Map<StemType, File>> {
  /// Upload, separate and download stem files for a song.
  ///
  /// TODO: Improve progress tracking for upload.
  DemixingProcess(
    this.parentSource, {
    required this.cacheDirectory,
    this.checkStatusInterval = const Duration(seconds: 1),
  });

  final SongSource parentSource;

  final Directory cacheDirectory;

  final Duration checkStatusInterval;

  /// The current step of the demixing process.
  DemixingStep get step => stepNotifier.value;
  final ValueNotifier<DemixingStep> stepNotifier = ValueNotifier(
    DemixingStep.checkingCache,
  );

  /// Get stems for the song, if all stems (see [StemType]) were found with the correct [fileExtension].
  Future<Map<StemType, File>?> getStemsInCache({
    String fileExtension = "mp3",
  }) async {
    List<File> stemFiles = StemType.values
        .map(
          (stem) => File("${cacheDirectory.path}/${stem.name}.$fileExtension"),
        )
        .toList();
    if ((await Future.wait(
      stemFiles.map((stem) => stem.exists()),
    )).every((value) => value)) {
      // All stems were found in the cache.
      return {
        for (final stem in StemType.values)
          stem: File("${cacheDirectory.path}/${stem.name}.$fileExtension"),
      };
    }

    return null;
  }

  @override
  Future<Map<StemType, File>> execute() async {
    // Try to grab stems from cache
    stepNotifier.value = DemixingStep.checkingCache;

    Map<StemType, File>? cachedStemFiles = await getStemsInCache();
    if (cachedStemFiles != null) {
      debugPrint("[DEMIXER] Using cached stems for song.");

      return cachedStemFiles;
    }

    stepNotifier.value = DemixingStep.findingHost;

    final MusbxApiClient client = await MusbxApi.getClient();

    breakIfCancelled();

    stepNotifier.value = DemixingStep.uploading;

    // Upload song to server
    final SongSource source = parentSource;
    final FileHandle file;
    switch (source) {
      case FileSource():
        file = await client.uploadFile(source.cacheFile!);
      case YtdlpSource():
        file = await client.uploadYtdlp(source.url);
      default:
        throw UnsupportedError(
          "Chord analysis cannot be performed on the source $source.",
        );
    }

    breakIfCancelled();

    // Wait for demixing job to complete
    stepNotifier.value = DemixingStep.separating;

    final DemixJob job = await client.demix(file);

    DemixJobReport report = await job.get();
    while (report.status == JobStatus.running) {
      stepNotifier.value = switch (report.step) {
        DemixStep.idle ||
        DemixStep.loadingModel ||
        DemixStep.demixing => DemixingStep.separating,
        DemixStep.saving => DemixingStep.compressing,
      };
      progressNotifier.value = report.progress;

      await Future<void>.delayed(checkStatusInterval); // Short delay
      breakIfCancelled();

      report = await job.get();
    }

    if (report.hasError) throw report.error!;
    if (!report.hasResult) {
      throw Exception("Demixing process didn't return a result.");
    }

    progressNotifier.value = null;

    breakIfCancelled();

    // Download stem files
    stepNotifier.value = DemixingStep.downloading;
    progressNotifier.value = 0;

    /// The progress of each of the download operations.
    Map<String, double> downloadProgress = {};

    final Map<StemType, File> files = Map.fromEntries(
      await Future.wait(
        report.result!.keys.map((stemName) async {
          final response = await job.dio.get<List<int>>(
            report.result![stemName]!,
            onReceiveProgress: (received, total) {
              downloadProgress[stemName] = received / total;
              final totalProgress = downloadProgress.values.reduce(
                (a, b) => a + b,
              );
              progressNotifier.value = totalProgress / report.result!.length;
            },
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
            ),
          );

          final File destination = File(
            "${cacheDirectory.path}/$stemName.mp3",
          );

          await destination.writeAsBytes(response.data!);
          return MapEntry(
            StemType.values.firstWhere((stem) => stem.name == stemName),
            destination,
          );
        }),
      ),
    );

    breakIfCancelled();

    return files;
  }
}
