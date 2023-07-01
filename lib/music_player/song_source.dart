import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/youtube_audio_streams.dart';
import 'package:musbx/widgets.dart';

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
      debugPrint("File doesn't exist, $path");
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
    Uri uri = await getAudioStream(youtubeId);
    return AudioSource.uri(uri);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "youtube",
        "youtubeId": youtubeId,
      };
}
