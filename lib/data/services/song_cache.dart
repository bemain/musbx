import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';

/// Where each song's files live on disk.
///
/// Split by durability: preferences are persistent, while everything that can be
/// fetched or computed again — the audio, its stems, the chords and the waveform
/// — is scratch, and may be purged by the operating system or by the user
/// clearing the cache.
class SongCache {
  SongCache({required FileCacheService fileCache}) : _fileCache = fileCache;

  final FileCacheService _fileCache;

  CacheDirectory _scratch(Song song) =>
      _fileCache.scratch.directory("songs/${song.id}");
  CacheDirectory _source(Song song) => _scratch(song).directory("source");

  CacheDirectory _persistent(Song song) =>
      _fileCache.persistent.directory("songs/${song.id}");

  /// How the user last left this song. Survives [clear].
  CacheFile preferences(Song song) =>
      _persistent(song).file("preferences.json");

  /// The chords identified in this song.
  CacheFile chords(Song song) => _scratch(song).file("chords.json");

  /// The extracted waveform of this song.
  CacheFile waveform(Song song) => _scratch(song).file("waveform.wave");

  /// The downloaded audio of this song.
  CacheFile audio(Song song, {String extension = "mp3"}) =>
      _source(song).file("audio.$extension");

  /// One of this song's separated stems.
  CacheFile stem(Song song, StemType stem, {String extension = "mp3"}) =>
      _source(song).file("${stem.name}.$extension");

  /// How much space this song's regenerable files take, in bytes.
  Future<int> size(Song song) => _scratch(song).size();

  /// Delete this song's regenerable files, keeping its [preferences].
  Future<void> clear(Song song) => _scratch(song).delete();

  /// Delete everything stored for this song, [preferences] included.
  Future<void> delete(Song song) async {
    await clear(song);
    await _persistent(song).delete();
  }

  /// How much space every song's regenerable files take, in bytes.
  Future<int> totalSize() => _fileCache.scratch.directory("songs").size();

  /// Delete the regenerable files of every song.
  Future<void> clearAll() => _fileCache.scratch.directory("songs").delete();
}
