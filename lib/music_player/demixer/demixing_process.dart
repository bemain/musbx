import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:musbx/music_player/song.dart';

enum DemixingStep {
  /// The API is looking for an available host with the correct version.
  findingHost,

  /// The song is being uploaded to the server.
  uploading,

  /// The server has begun separating the song into stems.
  separating,

  /// The stem files are being downloaded.
  downloading,
}

class DemixingProcess {
  /// A cancellable process that demixes [song].
  DemixingProcess(Song song) {
    future = demixSong(song);
  }

  /// Whether this job has been cancelled.
  bool _cancelled = false;

  /// The future that completes when the song is demixed.
  late final Future<Map<StemType, File>?> future;

  /// The current step of the demixing process.
  DemixingStep get step => stepNotifier.value;
  final ValueNotifier<DemixingStep> stepNotifier =
      ValueNotifier(DemixingStep.uploading);

  /// The progress of the separation, or `null` if [step] is not [DemixingStep.separating].
  int? get separationProgress => separationProgressNotifier.value;
  final ValueNotifier<int?> separationProgressNotifier = ValueNotifier(null);

  /// Cancel this job as soon as possible.
  void cancel() {
    _cancelled = true;
  }

  /// Upload, separate and download stem files for [song].
  Future<Map<StemType, File>?> demixSong(Song song) async {
    stepNotifier.value = DemixingStep.findingHost;

    Host host = await DemixerApi.findHost();

    if (_cancelled) return null;

    stepNotifier.value = DemixingStep.uploading;

    UploadResponse response;
    if (song.source is FileSource) {
      response = await host.uploadFile((song.source as FileSource).file);
    } else {
      response = await host
          .uploadYoutubeSong((song.source as YoutubeSource).youtubeId);
    }

    String songName = response.songName;

    if (_cancelled) return null;

    if (response.jobId != null) {
      stepNotifier.value = DemixingStep.separating;

      var subscription = host.jobProgress(response.jobId!).handleError((error) {
        if (error is! JobNotFoundException) throw error;
      }).listen(null, cancelOnError: true);
      subscription.onData((response) {
        if (_cancelled) {
          subscription.cancel();
        }
        separationProgressNotifier.value = response.progress;
      });

      await subscription.asFuture();
      separationProgressNotifier.value = null;
    }

    if (_cancelled) return null;

    stepNotifier.value = DemixingStep.downloading;

    Map<StemType, File> stemFiles = {};
    for (StemType stem in StemType.values) {
      if (_cancelled) return null;

      stemFiles[stem] = await host.downloadStem(
        songName,
        stem,
        await DemixerApi.stemDirectory,
      );
    }

    if (_cancelled) return null;

    return stemFiles;
  }
}
