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

  @override
  String toString() => abbreviation;
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

  /// The first note if this key, which provides a sense of arrival or rest.
  final PitchClass tonic;

  /// The type of this key, which describes the relationship between the [tonic] and the remaining [notes] in the key.
  final KeyType type;

  /// All the notes in this ḱey.
  List<PitchClass> get notes => type.intervalPattern
      .map((int interval) => tonic.transposed(interval))
      .toList();

  KeySignature get signature => KeySignature.fromKey(this);

  /// The key parallel to this one.
  /// It contains the same [notes] as this, but has a different [tonic] and [type].
  Key get parallelKey => switch (type) {
        KeyType.major => Key(tonic.transposed(-3), KeyType.minor),
        KeyType.minor => Key(tonic.transposed(3), KeyType.major),
      };

  /// Transpose this key a number of semitones.
  /// This doesn't change the `Key`'s [type].
  Key transposed(int semitones) {
    return Key(tonic.transposed(semitones), type);
  }

  String get abbreviation => "${tonic.abbreviation}${type.abbreviation}";

  @override
  String toString() => "Key(${tonic.abbreviation}, ${type.abbreviation})";
}

enum Accidental {
  sharp("♯"),
  flat("♭"),
  natural("♮");

  /// The types of accidentals that a [KeySignature] can introduce.
  const Accidental(this.abbreviation);

  final String abbreviation;
}

class KeySignature {
  /// Representation of a musical key signature.
  ///
  /// A key signature is a set of sharp, flat, or natural symbols placed at the
  /// beginning of a section of music, indicating persistent accidentals.
  KeySignature(this.nAccidentals, this.accidental);

  factory KeySignature.fromKey(Key key) {
    PitchClass majorTonic =
        key.type == KeyType.major ? key.tonic : key.parallelKey.tonic;
    return KeySignature(
      switch (majorTonic) {
        PitchClass.c => 0,
        PitchClass.g || PitchClass.f => 1,
        PitchClass.d || PitchClass.bFlat => 2,
        PitchClass.a || PitchClass.eFlat => 3,
        PitchClass.e || PitchClass.aFlat => 4,
        PitchClass.b || PitchClass.dFlat => 5,
        PitchClass.gFlat => 6,
      },
      switch (majorTonic) {
        PitchClass.c => Accidental.natural,
        PitchClass.g ||
        PitchClass.d ||
        PitchClass.a ||
        PitchClass.e ||
        PitchClass.b ||
        PitchClass.gFlat =>
          Accidental.sharp,
        PitchClass.f ||
        PitchClass.bFlat ||
        PitchClass.eFlat ||
        PitchClass.aFlat ||
        PitchClass.dFlat ||
        PitchClass.gFlat =>
          Accidental.flat,
      },
    );
  }

  /// The type of accidental that this key signature introduces.
  final Accidental accidental;

  /// The number of accidentals that this key signature introduces.
  final int nAccidentals;

  /// The notes that are altered by this key signature.
  List<PitchClass> get alteredNotes => switch (accidental) {
        Accidental.natural => [],
        Accidental.sharp => [
            PitchClass.gFlat,
            PitchClass.dFlat,
            PitchClass.aFlat,
            PitchClass.eFlat,
            PitchClass.bFlat,
            PitchClass.f
          ].sublist(0, nAccidentals),
        Accidental.flat => [
            PitchClass.bFlat,
            PitchClass.eFlat,
            PitchClass.aFlat,
            PitchClass.dFlat,
            PitchClass.gFlat,
            PitchClass.b
          ].sublist(0, nAccidentals),
      };

  @override
  String toString() {
    return "KeySignature($nAccidentals, ${accidental.abbreviation})";
  }
}
