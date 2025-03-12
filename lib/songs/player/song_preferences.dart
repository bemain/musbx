import 'dart:convert';
import 'dart:io';

import 'package:musbx/songs/player/song.dart';

/// Helper class for saving preferences for songs to disk.
class SongPreferences {
  /// Get the preferences file for a [song].
  Future<File> _getFileForSong(Song song) async {
    return File("${(await song.cacheDirectory).path}/preferences.json");
  }

  /// Load preferences for a [song].
  Future<Map<String, dynamic>?> load(Song song) async {
    File file = await _getFileForSong(song);
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  /// Save preferences for a [song].
  Future<void> save(Song song, Map<String, dynamic> preferences) async {
    File file = await _getFileForSong(song);

    await file.writeAsString(jsonEncode(preferences));
  }

  /// Remove the preferences for a [song].
  Future<void> remove(Song song) async {
    File file = await _getFileForSong(song);
    if (await file.exists()) await file.delete();
  }
}

/// Helper class for saving preferences for songs to disk.
class SongPreferencesNew {
  /// Get the preferences file for a [song].
  Future<File> _getFileForSong(SongNew song) async {
    return File("${(await song.cacheDirectory).path}/preferences.json");
  }

  /// Load preferences for a [song].
  Future<Map<String, dynamic>?> load(SongNew song) async {
    File file = await _getFileForSong(song);
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  /// Save preferences for a [song].
  Future<void> save(SongNew song, Map<String, dynamic> preferences) async {
    File file = await _getFileForSong(song);

    await file.writeAsString(jsonEncode(preferences));
  }

  /// Remove the preferences for a [song].
  Future<void> remove(SongNew song) async {
    File file = await _getFileForSong(song);
    if (await file.exists()) await file.delete();
  }
}
