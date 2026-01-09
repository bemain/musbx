import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

/// Helper class for persisting history entries to disk.
class HistoryHandler<T> extends ChangeNotifier {
  HistoryHandler({
    required this.fromJson,
    required this.toJson,
    required this.historyFileName,
    this.onEntryRemoved,
    this.maxEntries,
  });

  /// The maximum number of entries saved in history.
  final int? maxEntries;

  /// The name of the file where entries are persisted, without extension.
  final String historyFileName;

  /// Convert json from the history file to the desired type.
  final T Function(dynamic json) fromJson;

  /// Convert a history entry to json, that is then saved to the history file.
  final dynamic Function(T value) toJson;

  /// Callback for when an entry is removed from the history due to [maxEntries] being exceeded.
  final void Function(MapEntry<DateTime, T> entry)? onEntryRemoved;

  /// The file where song history is saved.
  File get _historyFile => File(
    "${Directories.applicationDocumentsDir("").path}/$historyFileName.json",
  );

  /// The history entries, with the previously loaded songs and the time they were loaded.
  final Map<DateTime, T> entries = {};

  /// The previously played songs, sorted by date.
  List<T> sorted({bool ascending = false}) {
    List<T> sorted =
        (entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            .map((entry) => entry.value)
            .toList();
    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Fetch the history from disk.
  ///
  /// Notifies listeners when done.
  Future<void> fetch() async {
    if (!await _historyFile.exists()) return;
    Json json;
    try {
      json = jsonDecode(await _historyFile.readAsString()) as Json;
    } catch (e) {
      debugPrint(
        "[HISTORY] Unable to read history file ${_historyFile.path} as json: $e",
      );
      return;
    }

    entries.clear();

    for (var entry in json.entries) {
      DateTime? date = DateTime.tryParse(entry.key);
      T? value;
      try {
        value = fromJson(entry.value);
      } catch (e) {
        debugPrint("[HISTORY] Unable to parse history entry: $e");
      }
      if (date != null && value != null) entries[date] = value;
    }

    notifyListeners();
  }

  /// Add [newValue] to the history.
  /// Only keeps the [maxEntries] most recent entries.
  ///
  /// Notifies listeners when done.
  Future<void> add(T newValue) async {
    // Remove duplicates
    entries.removeWhere((key, value) => value == newValue);

    entries[DateTime.now()] = newValue;

    // Only keep the [maxEntries] newest entries
    while (maxEntries != null && entries.length > maxEntries!) {
      final oldestEntry = entries.entries.reduce(
        (oldest, element) =>
            element.key.isBefore(oldest.key) ? element : oldest,
      );
      entries.remove(oldestEntry.key);
      onEntryRemoved?.call(oldestEntry);
    }

    await save();
    notifyListeners();
  }

  /// Remove [value] from the history.
  ///
  /// Notifies listeners when done.
  Future<void> remove(T value) async {
    if (!entries.values.contains(value)) return;

    entries.removeWhere((key, v) => v == value);

    onEntryRemoved?.call(MapEntry(DateTime.now(), value));

    await save();
    notifyListeners();
  }

  /// Save the current history entries to disk.
  Future<void> save() async {
    await _historyFile.create(recursive: true);
    await _historyFile.writeAsString(
      jsonEncode(
        entries.map(
          (date, song) => MapEntry(
            date.toString(),
            toJson(song),
          ),
        ),
      ),
    );
  }

  /// Remove all history entries.
  Future<void> clear() async {
    for (var value in entries.values.toList()) {
      await remove(value);
    }
  }
}
