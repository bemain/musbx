import 'package:flutter/material.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';

class SettingsRepository {
  SettingsRepository({required SharedPreferencesService sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferencesService _sharedPreferences;

  late final SongSettingsRepository songs = SongSettingsRepository._(
    _sharedPreferences,
  );

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
