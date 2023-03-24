import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Helper class for saving preferences for songs to disk.
class SongPreferences {
  final Future<Directory> _documentsDirectory =
      getApplicationDocumentsDirectory();
  File? _preferencesFile;

  /// The file where song preferences are saved
  Future<File> get preferencesFile async {
    _preferencesFile ??=
        File("${(await _documentsDirectory).path}/song_preferences.json");

    return _preferencesFile!;
  }

  /// Load preferences for a song.
  Future<Map<String, dynamic>> loadPreferencesForSong() async {
    if (!await (await preferencesFile).exists()) return {};

    return jsonDecode(await (await preferencesFile).readAsString());
  }

  /// Save preferences for a song.
  Future<void> savePreferencesForSong(Map<String, dynamic> preferences) async {
    await (await preferencesFile).writeAsString(jsonEncode(preferences));
  }

  Future<void> clearPreferences() async {
    if (await (await preferencesFile).exists()) {
      (await preferencesFile).delete();
    }
  }
}
