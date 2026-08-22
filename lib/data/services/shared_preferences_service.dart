import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the small values that have to outlive a single run of the app, such
/// as settings and the user's last choices.
///
/// Values are handed out as [PersistentValue] handles rather than read and
/// written directly, so each setting has one declaration that reads it, saves
/// it, and notifies whatever is showing it.
class SharedPreferencesService {
  /// The types that can be written to disk as they are.
  static const List<Type> _supportedTypes = [
    bool,
    String,
    int,
    double,
    List<String>,
  ];

  /// Prefix on every key this service writes.
  ///
  /// Keeps [clear] from reaching preferences stored by plugins that use
  /// `shared_preferences` underneath.
  static const String _prefix = "musbx/";

  SharedPreferencesService._(this._preferences);

  /// The store backing every value this service hands out.
  final SharedPreferencesWithCache _preferences;

  /// Create the service, loading what is already stored into memory.
  ///
  /// Reads are served from that copy, which is what lets [PersistentValue.value]
  /// be read synchronously.
  static Future<SharedPreferencesService> create({
    SharedPreferencesWithCache? preferences,
  }) async {
    final p =
        preferences ??
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );

    await _migrate(p);

    return SharedPreferencesService._(p);
  }

  /// Namespaces the app stored values under before [_prefix] was introduced.
  ///
  /// Namespaces rather than whole keys, because announcement responses are
  /// stored under a key containing the id of the announcement.
  static const _legacyNamespaces = [
    "announcements/",
    "drone/",
    "metronome/",
    "songs/",
    "theme/",
    "tuner/",
  ];

  /// Keys the app stored outside any namespace before [_prefix] was introduced.
  static const _legacyKeys = ["currentBranch", "lastVersionLaunched"];

  /// Move values stored before [_prefix] was introduced under it.
  ///
  /// Has to run before anything reads a value: an unmigrated key reads as its
  /// initial value, which would look to [LaunchHandler] like a fresh install
  /// and trigger the migration that erases settings and the song library.
  ///
  /// Only keys the app is known to have written are moved, so that preferences
  /// belonging to plugins are left where they are. Once moved they are removed,
  /// so later runs find nothing to do.
  ///
  /// TODO: Remove in a future version
  static Future<void> _migrate(SharedPreferencesWithCache preferences) async {
    final legacyKeys = preferences.keys
        .where(
          (key) =>
              !key.startsWith(_prefix) &&
              (_legacyKeys.contains(key) ||
                  _legacyNamespaces.any(key.startsWith)),
        )
        .toList();

    for (final key in legacyKeys) {
      final prefixedKey = "$_prefix$key";

      // Never overwrite a value that has already been migrated.
      if (preferences.get(prefixedKey) == null) {
        switch (preferences.get(key)) {
          case final bool value:
            await preferences.setBool(prefixedKey, value);
          case final int value:
            await preferences.setInt(prefixedKey, value);
          case final double value:
            await preferences.setDouble(prefixedKey, value);
          case final String value:
            await preferences.setString(prefixedKey, value);
          case List<Object?> _:
            await preferences.setStringList(
              prefixedKey,
              preferences.getStringList(key)!,
            );
        }
      }

      await preferences.remove(key);
    }
  }

  // TODO: Remove once we introduce `provider`.
  static late final SharedPreferencesService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  /// A value stored under [key], reading as [initialValue] until something has
  /// been stored there.
  ///
  /// [T] has to be one of `bool`, `String`, `int`, `double` or `List<String>`;
  /// any other type throws. Use [transformed] for everything else.
  PersistentValue<T> value<T>(String key, {required T initialValue}) =>
      PersistentValue._(
        _preferences,
        "$_prefix$key",
        initialValue: initialValue,
      );

  /// A value stored under [key] that cannot be stored as it is, converted by
  /// [to] on the way to disk and by [from] on the way back.
  ///
  /// [S] is what actually gets stored, so it has to be a type [value] accepts.
  TransformedPersistentValue<T, S> transformed<T, S>(
    String key, {
    required T initialValue,
    required S Function(T value) to,
    required T Function(S value) from,
  }) => TransformedPersistentValue._(
    _preferences,
    "$_prefix$key",
    initialValue: initialValue,
    to: to,
    from: from,
  );

  /// Remove everything stored by the app, so every value falls back to its initial one.
  ///
  /// Existing [PersistentValue] handles report their initial values again but
  /// are not notified, so anything already displaying one keeps showing the old
  /// value until it rebuilds for some other reason.
  Future<void> clear() async {
    for (final key in _preferences.keys.where((k) => k.startsWith(_prefix))) {
      await _preferences.remove(key);
    }
  }
}

