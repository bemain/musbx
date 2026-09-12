import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/utils/utils.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  /// Representation of a song, to be played by a [SongPlayer].
  Song({
    required this.id,
    required this.title,
    this.album,
    this.artist,
    this.genre,
    this.artUri,
    required this.audio,
  });

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
  /// Can be used to create an [AudioSource] playable by [SongPlayer].
  @JsonKey(fromJson: AudioReference.fromJson)
  final AudioReference audio;

  /// Create a copy of this [Song] with the specified fields replaced with new values.
  ///
  /// If a field is not specified, it will be copied from this [Song].
  ///
  /// Example:
  /// ```dart
  /// final Song newSong = oldSong.copyWith(title: "New title");
  /// ```
  Song copyWith({
    String? id,
    String? title,
    String? album,
    String? artist,
    String? genre,
    Uri? artUri,
    Json? preferences,
    AudioReference? audio,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      artUri: artUri ?? this.artUri,
      audio: audio ?? this.audio,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static Song fromJson(Json json) => _$SongFromJson(json);

  Json toJson() => _$SongToJson(this);

  @override
  String toString() {
    return "Song(${toJson().entries.map((e) => "${e.key}: ${e.value}").join(", ")})";
  }
}

sealed class AudioReference {
  static AudioReference fromJson(Json json) {
    String? type = json['type'] as String;

    switch (type) {
      case "ytdlp":
        return UrlAudio.fromJson(json);
      case "file":
        return FileAudio.fromJson(json);
      case "bytes":
        throw FormatException("Bytes audio cannot be persisted to disk");
      default:
        throw FormatException("Unsupported AudioReference type: $type");
    }
  }

  Json toJson();
}

class UrlAudio extends AudioReference {
  UrlAudio(this.url);

  final Uri url;

  /// Try to create a [UrlAudio] from a [json] object.
  static UrlAudio fromJson(Json json) =>
      UrlAudio(Uri.parse(json['url'] as String));

  @override
  Json toJson() => {
    "type": "ytdlp",
    "url": url.toString(),
  };
}

class BytesAudio extends AudioReference {
  /// A source that constructs audio from raw bytes.
  /// TODO: Revise this class
  BytesAudio(this.bytes);

  /// The bytes to construct the audio from.
  ///
  /// If this is `null`, the audio is expected to already be loaded into the [cacheFile]
  final Uint8List? bytes;

  /// Try to create a [FileAudio] from a [json] object.
  static BytesAudio fromJson(Json json) => BytesAudio(null);

  @override
  Json toJson() => {
    "type": "bytes",
  };
}

class FileAudio extends AudioReference {
  /// A source that reads audio from a file.
  FileAudio(this.file);

  /// The file to read.
  final File file;

  /// Try to create a [FileAudio] from a [json] object.
  static FileAudio fromJson(Json json) =>
      FileAudio(File(json['path'] as String));

  @override
  Json toJson() => {
    "type": "file",
    "path": file.path,
  };
}
