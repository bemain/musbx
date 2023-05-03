import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/youtube_audio_streams.dart';
import 'package:musbx/widgets.dart';

/// Where a song was loaded from.
enum SongSource {
  /// From searching or entering a url for a video on YouTube.
  youtube,

  /// From a local file selected by the user.
  file;

  @override
  String toString() {
    switch (this) {
      case SongSource.youtube:
        return "youtube";
      case SongSource.file:
        return "file";
    }
  }

  static SongSource? fromString(String? string) {
    switch (string) {
      case "youtube":
        return SongSource.youtube;
      case "file":
        return SongSource.file;
    }
    return null;
  }
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
    required this.audioSource,
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

  /// Where this song was loaded from, e.g. a YouTube video or a local file.
  final SongSource source;

  /// The audio source for this song, playable by [AudioPlayer].
  final AudioSource audioSource;

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
  /// - audioSource
  ///
  /// Additionally, if audioSource is [AudioSource.file], the map will contain the key `filePath`.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (genre != null) "genre": genre,
      if (artUri != null) "artUri": artUri.toString(),
      "source": source.toString(),
      if (source == SongSource.file)
        "filePath": (audioSource as UriAudioSource).uri.toString(),
    };
  }

  /// Create a [Song] from a json map.
  ///
  /// The map should contain the following keys, else we return `null`.
  ///  - id
  ///  - title
  ///  - source
  ///  - audioSource
  ///
  /// Additionally, if audioSource is [AudioSource.file], the map should contain the key `filePath`.
  static Future<Song?> fromJson(Map<String, dynamic> json) async {
    if (!json.containsKey("id") || !json.containsKey("title")) return null;

    SongSource? source = SongSource.fromString(tryCast<String>(json["source"]));
    if (source == null) return null;

    AudioSource? audioSource = await _tryParseAudioSource(json, source);
    if (audioSource == null) return null;

    return Song(
      id: json["id"] as String,
      title: json["title"] as String,
      album: tryCast<String>(json["album"]),
      artist: tryCast<String>(json["artist"]),
      genre: tryCast<String>(json["genre"]),
      artUri: Uri.tryParse(tryCast<String>(json["artUri"]) ?? ""),
      source: source,
      audioSource: audioSource,
    );
  }

  /// Try to parse a [AudioSource] from a json map, given the [source].
  ///
  /// If [source] is [SongSource.file], the map should contain the key `filePath`.
  static Future<AudioSource?> _tryParseAudioSource(
    Map<String, dynamic> json,
    SongSource source,
  ) async {
    switch (source) {
      case SongSource.youtube:
        return AudioSource.uri(await getAudioStream(json["id"]));

      case SongSource.file:
        if (!json.containsKey("filePath")) return null;
        final Uri? fileUrl = Uri.tryParse(json["filePath"] as String);
        if (fileUrl == null) return null;
        return AudioSource.uri(fileUrl);
    }
  }
}
