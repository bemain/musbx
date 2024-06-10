import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A value that is persisted to disk whenever it changes.
class PersistentValue<T extends dynamic> extends ChangeNotifier {
  /// Used internally to persist values to disk.
  static late final SharedPreferences _preferences;

  PersistentValue(this.key, {required T initialValue}) {
    assert(
      [bool, String, int, double, List<String>].contains(T),
      "Unsupported type for PersistentValue: $T",
    );

    if (!_preferences.containsKey(key)) value = initialValue;
  }

  final String key;

  T get value => _preferences.get(key) as T;
  set value(T newValue) {
    if (newValue == null) return;
    if (newValue is bool) _preferences.setBool(key, newValue);
    if (newValue is String) _preferences.setString(key, newValue);
    if (newValue is int) _preferences.setInt(key, newValue);
    if (newValue is double) _preferences.setDouble(key, newValue);
    if (newValue is List<String>) _preferences.setStringList(key, newValue);
  }

  /// Whether this class has been initialized by calling [initialize].
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;
    _preferences = await SharedPreferences.getInstance();
  }
}
