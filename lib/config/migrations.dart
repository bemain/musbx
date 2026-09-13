import 'dart:async';

import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Brings data written by an older build up to date.
///
/// Runs once per launch, before anything reads the caches. Each migration names
/// the build number it belongs to and runs only when the app has crossed it, so
/// skipping several versions still applies each one in turn.
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
  /// Does nothing on a fresh install or an unchanged build.
  Future<void> run() async {
    final int current = int.parse(_packageInfo.buildNumber);
    final int? previous = int.tryParse(_lastVersionLaunched.value);
    if (previous == null || previous == current) return;

    for (final migration in _migrations) {
      if (previous < migration.version && current >= migration.version) {
        await migration.run();
      }
    }

    _lastVersionLaunched.value = current.toString();
  }

  late final List<_Migration> _migrations = [
    _Migration(39, () async {
      // Delete the old cache and shared_preferences layout
      await _sharedPreferences.clear();
      await _fileCache.persistent.directory("songs").delete(recursive: true);
    }),
  ];
}

class _Migration {
  _Migration(this.version, this.run);

  final int version;
  final FutureOr<void> Function() run;
}
