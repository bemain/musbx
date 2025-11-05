import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransformedPersistentValue<T, S> extends ValueNotifier<T> {
  /// A value that is converted to a primitive data type using the given [to]
  /// method and then persisted to disk whenever it changes.
  /// The [from] method is in turn used when reading the value from disk.
  ///
  /// The type of the data after conversion ([S]) has to be one of the supported
  /// primitive data types. See [PersistentValue].
  TransformedPersistentValue(
    String key, {
    required T initialValue,
    required this.to,
    required this.from,
  }) : _primitiveValue = PersistentValue<S>(
         key,
         initialValue: to(initialValue),
       ),
       super(initialValue) {
    value = from(_primitiveValue.value);
  }

  final PersistentValue<S> _primitiveValue;

  final S Function(T value) to;
  final T Function(S value) from;

  @override
  set value(T value) {
    _primitiveValue.value = to(value);
    super.value = value;
  }
}

class PersistentValue<T> extends ValueNotifier<T> {
  /// A value that is persisted to disk whenever it changes.
  PersistentValue(this.key, {required T initialValue}) : super(initialValue) {
    assert(
      [bool, String, int, double, List<String>].contains(T),
      "Unsupported type for PersistentValue: $T",
    );

    if (preferences.get(key) == null) value = initialValue;
  }

  /// Whether this class has been initialized by calling [initialize].
  static bool isInitialized = false;

  /// Used internally to persist values to disk.
  static late final SharedPreferencesWithCache preferences;

  /// The key to where the value is persisted to disk.
  final String key;

  @override
  T get value => (<T>[] is List<List>)
      ? preferences.getStringList(key)!.cast<String>() as T
      : preferences.get(key) as T;
  @override
  set value(T newValue) {
    if (preferences.get(key) == newValue) return; // Do nothing

    if (newValue is bool) preferences.setBool(key, newValue);
    if (newValue is String) preferences.setString(key, newValue);
    if (newValue is int) preferences.setInt(key, newValue);
    if (newValue is double) preferences.setDouble(key, newValue);
    if (newValue is List<String>) preferences.setStringList(key, newValue);

    notifyListeners();
  }

  static Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;
    preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }
}
