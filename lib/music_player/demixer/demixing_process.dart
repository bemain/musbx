import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/musbx_api/demixer_api.dart';
import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/process.dart';

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

class DemixingProcess extends Process<Map<StemType, File>> {
  /// Upload, separate and download stem files for a [song].
  ///
  /// The stem files will be 16 bit wav files.
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

      // Cached files need to be converted to wav
      stepNotifier.value = DemixingStep.extracting;
      progressNotifier.value = 0;

      for (final entry in cachedStemFiles.entries) {
        cachedStemFiles[entry.key] = await mp3ToWav(entry.value);
        progressNotifier.value = (progress ?? 0) + 0.25;
        breakIfCancelled();
      }

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
            error.message != "The requested Job does not exist") throw error;
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
        progressNotifier.value = (progress ?? 0) + 0.25;

        return MapEntry(stem, file);
      }),
    ));

    breakIfCancelled();

    // Convert files to wav
    stepNotifier.value = DemixingStep.extracting;
    progressNotifier.value = 0;

    for (final entry in stemFiles.entries) {
      stemFiles[entry.key] = await mp3ToWav(entry.value);

      progressNotifier.value = (progress ?? 0) + 0.25;

      breakIfCancelled();
    }

    return stemFiles;
  }
}

/// Convert [inFile] from mp3 to 16 bit pcm wav.
Future<File> mp3ToWav(File inFile) async {
  /// File name without extension
  String fileName = inFile.path.split("/").last.split(".").first;
  String outputDirectory = (await DemixerApiHost.extractedFilesDirectory).path;

  // Use ffmpeg to convert files to wav
  String arguments =
      "-y -i ${inFile.path} -bitexact -acodec pcm_s16le $outputDirectory/$fileName.wav";
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
