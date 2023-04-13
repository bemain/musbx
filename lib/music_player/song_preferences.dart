import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Helper class for saving preferences for songs to disk.
class SongPreferences {
  /// Used internally to cache the [preferencesDirectory].
  Directory? _preferencesDirectory;

  /// The [Directory] where song preferences are located.
  Future<Directory> get preferencesDirectory async {
    _preferencesDirectory ??= Directory(
        "${(await getApplicationDocumentsDirectory()).path}/song_preferences");
    return await _preferencesDirectory!.create(recursive: true);
  }

  /// Get the preferences file for the song with [songId].
  Future<File> _getFileForSong(String songId) async {
    return File("${(await preferencesDirectory).path}/$songId.json");
  }

  /// Load preferences for the song with [songId].
  Future<Map<String, dynamic>?> load(String songId) async {
    File preferencesFile = await _getFileForSong(songId);

    if (!await preferencesFile.exists()) return null;

    return jsonDecode(await preferencesFile.readAsString());
  }

  /// Save preferences for the song with [songId].
  Future<void> save(
    String songId,
    Map<String, dynamic> preferences,
  ) async {
    File preferencesFile = await _getFileForSong(songId);

    await preferencesFile.writeAsString(jsonEncode(preferences));
  }

  /// Clear the preferences for all songs.
  Future<void> clear() async {
    if (await (await preferencesDirectory).exists()) {
      (await preferencesDirectory).delete(recursive: true);
    }
  }
}
