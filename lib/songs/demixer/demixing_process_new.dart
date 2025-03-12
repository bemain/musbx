import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_source.dart';
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
  /// Upload, separate and download stem files for a [song].
  ///
  /// TODO: Improve progress tracking for upload and download.
  DemixingProcess(this.song);

  /// The song being demixed.
  final Song song;

  /// The current step of the demixing process.
  DemixingStep get step => stepNotifier.value;
  final ValueNotifier<DemixingStep> stepNotifier =
      ValueNotifier(DemixingStep.checkingCache);

  /// Get stems for [song], if all stems (see [StemType]) were found with the correct [fileExtension].
  Future<Map<StemType, File>?> getStemsInCache(
    Song song, {
    String fileExtension = "mp3",
  }) async {
    Directory directory = await DemixerApiHost.getStemsDirectory(song);
    List<File> stemFiles = StemType.values
        .map((stem) => File("${directory.path}/${stem.name}.$fileExtension"))
        .toList();
    if ((await Future.wait(stemFiles.map((stem) => stem.exists())))
        .every((value) => value)) {
      // All stems were found in the cache.
      return {
        for (final stem in StemType.values)
          stem: File("${directory.path}/${stem.name}.$fileExtension")
      };
    }

    return null;
  }

  @override
  Future<Map<StemType, File>> process() async {
    // Try to grab stems from cache
    stepNotifier.value = DemixingStep.checkingCache;

    Map<StemType, File>? cachedStemFiles = await getStemsInCache(song);
    if (cachedStemFiles != null) {
      debugPrint("[DEMIXER] Using cached stems for song ${song.id}.");

      return cachedStemFiles;
    }

    stepNotifier.value = DemixingStep.findingHost;

    DemixerApiHost host = await MusbxApi.findDemixerHost();

    breakIfCancelled();

    // Upload song to server
    stepNotifier.value = DemixingStep.uploading;

    UploadResponse response;
    if (song.source is FileSource) {
      response = await host.uploadFile(
        (song.source as FileSource).file,
      );
    } else {
      response = await host.uploadYoutubeSong(
        (song.source as YoutubeSource).youtubeId,
      );
    }

    breakIfCancelled();

    if (response.jobId != null) {
      // Wait for demixing job to complete
      stepNotifier.value = DemixingStep.separating;

      var subscription = host.jobProgress(response.jobId!).handleError((error) {
        if (error is! HttpException ||
            error.message != "The requested Job does not exist") {
          throw error;
        }
      }).listen(null, cancelOnError: true);
      subscription.onData((response) {
        if (isCancelled) {
          subscription.cancel();
        }

        if (response.progress == 100) {
          // The server is converting files to mp3
          stepNotifier.value = DemixingStep.compressing;
          progressNotifier.value = null;
        } else {
          // Update demixing progress
          progressNotifier.value = response.progress / 100;
        }
      });

      await subscription.asFuture();
      progressNotifier.value = null;
    }

    breakIfCancelled();

    // Download stem files
    stepNotifier.value = DemixingStep.downloading;
    progressNotifier.value = 0;

    Map<StemType, File> stemFiles = Map.fromEntries(await Future.wait(
      StemType.values.map((stem) async {
        File file = await host.downloadStem(
          // When dimixing files, [song.id] is not the same as the id of the song on the API ([response.songId]).
          // Thus we need to pass it as well, which is ugly. TODO: Fix this.
          response.songId,
          song,
          stem,
        );
        progressNotifier.value = (progress ?? 0) + 1 ~/ StemType.values.length;

        return MapEntry(stem, file);
      }),
    ));

    breakIfCancelled();

    return stemFiles;
  }
}
