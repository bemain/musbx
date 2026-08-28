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

  final int semitonesFromC;

  /// The number of perfect fifths from this chroma and c, following the circle of fifths.
  ///
  /// Returns a negative number if the fifths are descending (if this key would introduce flat accidentals)
  int get fifthsFromC => [
    for (var i = -5; i <= 6; i++) i,
  ].firstWhere((i) => (i * 7) % 12 == semitonesFromC);

  Chroma transposed(int semitones) => Chroma.values.singleWhere(
    (chroma) => chroma.semitonesFromC == (semitonesFromC + semitones) % 12,
  );
}
