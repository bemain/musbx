import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

/// The default album art.
/// TODO: Make this a local asset.
final Uri defaultAlbumArt = Uri.parse(
  "https://bemain.github.io/musbx/default_album_art.png",
);

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
    this.preferences,
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
  final AudioProvider audio;

  /// The media item for this song, provided to [SongsAudioHandler] when
  /// this song is played.
  ///
  /// Note that the returned media item does not include the duration of the audio.
  MediaItem get mediaItem => MediaItem(
    id: id,
    title: title,
    album: album,
    artist: artist,
    genre: genre,
    artUri: artUri ?? defaultAlbumArt,
  );

  /// The user's preferences for playing this song.
  /// TODO: Make a dedicated class for this?
  Json? preferences;

  /// Whether this song should be demixed or not.
  bool get shouldDemix =>
      (preferences?['demix'] as bool? ?? Songs.demixAutomatically);
  set shouldDemix(bool value) {
    preferences ??= {};
    preferences?['demix'] = value;
  }

  /// Whether this song has been demixed already.
  Future<bool> get isDemixed async => await cachedStems != null;

  /// The demixed audio stems for this song, if any.
  Future<Map<StemType, File>?> get cachedStems =>
      DemixingProcess.getStemsInCache(
        directory: audioDirectory,
      );

  /// The directory where files relating to this song are cached.
  Directory get cacheDirectory =>
      Directories.applicationDocumentsDir("songs/$id");

  /// The directory where audio files for this song are cached.
  Directory get audioDirectory => Directory("${cacheDirectory.path}/source/");

  /// Whether the cache for this song is not empty.
  bool get hasCache => cacheDirectory.existsSync();

  /// Remove all the cache files relating to this song.
  Future<void> clearCache() async {
    DemixingProcesses.cancel(this);

    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  }

  @override
  String toString() {
    return "Song(${toJson().entries.map((e) => "${e.key}: ${e.value}").join(", ")})";
  }

  /// Convert this [Song] to a json map.
  ///
  /// The map will always contain the following keys:
  /// - `id` [String] A unique id.
  /// - `title` [String] The title of this song.
  /// - `source` [Json] Where this song's audio was loaded from. Will contain the key `type` and other values depending on the type.
  Json toJson() {
    return {
      "id": id,
      "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (genre != null) "genre": genre,
      if (artUri != null) "artUri": artUri?.toString(),
      "source": audio.toJson(),
      "preferences": preferences,
    };
  }

  /// Create a [Song] from a json map.
  ///
  /// The map should always contain the following keys:
  /// - `id` [String] A unique id.
  /// - `title` [String] The title of this song.
  /// - `source` [Json] Json describing how to create a [AudioProvider]. Should contain the key `type` and other values depending on the type.
  static Song? fromJson(Json json) {
    if (!json.containsKey("id") ||
        !json.containsKey("title") ||
        !json.containsKey("source")) {
      return null;
    }

    AudioProvider? source = AudioProvider.fromJson(json['source'] as Json);
    if (source == null) return null;
    final String? artUri = tryCast<String>(json['artUri']);

    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      album: tryCast<String>(json['album']),
      artist: tryCast<String>(json['artist']),
      genre: tryCast<String>(json['genre']),
      artUri: artUri == null ? null : Uri.tryParse(artUri),
      audio: source,
      preferences: tryCast<Json>(json['preferences']),
    );
  }

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
    AudioProvider? audio,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      artUri: artUri ?? this.artUri,
      audio: audio ?? this.audio,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
