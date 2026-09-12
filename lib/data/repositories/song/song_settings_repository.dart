import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';

class SongSettingsRepository {
  SongSettingsRepository({required SharedPreferencesService sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferencesService _sharedPreferences;

  // TODO: Remove once we introduce 'provider'.
  static late final SongSettingsRepository instance;
  static Future<void> initialize() async {
    instance = SongSettingsRepository(
      sharedPreferences: SharedPreferencesService.instance,
    );
  }

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
