import 'package:flutter/material.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';
import 'package:musbx/domain/models/music/temperament.dart';

/// The user's app-wide preferences, persisted as they change.
class SettingsRepository {
  SettingsRepository({required SharedPreferencesService sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferencesService _sharedPreferences;

  late final SongSettingsRepository songs = SongSettingsRepository._(
    _sharedPreferences,
  );

  late final TunerSettingsRepository tuner = TunerSettingsRepository._(
    _sharedPreferences,
  );

  late final MetronomeSettingsRepository metronome =
      MetronomeSettingsRepository._(_sharedPreferences);

  /// Whether to follow the system theme, or force light or dark.
  ThemeMode get themeMode => themeModeNotifier.value;
  set themeMode(ThemeMode value) => themeModeNotifier.value = value;
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
class SongSettingsRepository extends ChangeNotifier {
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
      )..addListener(notifyListeners);
}

class TunerSettingsRepository extends ChangeNotifier {
  TunerSettingsRepository._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  Pitch get tuning => tuningNotifier.value;
  set tuning(Pitch value) => tuningNotifier.value = value;
  late final ValueNotifier<Pitch> tuningNotifier =
      _sharedPreferences.transformed<Pitch, String>(
        "tuner/tuning",
        initialValue: const Pitch(PitchClass.a(), 4, 440),
        from: Pitch.parse,
        to: (pitch) => pitch.toString(),
      )..addListener(notifyListeners);

  Temperament get temperament => temperamentNotifier.value;
  set temperament(Temperament value) => temperamentNotifier.value = value;
  late final ValueNotifier<Temperament> temperamentNotifier = ValueNotifier(
    const EqualTemperament(),
  )..addListener(notifyListeners);

  Accidental get preferredAccidental => preferredAccidentalNotifier.value;
  set preferredAccidental(Accidental value) =>
      preferredAccidentalNotifier.value = value;
  late final ValueNotifier<Accidental> preferredAccidentalNotifier =
      _sharedPreferences.transformed<Accidental, String>(
        "tuner/accidental",
        initialValue: Accidental.natural,
        to: (accidental) => accidental.name,
        from: (string) => Accidental.values.firstWhere(
          (accidental) => accidental.name == string,
        ),
      )..addListener(notifyListeners);
}

class MetronomeSettingsRepository extends ChangeNotifier {
  MetronomeSettingsRepository._(this._sharedPreferences);

  final SharedPreferencesService _sharedPreferences;

  /// Whether to show a notification while the Metronome is playing.
  bool get showNotification => showNotificationNotifier.value;
  set showNotification(bool value) => showNotificationNotifier.value = value;
  late final PersistentValue<bool> showNotificationNotifier =
      _sharedPreferences.value(
        "metronome/notification",
        initialValue: true,
      )..addListener(notifyListeners);
}
