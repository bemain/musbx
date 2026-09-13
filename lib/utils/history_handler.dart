import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/utils/utils.dart';

/// Entries kept in the order they were last used, persisted to disk.
///
/// Each entry is stored against the time it was added. Adding one that is
/// already there moves it to the top rather than duplicating it, which is what
/// makes this usable both as a history and as a library.
// TODO: Rethink
class HistoryHandler<T> extends ChangeNotifier {
  HistoryHandler({
    required this.file,
    required this.fromJson,
    required this.toJson,
    this.onEntryRemoved,
    this.maxEntries,
  });

  /// The file the entries are persisted to.
  final CacheFile file;

  /// The maximum number of entries saved in history.
  final int? maxEntries;

  /// Convert json from the history file to the desired type.
  final T Function(dynamic json) fromJson;

  /// Convert a history entry to json, that is then saved to the history file.
  final dynamic Function(T value) toJson;

  /// Callback for when an entry is removed from the history due to [maxEntries] being exceeded.
  final FutureOr<void> Function(MapEntry<DateTime, T> entry)? onEntryRemoved;

  /// The entries, against the time each was last added.
  final Map<DateTime, T> entries = {};

  /// The entries, sorted by the time they were last added.
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
    final Json? json;
    try {
      json = await file.readJson();
    } catch (e) {
      debugPrint(
        "[HISTORY] Unable to read history file ${file.path} as json: $e",
      );
      return;
    }

    if (json == null) return;

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
      await onEntryRemoved?.call(oldestEntry);
    }

    await save();
    notifyListeners();
  }

  /// Replace the stored value equal to [value], keeping its position in history.
  Future<void> update(T value) async {
    final key = entries.entries
        .where((e) => e.value == value)
        .firstOrNull
        ?.key;
    if (key == null) return;

    entries[key] = value;
    await save();
    notifyListeners();
  }

  /// Remove [value] from the history.
  ///
  /// Notifies listeners when done.
  Future<void> remove(T value) async {
    if (!entries.values.contains(value)) return;

    entries.removeWhere((key, v) => v == value);

    await onEntryRemoved?.call(MapEntry(DateTime.now(), value));

    await save();
    notifyListeners();
  }

  /// Save the current history entries to disk.
  Future<void> save() async {
    await file.writeJson(
      entries.map(
        (date, song) => MapEntry(
          date.toString(),
          toJson(song),
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
