import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/repositories/song/audio_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/load_song.dart';
import 'package:musbx/domain/use_case/unload_song.dart';

import 'fixtures.dart';
import 'mocks.dart';

/// The song repositories, real and backed by a temporary directory, with only
/// the audio engine, audio session and demixing server mocked.
class SongHarness {
  SongHarness._(this.fileCache, this.songs, this.settings)
    : cache = SongCache(fileCache: fileCache);

  static Future<SongHarness> create({
    Map<Song, DateTime>? library,
  }) async {
    final fileCache = await createTempFileCache();
    if (library != null) await seedLibrary(fileCache, library);

    final harness = SongHarness._(
      fileCache,
      await SongRepository.create(fileCache: fileCache),
      SettingsRepository(sharedPreferences: await createPreferences()),
    );
    addTearDown(harness.playback.dispose);
    return harness;
  }

  final FileCacheService fileCache;
  final SongCache cache;
  final SongRepository songs;
  final SettingsRepository settings;

  final engine = MockAudioEngine();
  final session = MockAudioSession();
  final demixing = MockDemixRepository();

  late final preferences = SongPreferencesRepository(songCache: cache);
  late final audio = AudioRepository(songCache: cache);
  late final playback = PlaybackRepository(
    audioEngine: engine,
    audioSession: session,
  );

  late final unloadSong = UnloadSong(
    songPreferences: preferences,
    playback: playback,
  );
  late final loadSong = LoadSong(
    unloadSong: unloadSong,
    audio: audio,
    songPreferences: preferences,
    playback: playback,
    demix: demixing,
  );

  /// A song whose audio is a local file that exists.
  Future<Song> localSong(String id) async {
    final file = File(fileCache.persistent.file("library/$id.mp3").path);
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    return Song(id: id, title: "Song $id", audio: FileAudio(file));
  }
}
