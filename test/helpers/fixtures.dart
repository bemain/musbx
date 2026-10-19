import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A [FileCacheService] in fresh temporary directories, deleted after the test.
Future<FileCacheService> createTempFileCache() async {
  final root = await Directory.systemTemp.createTemp("musbx_test_");
  addTearDown(() => root.delete(recursive: true));
  return FileCacheService.create(
    scratch: Directory("${root.path}/scratch"),
    persistent: Directory("${root.path}/persistent"),
  );
}

/// A [ServiceLoader] whose service starts as [fallback] and becomes [service]
/// once loaded.
ServiceLoader<T> loaderOf<T extends OptionalService>(
  T service, {
  required T Function() fallback,
}) => ServiceLoader(create: () async => service, fallback: fallback);

/// A [SharedPreferencesService] over an in-memory store holding [data].
///
/// Keys in [data] are raw, so values the service reads have to carry its
/// `musbx/` prefix.
Future<SharedPreferencesService> createPreferences([
  Map<String, Object> data = const {},
]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(data);
  return SharedPreferencesService.create();
}

/// A song with audio from a URL, identified by [id].
Song urlSong(String id, {String? title}) => Song(
  id: id,
  title: title ?? "Song $id",
  audio: UrlAudio(Uri.parse("https://example.com/$id")),
);

/// Write the song library as if each song had last been played at its time.
///
/// Must run before `SongRepository.create`, which seeds an empty library.
Future<void> seedLibrary(
  FileCacheService fileCache,
  Map<Song, DateTime> playedAt,
) => fileCache.persistent.file("songs/history.json").writeJson({
  for (final e in playedAt.entries) e.value.toString(): e.key.toJson(),
});

/// [length] samples of a pure sine wave at [frequency] Hz.
Float32List sine(
  double frequency, {
  int sampleRate = 22050,
  int length = 2048,
  double amplitude = 0.5,
}) => Float32List.fromList([
  for (var i = 0; i < length; i++)
    amplitude * sin(2 * pi * frequency * i / sampleRate),
]);
