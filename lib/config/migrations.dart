import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Brings data written by an older build up to date.
///
/// Runs once per launch, before anything reads the caches. Each migration names
/// the build number it belongs to and runs only when the app has crossed it, so
/// skipping several versions still applies each one in turn.
///
/// Migrations describe formats that no longer exist, so they address paths and
/// keys literally rather than through the classes that own them today. One that
/// follows a moving abstraction stops describing the version it was written
/// for.
class Migrations {
  Migrations({
    required SharedPreferencesService sharedPreferences,
    required FileCacheService fileCache,
    required PackageInfo packageInfo,
  }) : _sharedPreferences = sharedPreferences,
       _fileCache = fileCache,
       _packageInfo = packageInfo;

  final SharedPreferencesService _sharedPreferences;
  final FileCacheService _fileCache;
  final PackageInfo _packageInfo;

  late final PersistentValue<String> _lastVersionLaunched = _sharedPreferences
      .value(
        "lastVersionLaunched",
        initialValue: "0",
      );

  /// Apply every migration between the last launched build and this one.
  ///
  /// Does nothing on a fresh install or an unchanged build. A version that
  /// cannot be read is treated as a fresh install.
  Future<void> run() async {
    final int current = int.parse(_packageInfo.buildNumber);
    final int? previous = int.tryParse(_lastVersionLaunched.value);

    if (previous == null || previous == 0 || previous == current) {
      _lastVersionLaunched.value = current.toString();
      return;
    }

    for (final migration in _migrations) {
      if (previous < migration.version && current >= migration.version) {
        await migration.run();
      }
    }

    _lastVersionLaunched.value = current.toString();
  }

  late final List<_Migration> _migrations = [
    _Migration(70, _extractSongPreferences),
  ];

  /// Move each song's preferences out of the library history into its own file.
  ///
  /// Up to build 69 a song carried its preferences inline, under a
  /// `preferences` key in `songs/history.json`. The blob left behind is ignored
  /// by the current `Song` and disappears the next time the library is written.
  Future<void> _extractSongPreferences() async {
    final Json? history = await _fileCache.persistent
        .file("songs/history.json")
        .readJson();
    if (history == null) return;

    for (final entry in history.values) {
      if (entry is! Json) continue;

      final Object? id = entry["id"];
      final Object? preferences = entry["preferences"];
      if (id is! String || preferences is! Json) continue;

      final CacheFile file = _fileCache.persistent
          .directory("songs/$id")
          .file("preferences.json");
      if (await file.exists()) continue;

      try {
        await file.writeJson(_legacyPreferences(preferences).toJson());
      } catch (error) {
        debugPrint(
          "[MIGRATIONS] Could not migrate the preferences for song $id: $error",
        );
      }
    }
  }

  /// Read the nested preferences blob written up to build 69.
  ///
  /// `analyzer.durationShown` is dropped; the waveform zoom is no longer stored
  /// per song.
  SongPreferences _legacyPreferences(Json json) {
    final Object? slowdowner = json["slowdowner"];
    final Object? looper = json["looper"];
    final Object? equalizer = json["equalizer"];
    final Object? demixer = json["demixer"];

    final Map<int, double> gains = {};
    if (equalizer is Json && equalizer["gain"] is Json) {
      (equalizer["gain"] as Json).forEach((key, value) {
        final int? band = int.tryParse(key);
        final double? gain = _toDouble(value);
        if (band != null && gain != null) gains[band] = gain;
      });
    }

    final Map<StemType, ({bool enabled, double volume})> stems = {};
    if (demixer is Json) {
      demixer.forEach((key, value) {
        final StemType? type = StemType.values.asNameMap()[key];
        if (type == null || value is! Json) return;

        stems[type] = (
          enabled: value["enabled"] is bool ? value["enabled"] as bool : true,
          volume: _toDouble(value["volume"]) ?? 0.5,
        );
      });
    }

    return SongPreferences(
      position: _toDuration(json["position"]),
      speed: slowdowner is Json ? _toDouble(slowdowner["speed"]) : null,
      pitch: slowdowner is Json ? _toDouble(slowdowner["pitch"]) : null,
      loopStart: looper is Json ? _toDuration(looper["start"]) : null,
      loopEnd: looper is Json ? _toDuration(looper["end"]) : null,
      numEqualizerBands: equalizer is Json ? _toInt(equalizer["bands"]) : null,
      equalizerGains: gains.isEmpty ? null : gains,
      shouldDemix: json["demix"] is bool ? json["demix"] as bool : null,
      stems: stems.isEmpty ? null : stems,
    );
  }

  /// Positions and loop points were stored in milliseconds up to build 69.
  static Duration? _toDuration(Object? value) =>
      value is num ? Duration(milliseconds: value.toInt()) : null;

  static double? _toDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  static int? _toInt(Object? value) => value is num ? value.toInt() : null;
}

class _Migration {
  _Migration(this.version, this.run);

  /// The build number this migration brings data up to.
  final int version;

  final FutureOr<void> Function() run;
}
