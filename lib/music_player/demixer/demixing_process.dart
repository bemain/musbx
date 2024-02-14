import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/musbx_api/demixer_api.dart';
import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/musbx_api/exceptions.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';

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
      ValueNotifier(DemixingStep.checkingCache);

  /// The progress of the current demixing [step], or `null` if [step] doesn't report progress.
  int? get stepProgress => stepProgressNotifier.value;
  final ValueNotifier<int?> stepProgressNotifier = ValueNotifier(null);

  /// Queue this job for cancellation.
  void cancel() {
    _cancelled = true;
  }

  /// Get stems from [songDirectory], if all stems (see [StemType]) were found with [fileExtension].
  Future<Map<StemType, File>?> getStemsInCache(
    Directory songDirectory, {
    String fileExtension = "mp3",
  }) async {
    List<File> stemFiles = StemType.values
        .map(
            (stem) => File("${songDirectory.path}/${stem.name}.$fileExtension"))
        .toList();
    if ((await Future.wait(stemFiles.map((stem) => stem.exists())))
        .every((value) => value)) {
      // All stems were found in the cache.
      return {
        for (final stem in StemType.values)
          stem: File("${songDirectory.path}/${stem.name}.$fileExtension")
      };
    }

    return null;
  }

  /// Upload, separate and download stem files for [song].
  ///
  /// The stem files will be 16 bit wav files.
  ///
  /// TODO: Improve progress tracking for upload and download.
  Future<Map<StemType, File>?> demixSong(Song song) async {
    // Try to grab stems from cache
    stepNotifier.value = DemixingStep.checkingCache;

    Directory songDirectory = await DemixerApiHost.getSongDirectory(song.id);
    Map<StemType, File>? cachedStemFiles = await getStemsInCache(songDirectory);
    if (cachedStemFiles != null) {
      debugPrint("[DEMIXER] Using cached stems for song ${song.id}.");

      // Cached files need to be converted to wav
      stepNotifier.value = DemixingStep.extracting;
      stepProgressNotifier.value = 0;

      for (final entry in cachedStemFiles.entries) {
        cachedStemFiles[entry.key] = await mp3ToWav(entry.value);
        stepProgressNotifier.value = (stepProgress ?? 0) + 25;
        if (_cancelled) return null;
      }

      return cachedStemFiles;
    }

    stepNotifier.value = DemixingStep.findingHost;

    DemixerApiHost host = await MusbxApi.findDemixerHost();

    if (_cancelled) return null;

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

    String songId = response.songId;

    if (_cancelled) return null;

    if (response.jobId != null) {
      // Wait for demixing job to complete
      stepNotifier.value = DemixingStep.separating;

      var subscription = host.jobProgress(response.jobId!).handleError((error) {
        if (error is! JobNotFoundException) throw error;
      }).listen(null, cancelOnError: true);
      subscription.onData((response) {
        if (_cancelled) {
          subscription.cancel();
        }

        if (response.progress == 100) {
          // The server is converting files to mp3
          stepNotifier.value = DemixingStep.compressing;
          stepProgressNotifier.value = null;
        } else {
          // Update demixing progress
          stepProgressNotifier.value = response.progress;
        }
      });

      await subscription.asFuture();
      stepProgressNotifier.value = null;
    }

    if (_cancelled) return null;

    // Download stem files
    stepNotifier.value = DemixingStep.downloading;
    stepProgressNotifier.value = 0;

    Map<StemType, File> stemFiles = Map.fromEntries(await Future.wait(
      StemType.values.map((stem) async {
        File file = await host.downloadStem(
          songId,
          stem,
        );
        stepProgressNotifier.value = (stepProgress ?? 0) + 25;

        return MapEntry(stem, file);
      }),
    ));

    if (_cancelled) return null;

    // Convert files to wav
    stepNotifier.value = DemixingStep.extracting;
    stepProgressNotifier.value = 0;

    for (final entry in stemFiles.entries) {
      stemFiles[entry.key] = await mp3ToWav(entry.value);

      stepProgressNotifier.value = (stepProgress ?? 0) + 25;

      if (_cancelled) return null;
    }

    return stemFiles;
  }
}

/// Convert [file] from mp3 to 16 bit pcm wav.
Future<File> mp3ToWav(File file) async {
  /// File name without extension
  String fileName = file.path.split("/").last.split(".").first;
  String outputDirectoryPath = (await DemixerApiHost.demixerDirectory).path;

  // Use ffmpeg to convert files to wav
  String arguments =
      "-y -i ${file.path} -bitexact -acodec pcm_s16le $outputDirectoryPath/$fileName.wav";
  final session = await FFmpegKit.execute(arguments);
  ReturnCode? returnCode = await session.getReturnCode();

  if (!ReturnCode.isSuccess(returnCode)) {
    throw ProcessException(
      "ffmpeg",
      arguments.split(" "),
      "Converting file $fileName.mp3 to wav failed. \n${await session.getOutput()}",
      returnCode?.getValue() ?? 0,
    );
  }

  return File("$fileName.wav");
}
