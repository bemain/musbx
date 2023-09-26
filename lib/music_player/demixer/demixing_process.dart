import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';

enum DemixingStep {
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

  /// The stem files are being extracted.
  extracting,
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
      ValueNotifier(DemixingStep.findingHost);

  /// The progress of the separation, or `null` if [step] is not [DemixingStep.separating].
  int? get separationProgress => separationProgressNotifier.value;
  final ValueNotifier<int?> separationProgressNotifier = ValueNotifier(null);

  /// Cancel this job as soon as possible.
  void cancel() {
    _cancelled = true;
  }

  /// Get stems from [songDirectory], if all stems (see [StemType]) were found and of [fileType].
  Future<Map<StemType, File>?> getStemsInCache(
    Directory songDirectory, {
    StemFileType fileType = StemFileType.mp3,
  }) async {
    if ((await Future.wait(StemType.values.map((stem) async =>
            await File("${songDirectory.path}/${stem.name}.${fileType.name}")
                .exists())))
        .every((element) => element)) {
      // All stems were found in the cache,
      return {
        for (final stem in StemType.values)
          stem: File("${songDirectory.path}/${stem.name}.${fileType.name}")
      };
    }

    return null;
  }

  /// Upload, separate and download stem files for [song].
  ///
  /// The stem files will be of the type [stemFilesType].
  Future<Map<StemType, File>?> demixSong(
    Song song, {
    StemFileType stemFilesType = StemFileType.mp3,
  }) async {
    // Try to grab stems from cache
    Directory songDirectory = await DemixerApi.getSongDirectory(song.id);
    if (await songDirectory.exists()) {
      Map<StemType, File>? stemFiles =
          await getStemsInCache(songDirectory, fileType: stemFilesType);
      if (stemFiles != null) {
        debugPrint("[DEMIXER] Using cached stems for song ${song.id}.");

        if (stemFilesType == StemFileType.mp3) {
          // Cached files need to be converted to wav
          for (final entry in stemFiles.entries) {
            stemFiles[entry.key] = await mp3ToWav(entry.value);
            if (_cancelled) return null;
          }
        }

        return stemFiles;
      }
    }

    stepNotifier.value = DemixingStep.findingHost;

    Host host = await DemixerApi.findHost();

    if (_cancelled) return null;

    stepNotifier.value = DemixingStep.uploading;

    UploadResponse response;
    if (song.source is FileSource) {
      response = await host.uploadFile(
        (song.source as FileSource).file,
        desiredStemFilesType: stemFilesType,
      );
    } else {
      response = await host.uploadYoutubeSong(
        (song.source as YoutubeSource).youtubeId,
        desiredStemFilesType: stemFilesType,
      );
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

        if (stemFilesType == StemFileType.mp3 && response.progress == 100) {
          // The server is converting files to mp3
          stepNotifier.value = DemixingStep.compressing;
          separationProgressNotifier.value = null;
        } else {
          // Update demixing progress
          separationProgressNotifier.value = response.progress;
        }
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
        songDirectory,
        fileType: stemFilesType,
      );
    }

    if (_cancelled) return null;

    stepNotifier.value = DemixingStep.extracting;

    if (stemFilesType == StemFileType.mp3) {
      // Downloaded files need to be converted to wav
      for (final entry in stemFiles.entries) {
        stemFiles[entry.key] = await mp3ToWav(entry.value);
        if (_cancelled) return null;
      }
    }

    if (_cancelled) return null;

    return stemFiles;
  }
}

Future<File> mp3ToWav(File file) async {
  List<String> fileParts = file.path.split(".");

  /// File path without extension
  String fileName = fileParts.sublist(0, fileParts.length - 1).join(".");

  // Use ffmpeg to convert
  String arguments =
      "-i $fileName.mp3 -bitexact -acodec pcm_s16le $fileName.wav";
  final session = await FFmpegKit.execute(arguments);
  ReturnCode? returnCode = await session.getReturnCode();

  if (!ReturnCode.isSuccess(returnCode)) {
    throw ProcessException(
      session.toString(),
      arguments.split(" "),
      "Converting file $fileName.mp3 to wav failed",
      returnCode?.getValue() ?? 0,
    );
  }

  return File("$fileName.wav");
}
