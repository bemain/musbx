import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/jobs/demix.dart';
import 'package:musbx/data/services/musbx_api/jobs/job.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';
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

sealed class DemixingError implements Exception {}

final class NoServerFound extends DemixingError {
  @override
  String toString() =>
      "No Musbx API server capable of demixing could be found";
}

final class ServerError extends DemixingError {
  @override
  String toString() => "The Musbx API server was unable to demix the song";
}

class DemixingProcess extends Process<Map<StemType, CacheFile>> {
  /// Upload, separate and download stem files for a [song].
  DemixingProcess(
    this.song, {
    this.checkStatusInterval = const Duration(milliseconds: 300),
  });

  final Song song;

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
  static Future<Map<StemType, CacheFile>?> getStemsInCache(
    Song song, {

    String fileExtension = "mp3",
  }) async {
    final stems = {
      for (final stem in StemType.values)
        stem: SongCache.instance.stem(song, stem),
    };

    if ((await Future.wait(
      stems.values.map((file) => file.exists()),
    )).every((value) => value)) {
      // All stems were found in the cache.
      return stems;
    }

    return null;
  }

  @override
  Future<Map<StemType, CacheFile>> execute() async {
    // Try to grab stems from cache
    stepNotifier.value = DemixingStep.checkingCache;

    Map<StemType, CacheFile>? cachedStemFiles = await getStemsInCache(song);
    if (cachedStemFiles != null) {
      debugPrint("[DEMIXER] Using cached stems for song.");

      return cachedStemFiles;
    }

    stepNotifier.value = DemixingStep.findingHost;

    final MusbxApiClient client = await MusbxApi.getClient();

    breakIfCancelled();

    stepNotifier.value = DemixingStep.uploading;

    // Upload song to server
    final FileHandle file;
    switch (song.audio) {
      case FileAudio() || BytesAudio():
        file = await client.uploadFile(
          File(SongCache.instance.audio(song).path),
          onSendProgress: (count, total) {
            stepProgressNotifier.value = count / total;
          },
        );
      case UrlAudio(:final url):
        file = await client.uploadYtdlp(url);
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

    if (report.hasError) throw Exception("Demixing failed: ${report.error!}");
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

    final Map<StemType, CacheFile> files = Map.fromEntries(
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

          final StemType stem = StemType.values.firstWhere(
            (stem) => stem.name == stemName,
          );

          final CacheFile destination = SongCache.instance.stem(song, stem);
          await destination.writeBytes(response.data!);

          return MapEntry(
            stem,
            destination,
          );
        }),
      ),
    );

    breakIfCancelled();

    return files;
  }
}
