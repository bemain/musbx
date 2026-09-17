import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/audio_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/domain/use_case/unload_song.dart';
import 'package:musbx/utils/result.dart';

class LoadSong {
  LoadSong({
    required UnloadSong unloadSong,
    required AudioRepository audio,
    required SongPreferencesRepository songPreferences,
    required PlaybackRepository playback,
    required DemixRepository demix,
  }) : _unloadSong = unloadSong,
       _audio = audio,
       _songPreferences = songPreferences,
       _playback = playback,
       _demix = demix;

  final UnloadSong _unloadSong;
  final AudioRepository _audio;
  final SongPreferencesRepository _songPreferences;
  final PlaybackRepository _playback;
  final DemixRepository _demix;

  @useResult
  Future<Result<void>> call(Song song) async {
    // Unload previous song
    if (await _unloadSong.call() case Failure(:final error)) {
      debugPrint("[SONGS] Unloading song failed; $error");
    }

    try {
      final File file = (await _audio.resolve(song)).asOk;
      final stems = await _demix.stemsFor(song);

      final Map<StemType?, File> files;
      if (stems != null) {
        files = {
          for (final e in stems.entries) e.key: File(e.value.path),
        };
      } else {
        files = {null: file};
      }

      final preferences = (await _songPreferences.read(song)).asOk;

      (await _playback.load(song, files, preferences: preferences)).asOk;

      return Result.ok(null);
    } catch (e, s) {
      debugPrint("[SONGS] Loading song failed; $e");
      return Result.failed(e, s);
    }
  }
}
