import 'package:flutter/material.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';
import 'package:musbx/domain/models/music/temperament.dart';

/// The user's app-wide preferences, persisted as they change.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository({required SharedPreferencesService sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferencesService _sharedPreferences;

  late final SongSettings songs = SongSettings._(_sharedPreferences);
  late final TunerSettings tuner = TunerSettings._(_sharedPreferences);
  late final MetronomeSettings metronome = MetronomeSettings._(
    _sharedPreferences,
  );

  /// Whether to follow the system theme, or force light or dark.
  ThemeMode get themeMode => _themeMode.value;
  set themeMode(ThemeMode value) => _themeMode.value = value;
  late final TransformedPersistentValue<ThemeMode, String> _themeMode =
      _sharedPreferences.transformed<ThemeMode, String>(
        "theme/mode",
        initialValue: ThemeMode.system,
        to: (value) => value.name,
        from: (value) =>
            ThemeMode.values.asNameMap()[value] ?? ThemeMode.system,
      )..addListener(notifyListeners);
}

/// Preferences applying to every song, as opposed to a single one.
///
/// See `SongPreferences` for the per-song counterpart.
class SongSettings extends ChangeNotifier {
  SongSettings._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  /// Whether to automatically demix new songs.
  bool get demixAutomatically => _demixAutomatically.value;
  set demixAutomatically(bool value) => _demixAutomatically.value = value;
  late final ValueNotifier<bool> _demixAutomatically =
      _sharedPreferences.value(
        "songs/autoDemix",
        initialValue: true,
      )..addListener(notifyListeners);
}

class TunerSettings extends ChangeNotifier {
  TunerSettings._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  Pitch get tuning => _tuning.value;
  set tuning(Pitch value) => _tuning.value = value;
  late final ValueNotifier<Pitch> _tuning =
      _sharedPreferences.transformed<Pitch, String>(
        "tuner/tuning",
        initialValue: const Pitch(PitchClass.a(), 4, 440),
        from: Pitch.parse,
        to: (pitch) => pitch.toString(),
      )..addListener(notifyListeners);

  Temperament get temperament => _temperament.value;
  set temperament(Temperament value) => _temperament.value = value;
  late final ValueNotifier<Temperament> _temperament = ValueNotifier(
    const EqualTemperament(),
  )..addListener(notifyListeners);

  Accidental get preferredAccidental => _preferredAccidental.value;
  set preferredAccidental(Accidental value) =>
      _preferredAccidental.value = value;
  late final ValueNotifier<Accidental> _preferredAccidental =
      _sharedPreferences.transformed<Accidental, String>(
        "tuner/accidental",
        initialValue: Accidental.natural,
        to: (accidental) => accidental.name,
        from: (string) => Accidental.values.firstWhere(
          (accidental) => accidental.name == string,
        ),
      )..addListener(notifyListeners);
}

class MetronomeSettings extends ChangeNotifier {
  MetronomeSettings._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  /// Whether to show a notification while the Metronome is playing.
  bool get showNotification => _showNotification.value;
  set showNotification(bool value) => _showNotification.value = value;
  late final PersistentValue<bool> _showNotification =
      _sharedPreferences.value(
        "metronome/notification",
        initialValue: true,
      )..addListener(notifyListeners);
}
