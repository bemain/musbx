import 'dart:convert';
import 'dart:io';

import 'package:musbx/songs/player/song.dart';

/// Helper class for saving preferences for songs to disk.
class SongPreferences {
  /// Get the preferences file for a [song].
  File _getFileForSong(Song song) {
    return File("${song.cacheDirectory.path}/preferences.json");
  }

  /// Load preferences for a [song].
  Future<Map<String, dynamic>?> load(Song song) async {
    File file = _getFileForSong(song);
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  /// Save preferences for a [song].
  Future<void> save(Song song, Map<String, dynamic> preferences) async {
    File file = _getFileForSong(song);

    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(preferences));
  }

  /// Remove the preferences for a [song].
  Future<void> remove(Song song) async {
    File file = _getFileForSong(song);
    if (await file.exists()) await file.delete();
  }
}
