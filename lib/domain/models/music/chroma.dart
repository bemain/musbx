/// A set of pitches that are a whole number of octaves apart, e.g. "C" or "F♯".
enum Chroma {
  c(0),
  cSharp(1),
  d(2),
  dSharp(3),
  e(4),
  f(5),
  fSharp(6),
  g(7),
  gSharp(8),
  a(9),
  aSharp(10),
  b(11);

  const Chroma(this.semitonesFromC);

  /// How far above C this chroma sits, between `0` and `11`.
  final int semitonesFromC;

  /// The number of perfect fifths between C and this chroma, following the
  /// circle of fifths.
  ///
  /// Negative if the fifths are descending, i.e. if a major key on this chroma
  /// has flats.
  int get fifthsFromC => [
    for (var i = -5; i <= 6; i++) i,
  ].firstWhere((i) => (i * 7) % 12 == semitonesFromC);

  /// Transpose this chroma a number of semitones, wrapping around the octave.
  Chroma transposed(int semitones) => Chroma.values.singleWhere(
    (chroma) => chroma.semitonesFromC == (semitonesFromC + semitones) % 12,
  );
}
