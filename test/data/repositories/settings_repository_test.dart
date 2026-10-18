import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

import '../../helpers/fixtures.dart';

void main() {
  late SharedPreferencesService preferences;
  late SettingsRepository settings;

  setUp(() async {
    preferences = await createPreferences();
    settings = SettingsRepository(sharedPreferences: preferences);
  });

  test("defaults", () {
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.songs.demixAutomatically, isTrue);
    expect(settings.tuner.tuning, const Pitch.a440());
    expect(settings.tuner.preferredAccidental, Accidental.natural);
    expect(settings.metronome.showNotification, isTrue);
  });

  test("persisted settings survive a restart", () {
    settings
      ..themeMode = ThemeMode.dark
      ..songs.demixAutomatically = false
      ..tuner.tuning = const Pitch(PitchClass.a(), 4, 442)
      ..tuner.preferredAccidental = Accidental.flat
      ..metronome.showNotification = false;

    final restarted = SettingsRepository(sharedPreferences: preferences);
    expect(restarted.themeMode, ThemeMode.dark);
    expect(restarted.songs.demixAutomatically, isFalse);
    expect(restarted.tuner.tuning.frequency, 442);
    expect(restarted.tuner.preferredAccidental, Accidental.flat);
    expect(restarted.metronome.showNotification, isFalse);
  });

  test("an unknown stored theme falls back to the system's", () async {
    settings = SettingsRepository(
      sharedPreferences: await createPreferences({
        "musbx/theme/mode": "sepia",
      }),
    );
    expect(settings.themeMode, ThemeMode.system);
  });

  test("each group notifies its own listeners", () {
    var root = 0, songs = 0;
    settings
      ..addListener(() => root++)
      ..songs.addListener(() => songs++);

    settings.themeMode = ThemeMode.light;
    settings.songs.demixAutomatically = false;

    expect((root, songs), (1, 1));
  });
}
