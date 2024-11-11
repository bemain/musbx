import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/musbx_api/youtube_api.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/widgets/widgets.dart';

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
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file.
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

  /// The file where the audio to this Youtube song is cached.
  /// Not set until [toAudioSource] has been called.
  late File cacheFile;

  @override
  Future<AudioSource> toAudioSource() async {
    File? file = await _getAudioFromCache();
    file ??= await (await MusbxApi.findYoutubeHost()).downloadYoutubeSong(
      youtubeId,
    );

    cacheFile = file;
    return AudioSource.file(file.path);
  }

  Future<File?> _getAudioFromCache() async {
    for (final String extension in allowedExtensions) {
      final File file =
          await YoutubeApiHost.getYoutubeFile(youtubeId, extension);
      if (await file.exists()) {
        debugPrint(
            "[YOUTUBE] Using cached audio for video with id '$youtubeId'");
        return file;
      }
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "youtube",
        "youtubeId": youtubeId,
      };
}
