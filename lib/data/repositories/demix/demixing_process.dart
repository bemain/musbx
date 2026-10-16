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
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/process.dart';

/// The stages a [DemixingProcess] passes through, in order.
enum DemixingStep {
  /// The API is looking for an available host with the correct version.
  findingHost,

  /// The song is being uploaded to the server.
  uploading,

  /// The server has begun separating the song into parts.
  separating,

  /// The server is compressing the part files.
  compressing,

  /// The part files are being downloaded.
  downloading,
}

/// Upload, separate and download part files for a [song].
class DemixingProcess extends Process<Map<Part, CacheFile>> {
  DemixingProcess(
    this.song, {
    required SongCache cache,
    this.checkStatusInterval = const Duration(milliseconds: 300),
  }) : _cache = cache;

  final Song song;

  final Duration checkStatusInterval;

  final SongCache _cache;

  /// The progress of the current step.
  /// Should be a value between `0.0` and `1.0`.
  double? get stepProgress => stepProgressNotifier.value;
  late final ValueNotifier<double?> stepProgressNotifier = ValueNotifier(null)
    ..addListener(_updateProgress);

  /// The current step of the demixing process.
  DemixingStep get step => stepNotifier.value;
  late final ValueNotifier<DemixingStep> stepNotifier =
      ValueNotifier(DemixingStep.findingHost)
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

  @override
  Future<Map<Part, CacheFile>> execute() async {
    stepNotifier.value = DemixingStep.findingHost;

    if (await _cache.parts(song) case final cached?) return cached;

    breakIfCancelled();

    final MusbxApiClient client = await MusbxApi.getClient();

    breakIfCancelled();

    stepNotifier.value = DemixingStep.uploading;

    // Upload song to server
    final FileHandle file;
    switch (song.audio) {
      case FileAudio() || BytesAudio():
        file = await client.uploadFile(
          File(_cache.audio(song).path),
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

    // Download part files
    stepNotifier.value = DemixingStep.downloading;
    stepProgressNotifier.value = 0;

    /// The progress of each of the download operations.
    Map<String, double> downloadProgress = {};

    final Map<Part, CacheFile> files = Map.fromEntries(
      await Future.wait(
        report.result!.keys.map((partName) async {
          final Part part =
              Part.values.asNameMap()[partName] ?? (throw MalformedResponse());

          final response = await job.dio.get<List<int>>(
            report.result![partName]!,
            onReceiveProgress: (received, total) {
              downloadProgress[partName] = received / total;
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

          final data = response.data ?? (throw MalformedResponse());

          final CacheFile destination = _cache.part(song, part);
          await destination.writeBytes(data);

          return MapEntry(
            part,
            destination,
          );
        }),
      ),
    );

    breakIfCancelled();

    return files;
  }
}
