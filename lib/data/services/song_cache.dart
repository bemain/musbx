// lib/data/services/song_cache.dart
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';

class SongCache {
  SongCache(this._fileCache);

  final FileCacheService _fileCache;

  // TODO: Remove once we introduce 'provider'.
  static late final SongCache instance;
  static Future<void> initialize() async {
    instance = SongCache(FileCacheService.instance);
  }

  CacheDirectory _scratch(Song song) =>
      _fileCache.scratch.directory("songs/${song.id}");
  CacheDirectory _source(Song song) => _scratch(song).directory("source");

  CacheDirectory _persistent(Song song) =>
      _fileCache.persistent.directory("songs/${song.id}");

  CacheFile preferences(Song song) =>
      _persistent(song).file("preferences.json");
  CacheFile chords(Song song) => _scratch(song).file("chords.json");
  CacheFile waveform(Song song) => _scratch(song).file("waveform.wave");
  CacheFile audio(Song song, {String extension = "mp3"}) =>
      _source(song).file("audio.$extension");
  CacheFile stem(Song song, StemType stem, {String extension = "mp3"}) =>
      _source(song).file("${stem.name}.$extension");

  Future<int> size(Song song) => _scratch(song).size();
  Future<void> clear(Song song) => _scratch(song).delete();
  Future<void> delete(Song song) async {
    await clear(song);
    await _persistent(song).delete();
  }

  Future<int> totalSize() => _fileCache.scratch.directory("songs").size();
  Future<void> clearAll() => _fileCache.scratch.directory("songs").delete();
}
