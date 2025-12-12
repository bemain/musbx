import 'dart:async';
import 'dart:io';
import 'dart:math';

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
  DemixingProcess(
    this.parentSource, {
    required this.cacheDirectory,
    this.checkStatusInterval = const Duration(milliseconds: 300),
  });

  final SongSource parentSource;

  final Directory cacheDirectory;

  final Duration checkStatusInterval;

  /// The progress of the current step.
  /// Should be a value between `0.0` and `1.0`.
  double? get stepProgress => stepProgressNotifier.value;
  late final ValueNotifier<double?> stepProgressNotifier = ValueNotifier(null)
    ..addListener(_updateProgress);

  /// The current step of the demixing process.
  DemixingStep get step => stepNotifier.value;
  late final ValueNotifier<DemixingStep> stepNotifier =
      ValueNotifier(
          DemixingStep.checkingCache,
        )
        ..addListener(_updateProgress)
        ..addListener(() {
          stepProgressNotifier.value = null;
        });

  void _updateProgress() {
    // We ignore the first two steps as they are almost instantaneous
    final progress = step.index - 2 + (stepProgress ?? 0);
    progressNotifier.value =
        max(0, progress) / (DemixingStep.values.length - 2);
  }

  /// Get stems for the song, if all stems (see [StemType]) were found with the correct [fileExtension].
  static Future<Map<StemType, File>?> getStemsInCache({
    required Directory directory,
    String fileExtension = "mp3",
  }) async {
    List<File> stemFiles = StemType.values
        .map(
          (stem) => File("${directory.path}/${stem.name}.$fileExtension"),
        )
        .toList();
    if ((await Future.wait(
      stemFiles.map((stem) => stem.exists()),
    )).every((value) => value)) {
      // All stems were found in the cache.
      return {
        for (final stem in StemType.values)
          stem: File("${directory.path}/${stem.name}.$fileExtension"),
      };
    }

    return null;
  }

  @override
  Future<Map<StemType, File>> execute() async {
    // Try to grab stems from cache
    stepNotifier.value = DemixingStep.checkingCache;

    Map<StemType, File>? cachedStemFiles = await getStemsInCache(
      directory: cacheDirectory,
    );
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
        file = await client.uploadFile(
          source.cacheFile!,
          onSendProgress: (count, total) {
            stepProgressNotifier.value = count / total;
          },
        );
      case YtdlpSource():
        file = await client.uploadYtdlp(source.url);
      default:
        throw UnsupportedError(
          "Demixing cannot be performed on the source $source.",
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
      stepProgressNotifier.value = report.progress;

      await Future<void>.delayed(checkStatusInterval); // Short delay
      breakIfCancelled();

      report = await job.get();
    }

    if (report.hasError) throw report.error!;
    if (!report.hasResult) {
      throw Exception("Demixing process didn't return a result.");
    }

    stepProgressNotifier.value = null;

    breakIfCancelled();

    // Download stem files
    stepNotifier.value = DemixingStep.downloading;
    stepProgressNotifier.value = 0;

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
              stepProgressNotifier.value =
                  totalProgress / report.result!.length;
            },
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
            ),
          );

          final File destination = File(
            "${cacheDirectory.path}/$stemName.mp3",
          );

          await destination.create(recursive: true);
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
