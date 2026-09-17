import 'package:flutter/material.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';

/// The user's app-wide preferences, persisted as they change.
class SettingsRepository {
  SettingsRepository({required SharedPreferencesService sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferencesService _sharedPreferences;

  late final SongSettingsRepository songs = SongSettingsRepository._(
    _sharedPreferences,
  );

  /// Whether to follow the system theme, or force light or dark.
  ThemeMode get themeMode => themeModeNotifier.value;
  late final TransformedPersistentValue<ThemeMode, String> themeModeNotifier =
      _sharedPreferences.transformed<ThemeMode, String>(
        "theme/mode",
        initialValue: ThemeMode.system,
        to: (value) => value.name,
        from: (value) =>
            ThemeMode.values.asNameMap()[value] ?? ThemeMode.system,
      );
}

/// Preferences applying to every song, as opposed to a single one.
///
/// See `SongPreferences` for the per-song counterpart.
class SongSettingsRepository {
  SongSettingsRepository._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  /// Whether to automatically demix new songs.
  bool get demixAutomatically => demixAutomaticallyNotifier.value;
  set demixAutomatically(bool value) =>
      demixAutomaticallyNotifier.value = value;
  late final ValueNotifier<bool> demixAutomaticallyNotifier =
      _sharedPreferences.value(
        "songs/autoDemix",
        initialValue: true,
      );
}
