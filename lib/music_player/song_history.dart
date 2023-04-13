import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/song.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class for saving the history of previously played songs to disk.
class SongHistory extends ChangeNotifier {
  /// The maximum number of songs saved in history.
  final int historyLength = 2;

  final Map<DateTime, Song> history = {};

  /// The file where song history is saved.
  Future<File> get _historyFile async => File(
      "${(await getApplicationDocumentsDirectory()).path}/song_history.json");

  /// Fetch the history from disk.
  ///
  /// Notifies listeners when done.
  Future<void> fetch() async {
    File file = await _historyFile;
    if (!await file.exists()) return;
    Map<String, dynamic> json = jsonDecode(await file.readAsString());

    history.clear();

    json.forEach((key, value) {
      DateTime? date = DateTime.tryParse(key);

      if (date == null ||
          value is! Map<String, dynamic> ||
          !value.containsKey("id") ||
          !value.containsKey("title") ||
          !value.containsKey("sourceUri")) {
        debugPrint(
            "Incorrectly formatted entry in history file: ($key, $value)");
        return;
      }

      Song song = Song.fromJson(value);

      history[date] = song;
    });

    notifyListeners();
  }

  /// Add [song] to the history.
  ///
  /// Notifies listeners when done.
  Future<void> add(Song song) async {
    // Remove duplicates
    history.removeWhere((key, value) => value.id == song.id);

    history[DateTime.now()] = song;
    await save();

    notifyListeners();
  }

  /// Save history entries to disk.
  Future<void> save() async {
    // Only save the [historyLength] newest entries
    while (history.length > historyLength) {
      history.remove(history.entries
          .reduce((oldest, element) =>
              element.key.isBefore(oldest.key) ? element : oldest)
          .key);
    }

    await (await _historyFile).writeAsString(jsonEncode(history.map(
      (date, song) => MapEntry(
        date.toString(),
        song.toJson(),
      ),
    )));
  }
}