/// A value that is read from and written to disk as it is used, and that
/// notifies its listeners whenever it changes.
///
/// Reads always go to the store rather than to a copy held here, so several
/// handles on the same key never disagree.
///
/// Obtained from [SharedPreferencesService.value].
class PersistentValue<T> extends ValueNotifier<T> {
  PersistentValue._(this._preferences, this._key, {required T initialValue})
    : _initialValue = initialValue,
      super(initialValue) {
    if (!SharedPreferencesService._supportedTypes.contains(T)) {
      throw ArgumentError.value(
        T,
        "T",
        "Cannot persist '$_key'. Supported types are "
            "${SharedPreferencesService._supportedTypes.join(", ")}",
      );
    }
  }

  /// Used internally to persist values to disk.
  final SharedPreferencesWithCache _preferences;

  /// The key to where the value is persisted to disk.
  final String _key;

  /// What [value] reports until something has been stored under [_key].
  ///
  /// Never written to disk, so a key the user has not touched stays unset and
  /// picks up a new default if one is chosen in a later release.
  final T _initialValue;

  /// The stored value, or [_initialValue] if nothing has been stored yet.
  @override
  T get value =>
      ((T == List<String>)
          ? _preferences.getStringList(_key)?.cast<String>() as T?
          : _preferences.get(_key) as T?) ??
      _initialValue;

  /// Store [newValue] and notify listeners.
  ///
  /// The new value can be read back immediately; reaching the disk happens in
  /// the background.
  ///
  /// A list is stored as it was at the moment it was set. Mutating that list
  /// afterwards stores nothing, and each read hands back a fresh copy.
  @override
  set value(T newValue) {
    if (_preferences.get(_key) == newValue ||
        ((T == List<String>) &&
            listEquals(
              _preferences.get(_key) as List<String>,
              newValue as List<String>,
            ))) {
      return; // Do nothing
    }

    if (newValue is bool) _preferences.setBool(_key, newValue);
    if (newValue is String) _preferences.setString(_key, newValue);
    if (newValue is int) _preferences.setInt(_key, newValue);
    if (newValue is double) _preferences.setDouble(_key, newValue);
    if (newValue is List<String>) _preferences.setStringList(_key, newValue);

    notifyListeners();
  }
}

/// A [PersistentValue] for a type that cannot be written to disk as it is.
///
/// [to] converts the value into something storable before it is written, and
/// [from] converts it back on the way out, so [S] has to be one of the types
/// [PersistentValue] accepts.
///
/// Obtained from [SharedPreferencesService.transformed].
class TransformedPersistentValue<T, S> extends ValueNotifier<T> {
  TransformedPersistentValue._(
    SharedPreferencesWithCache preferences,
    String key, {
    required T initialValue,
    required this.to,
    required this.from,
  }) : _primitiveValue = PersistentValue<S>._(
         preferences,
         key,
         initialValue: to(initialValue),
       ),
       super(initialValue) {
    value = from(_primitiveValue.value);
  }

  /// The converted value, which is what actually reaches the disk.
  final PersistentValue<S> _primitiveValue;

  /// Converts a value into the form it is stored as.
  final S Function(T value) to;

  /// Converts a stored value back.
  final T Function(S value) from;

  /// The stored value, converted back by [from].
  @override
  T get value => from(_primitiveValue.value);

  /// Store [value] and notify listeners.
  @override
  set value(T value) {
    _primitiveValue.value = to(value);
    // Only to notify listeners; the inherited field is not what [value] reads.
    super.value = value;
  }
}
