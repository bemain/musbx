import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/utils/utils.dart';

part 'song.g.dart';

/// A song in the user's library, as it is described rather than as it sounds.
///
/// Two songs are the same song when their [id] matches; nothing else is
/// compared.
@JsonSerializable()
class Song {
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

  /// Where to find the artwork for this song.
  final Uri? artUri;

  /// Where this song's audio comes from, e.g. a YouTube video or a local file.
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

/// Where a song's audio comes from.
///
/// Says how the audio can be obtained, not how it is played; `AudioRepository`
/// turns one of these into something the audio engine can play.
sealed class AudioReference {
  /// Read a reference of any kind back from [json].
  ///
  /// Throws a [FormatException] for a [BytesAudio], which has no bytes left to
  /// point at once it has been written to disk.
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

/// Audio downloaded from a [url], e.g. a YouTube or SoundCloud page.
class UrlAudio extends AudioReference {
  UrlAudio(this.url);

  /// The page the audio is downloaded from.
  final Uri url;

  /// Read a [UrlAudio] from a [json] object.
  static UrlAudio fromJson(Json json) =>
      UrlAudio(Uri.parse(json['url'] as String));

  @override
  Json toJson() => {
    "type": "ytdlp",
    "url": url.toString(),
  };
}

/// Audio held in memory as raw bytes.
///
/// The bytes survive only until they have been written to the cache, which is
/// why this reference cannot be read back from disk.
// TODO: Revise this class
class BytesAudio extends AudioReference {
  BytesAudio(this.bytes);

  /// The bytes to construct the audio from.
  ///
  /// `null` once the audio has been written to the cache, which is then the
  /// only place it can be read from.
  final Uint8List? bytes;

  /// Read a [BytesAudio] from a [json] object. The bytes are always `null`.
  static BytesAudio fromJson(Json json) => BytesAudio(null);

  @override
  Json toJson() => {
    "type": "bytes",
  };
}

/// Audio read from a file on the device.
class FileAudio extends AudioReference {
  FileAudio(this.file);

  /// The file to read.
  final File file;

  /// Read a [FileAudio] from a [json] object.
  static FileAudio fromJson(Json json) =>
      FileAudio(File(json['path'] as String));

  @override
  Json toJson() => {
    "type": "file",
    "path": file.path,
  };
}
