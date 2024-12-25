import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/songs/player/song_source.dart';
import 'package:musbx/widgets/widgets.dart';

/// The default album art.
/// TODO: Make this a local asset.
final Uri defaultAlbumArt =
    Uri.parse("https://bemain.github.io/musbx/default_album_art.png");

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
          artUri: artUri ?? defaultAlbumArt,
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

  /// The directory where files relating to this song are cached.
  late final Future<Directory> cacheDirectory =
      createTempDirectory("songs/$id");

  @override
  String toString() {
    return "Song(${toJson().entries.map((e) => "${e.key}: ${e.value}").join(", ")})";
  }

  /// Convert this [Song] to a json map.
  ///
  /// The map will always contain the following keys:
  /// - `id` [String] A unique id.
  /// - `title` [String] The title of this song.
  /// - `source` [Map<String, dynamic>] Where this song's audio was loaded from. Will contain the key `type` and other values depending on the type.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (genre != null) "genre": genre,
      if (artUri != null) "artUri": artUri?.toString(),
      "source": source.toJson(),
    };
  }

  /// Create a [Song] from a json map.
  ///
  /// The map should always contain the following keys:
  /// - `id` [String] A unique id.
  /// - `title` [String] The title of this song.
  /// - `source` [Map<String, dynamic>] Where this song's audio was loaded from. Should contain the key `type` and other values depending on the type.
  static Song? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("id") ||
        !json.containsKey("title") ||
        !json.containsKey("source")) {
      return null;
    }

    SongSource? source = SongSource.fromJson(json["source"]);
    if (source == null) return null;
    final String? artUri = tryCast<String>(json["artUri"]);

    return Song(
      id: json["id"] as String,
      title: json["title"] as String,
      album: tryCast<String>(json["album"]),
      artist: tryCast<String>(json["artist"]),
      genre: tryCast<String>(json["genre"]),
      artUri: artUri == null ? null : Uri.tryParse(artUri),
      source: source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
