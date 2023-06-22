import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Used internally to get audio streams from YouTube.
final YoutubeExplode _youtubeExplode = YoutubeExplode();
final DemixerApi _demixerApi = DemixerApi();

/// Get the audio stream of a YouTube video with [videoId].
Future<Uri> getAudioStream(String videoId) async {
  try {
    // Try using the demixer API
    File file = await _demixerApi.downloadYoutubeSong(videoId);
    return Uri.file(file.path);
  } catch (error) {
    // Fallback to using the YoutubeExplode API
    if (Platform.isIOS) rethrow; // Using YoutubeExplode doesn't work on iOS

    debugPrint(
        "YOUTUBE: Demixer API is not available, falling back to YoutubeExplode");
    StreamManifest manifest =
        await _youtubeExplode.videos.streams.getManifest(videoId);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
    return streamInfo.url;
  }
}
