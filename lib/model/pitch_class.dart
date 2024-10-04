import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/chroma.dart';
import 'package:musbx/model/key.dart';

/// The seven "natural" pitch classes are the ones represented by just a letter;
/// A, B, C, D, E, F and G.
enum NaturalPitchClass {
  c("C", Chroma.c),
  d("D", Chroma.d),
  e("E", Chroma.e),
  f("F", Chroma.f),
  g("G", Chroma.g),
  a("A", Chroma.a),
  b("B", Chroma.b);

  const NaturalPitchClass(this.abbreviation, this.chroma);

  final String abbreviation;

  /// The chroma that this pitch class belongs to.
  final Chroma chroma;
}

class PitchClass {
  /// A set of all pitches that share the same [chroma].
  /// Due to enharmonic equivalence, they can belong to different [NaturalPitchClass]es and have different [accidental]s.
  const PitchClass(this.naturalClass, [this.accidental = Accidental.natural]);

  /// The "natural" pitch class (the seven pitch classes represented by just a letter)
  /// that is the basis of this pitch class.
  final NaturalPitchClass naturalClass;

  /// The accidental indicating the alteration of the [naturalClass].
  final Accidental accidental;

  const PitchClass.c()
      : naturalClass = NaturalPitchClass.c,
        accidental = Accidental.natural;
  const PitchClass.cSharp()
      : naturalClass = NaturalPitchClass.c,
        accidental = Accidental.sharp;
  const PitchClass.dFlat()
      : naturalClass = NaturalPitchClass.d,
        accidental = Accidental.flat;
  const PitchClass.d()
      : naturalClass = NaturalPitchClass.d,
        accidental = Accidental.natural;
  const PitchClass.dSharp()
      : naturalClass = NaturalPitchClass.d,
        accidental = Accidental.sharp;
  const PitchClass.eFlat()
      : naturalClass = NaturalPitchClass.e,
        accidental = Accidental.flat;
  const PitchClass.e()
      : naturalClass = NaturalPitchClass.e,
        accidental = Accidental.natural;
  const PitchClass.f()
      : naturalClass = NaturalPitchClass.f,
        accidental = Accidental.natural;
  const PitchClass.fSharp()
      : naturalClass = NaturalPitchClass.f,
        accidental = Accidental.sharp;
  const PitchClass.gFlat()
      : naturalClass = NaturalPitchClass.g,
        accidental = Accidental.flat;
  const PitchClass.g()
      : naturalClass = NaturalPitchClass.g,
        accidental = Accidental.natural;
  const PitchClass.gSharp()
      : naturalClass = NaturalPitchClass.g,
        accidental = Accidental.sharp;
  const PitchClass.aFlat()
      : naturalClass = NaturalPitchClass.a,
        accidental = Accidental.flat;
  const PitchClass.a()
      : naturalClass = NaturalPitchClass.a,
        accidental = Accidental.natural;
  const PitchClass.aSharp()
      : naturalClass = NaturalPitchClass.a,
        accidental = Accidental.sharp;
  const PitchClass.bFlat()
      : naturalClass = NaturalPitchClass.b,
        accidental = Accidental.flat;
  const PitchClass.b()
      : naturalClass = NaturalPitchClass.b,
        accidental = Accidental.natural;

  /// Creates a pitch class with the given [chroma].
  ///
  /// Tries using the [preferredAccidental], and fallbacks to the most
  /// common one (meaning the one found in a key close to C in the circle of fifths)
  /// if the given [chroma] could not be achieved using the preferred accidental.
  factory PitchClass.fromChroma(
    Chroma chroma, {
    Accidental? preferredAccidental,
  }) {
    if (preferredAccidental != null) {
      NaturalPitchClass? preferredNatural = NaturalPitchClass.values
          .where((natural) =>
              natural.chroma.semitonesFromC + preferredAccidental.alteration ==
              chroma.semitonesFromC)
          .firstOrNull;

      if (preferredNatural != null) {
        return PitchClass(
          preferredNatural,
          preferredAccidental,
        );
      }
    }

    /// The accidental most commonly used for this pitch class,
    /// meaning the one found in a key close to C in the circle of fifths
    final Accidental commonAccidental = switch (chroma.semitonesFromC) {
      1 || 6 || 8 => Accidental.sharp,
      3 || 10 => Accidental.flat,
      _ => Accidental.natural,
    };

    return PitchClass(
      NaturalPitchClass.values.firstWhere((natural) =>
          natural.chroma.semitonesFromC + commonAccidental.alteration ==
          chroma.semitonesFromC),
      commonAccidental,
    );
  }

  /// Parse [string] as a pitch class.
  /// Throws a [FormatException] if [string] is not a valid pitch class.
  static PitchClass parse(String string) {
    final PitchClass? pitchClass = tryParse(string);
    if (pitchClass == null) {
      throw FormatException("$string is not a valid PitchClass");
    }
    return pitchClass;
  }

  /// Parse [string] as a pitch class.
  /// Returns `null` if [string] is not a valid pitch class.
  static PitchClass? tryParse(String string) {
    final String trimmed = string.replaceAll("b", "♭").replaceAll("#", "♯");
    final NaturalPitchClass? natural = NaturalPitchClass.values
        .where((natural) => natural.abbreviation == trimmed[0])
        .singleOrNull;
    final Accidental? accidental = Accidental.values
        .where((accidental) =>
            accidental.abbreviation == (trimmed.length > 1 ? trimmed[1] : null))
        .firstOrNull;

    if (natural == null) return null;
    return PitchClass(natural, accidental ?? Accidental.natural);
  }

  /// The "quality" of the pitches in this pitch class.
  /// Due to enharmonic equivalence, many pitch classes (e.g F# and Gb) share the same chroma.
  Chroma get chroma => naturalClass.chroma.transposed(accidental.alteration);

  int get semitonesFromC => chroma.semitonesFromC;

  /// The name of this pitch class.
  String get abbreviation =>
      "${naturalClass.abbreviation}${accidental == Accidental.natural ? "" : accidental.abbreviation}";

  /// Transpose this pitch class a number of semitones.
  PitchClass transposed(int semitones) => PitchClass.fromChroma(
        chroma.transposed(semitones),
        preferredAccidental: Key.major(this).accidental,
      );

  @override
  bool operator ==(Object other) =>
      other is PitchClass &&
      naturalClass == other.naturalClass &&
      accidental == other.accidental;

  @override
  int get hashCode => Object.hash(naturalClass, accidental);
}
