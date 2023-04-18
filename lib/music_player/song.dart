import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/widgets.dart';

/// Where a song was loaded from.
enum SongSource {
  /// From searching or entering a url for a video on YouTube.
  youtube,

  /// From a local file selected by the user.
  file,
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
  final SongSource? source;

  /// The audio source for this song, playable by [AudioPlayer].
  final AudioSource audioSource;

  /// The media item for this song, provided to [MusicPlayerAudioHandler] when
  /// this song is played.
  final MediaItem mediaItem;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (genre != null) "genre": genre,
      if (artUri != null) "artUri": artUri.toString(),
      if (source != null) "source": source.toString().split(".").last,
      if (audioSource is UriAudioSource)
        "audioSource": (audioSource as UriAudioSource).uri.toString(),
    };
  }

  /// Create a [Song] from a json map.
  ///
  /// The map must contain the following keys:
  ///  - id
  ///  - title
  ///  - audioSource
  factory Song.fromJson(Map<String, dynamic> json) => Song(
      id: json["id"] as String,
      title: json["title"] as String,
      album: tryCast<String>(json["album"]),
      artist: tryCast<String>(json["artist"]),
      genre: tryCast<String>(json["genre"]),
      artUri: Uri.tryParse(tryCast<String>(json["artUri"]) ?? ""),
      source: _tryParseSongSource(tryCast<String>(json["source"])),
      audioSource: AudioSource.uri(Uri.parse(json["audioSource"])));
}

SongSource? _tryParseSongSource(String? source) {
  switch (source) {
    case "youtube":
      return SongSource.youtube;
    case "file":
      return SongSource.file;
  }
  return null;
}
