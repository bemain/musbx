import 'dart:io';

import 'package:audio_service/audio_service.dart';
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
  /// - type
  /// Depending on the type, the map will contain some additional keys. \
  /// "youtube": youtubeId \
  /// "file": path
  Map<String, dynamic> toJson();

  /// Try to create a [SongSource] from a json map.
  ///
  /// The map should contain at least the following key:
  /// - type
  ///
  /// Depending on the type, the map should contain some additional keys. \
  /// "youtube": youtubeId \
  /// "file": path
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

class Song {
  /// Representation of a song, to be played by [MusicPlayer].
  Song({
    required this.id,
    required this.title,
    this.album,
    this.artist,
    this.genre,
    this.artUri,
    required this.source,
  }) : mediaItem = MediaItem(
          id: id,
          title: title,
          album: album,
          artist: artist,
          genre: genre,
          artUri: artUri,
        );

  /// A unique id.
  final String id;

  /// The title of this song.
  final String title;

  /// The album this song belongs to.
  final String? album;

  /// The artist of this song.
  final String? artist;

  /// The genre of this song.
  final String? genre;

  /// The artwork URI for this song.
  ///
  /// See [MediaItem.artUri]
  final Uri? artUri;

  /// Where this song's audio was loaded from, e.g. a YouTube video or a local file.
  ///
  /// Can be used to create an [AudioSource] playable by [AudioPlayer].
  final SongSource source;

  /// The media item for this song, provided to [MusicPlayerAudioHandler] when
  /// this song is played.
  final MediaItem mediaItem;

  @override
  String toString() {
    return "Song(${toJson().entries.map((e) => "${e.key}: ${e.value}").join(", ")})";
  }

  /// Convert this [Song] to a json map.
  ///
  /// The map will always contain the following keys:
  /// - id
  /// - title
  /// - source
  ///
  /// The "source" value is a map containing the key "type"
  /// and other values required to intialize the source.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (genre != null) "genre": genre,
      if (artUri != null) "artUri": artUri.toString(),
      "source": source.toJson(),
    };
  }

  /// Create a [Song] from a json map.
  ///
  /// The map should contain the following keys, else we return `null`.
  ///  - id
  ///  - title
  ///  - source
  ///
  /// The "source" value should be a map containing the key "type"
  /// and other values required to intialize the source.
  static Future<Song?> fromJson(Map<String, dynamic> json) async {
    if (!json.containsKey("id") ||
        !json.containsKey("title") ||
        !json.containsKey("source")) return null;

    SongSource? source = SongSource.fromJson(json["source"]);
    if (source == null) return null;

    return Song(
      id: json["id"] as String,
      title: json["title"] as String,
      album: tryCast<String>(json["album"]),
      artist: tryCast<String>(json["artist"]),
      genre: tryCast<String>(json["genre"]),
      artUri: Uri.tryParse(tryCast<String>(json["artUri"]) ?? ""),
      source: source,
    );
  }
}
