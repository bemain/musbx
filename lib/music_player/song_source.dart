import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/pick_song_button/components/upload_file_button.dart';
import 'package:musbx/widgets.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Where the audio for a song is loaded from.
abstract class SongSource {
  /// Create an [AudioSource] playable by [AudioPlayer].
  Future<AudioSource> toAudioSource();

  /// Convert this to a json map.
  ///
  /// The map will contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map will contain some additional keys. \
  /// "youtube" [String] `youtubeId`: The id of the Youtube song. \
  /// "file" [String] `path`: The path to the file.
  Map<String, dynamic> toJson();

  /// Try to create a [SongSource] from a json map.
  ///
  /// The map should contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map should contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file.
  static SongSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("type")) return null;
    String? type = tryCast<String>(json["type"]);

    switch (type) {
      case "youtube":
        if (!json.containsKey("youtubeId")) break;
        String? id = tryCast<String>(json["youtubeId"]);
        if (id == null) break;

        return YoutubeSource(id);
      case "file":
        if (!json.containsKey("path")) break;
        String? path = tryCast<String>(json["path"]);
        if (path == null) break;

        return FileSource(path);
    }
    return null;
  }
}

class FileSource implements SongSource {
  /// A song with audio loaded from a local file.
  FileSource(this.path);

  /// The path to the file.
  final String path;

  /// The file that the audio is loaded from.
  File get file => File(path);

  @override
  Future<AudioSource> toAudioSource() async {
    if (!await File(path).exists()) {
      throw FileSystemException("File doesn't exist", path);
    }

    return AudioSource.file(path);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "file",
        "path": path,
      };
}

class YoutubeSource implements SongSource {
  /// A song with audio loaded from Youtube.
  YoutubeSource(this.youtubeId);

  /// The id of the Youtube song.
  final String youtubeId;

  @override
  Future<AudioSource> toAudioSource() async {
    Uri uri = await getYoutubeAudio(youtubeId);
    return AudioSource.uri(uri);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "youtube",
        "youtubeId": youtubeId,
      };

  /// Get the audio of a YouTube video.
  ///
  /// Tries to download the audio file using the [DemixerApi].
  /// If that fails, uses [YoutubeExplode] to stream the audio instead (not on iOS).
  ///
  /// If the device is on a cellular network, prefers stream over downloading to minimize data usage.
  static Future<Uri> getYoutubeAudio(String videoId) async {
    // Use cached audio, if available
    String cacheDirectory = (await DemixerApi.youtubeDirectory).path;
    for (String extension in allowedExtensions) {
      File file = File("$cacheDirectory/$videoId.$extension");
      if (await file.exists()) {
        debugPrint(
            "[YOUTUBE] Using cached audio '${file.path}' for Youtube song $videoId");
        return file.uri;
      }
    }

    if (Platform.isIOS) return await downloadYoutubeAudio(videoId);

    if (await isOnCellular()) {
      try {
        return await getYoutubeAudioStream(videoId); // Try using YoutubeExplode
      } catch (error) {
        debugPrint(
            "[YOUTUBE] YoutubeExplode is not available, falling back to the Demixer API");
        return await downloadYoutubeAudio(videoId);
      }
    }

    try {
      return await downloadYoutubeAudio(videoId); // Try using the Demixer API
    } catch (error) {
      debugPrint(
          "[YOUTUBE] Demixer API is not available, falling back to YoutubeExplode");
      return await getYoutubeAudioStream(videoId);
    }
  }

  /// Download the audio of a Youtube video using the [DemixerApi].
  static Future<Uri> downloadYoutubeAudio(String videoId) async {
    File file = await (await DemixerApi.findHost()).downloadYoutubeSong(
      videoId,
      await DemixerApi.youtubeDirectory,
    );
    return Uri.file(file.path);
  }

  static Future<Uri> getYoutubeAudioStream(String videoId) async {
    StreamManifest manifest =
        await YoutubeExplode().videos.streams.getManifest(videoId);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
    return streamInfo.url;
  }
}
