import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/chroma.dart';
import 'package:musbx/model/pitch_class.dart';

enum KeyType {
  major("", [0, 2, 4, 5, 7, 9, 11]),
  minor("m", [0, 2, 3, 5, 7, 8, 10]);

  /// The different types of keys.
  ///
  /// This describes the relationship between the tonic and the remaining notes in the key.
  const KeyType(this.abbreviation, this.intervalPattern);

  final String abbreviation;

  final List<int> intervalPattern;
}

/// Representation of a musical key.
///
/// A key is the group of pitches that forms the basis of most western music.
/// A key is characterised by its [tonic] which provides a sense of arrival or rest,
/// and its [type] which describes the relationship between the [tonic] and the remaining [notes] in the key.
class Key {
  const Key(this.tonic, this.type);

  const Key.major(this.tonic) : type = KeyType.major;
  const Key.minor(this.tonic) : type = KeyType.minor;

  /// The first note in this key, which provides a sense of arrival or rest.
  final PitchClass tonic;

  /// The type of this key, which describes the relationship between the [tonic] and the remaining [notes] in the key.
  final KeyType type;

  /// The type of accidental that this key signature introduces.
  Accidental get accidental => switch (_majorParallel.tonic.chroma) {
    Chroma.c => Accidental.natural,
    Chroma.g ||
    Chroma.d ||
    Chroma.a ||
    Chroma.e ||
    Chroma.b ||
    Chroma.fSharp => Accidental.sharp,
    Chroma.f ||
    Chroma.aSharp ||
    Chroma.dSharp ||
    Chroma.gSharp ||
    Chroma.cSharp ||
    Chroma.fSharp => Accidental.flat,
  };

  /// The number of accidentals that this key signature introduces.
  int get nAccidentals => switch (_majorParallel.tonic.chroma) {
    Chroma.c => 0,
    Chroma.g || Chroma.f => 1,
    Chroma.d || Chroma.aSharp => 2,
    Chroma.a || Chroma.dSharp => 3,
    Chroma.e || Chroma.gSharp => 4,
    Chroma.b || Chroma.cSharp => 5,
    Chroma.fSharp => 6,
  };

  /// All the notes in this ḱey.
  Iterable<PitchClass> get notes =>
      type.intervalPattern.map((interval) => tonic.transposed(interval));

  /// The key parallel to this one.
  /// It contains the same [notes] as this, but has a different [tonic] and [type].
  Key get parallel => switch (type) {
    KeyType.major => Key(tonic.transposed(-3), KeyType.minor),
    KeyType.minor => Key(tonic.transposed(3), KeyType.major),
  };

  /// Returns [this] if this is major, or [parallel] otherwise.
  Key get _majorParallel => type == KeyType.major ? this : parallel;

  /// Transpose this key a number of semitones.
  /// This doesn't change the `Key`'s [type].
  Key transposed(int semitones) {
    return Key(tonic.transposed(semitones), type);
  }

  String get abbreviation => "${tonic.abbreviation}${type.abbreviation}";

  @override
  String toString() => "Key(${tonic.abbreviation}, ${type.abbreviation})";

  @override
  bool operator ==(Object other) =>
      other is Key && tonic == other.tonic && type == other.type;

  @override
  int get hashCode => Object.hash(tonic, type);
}
