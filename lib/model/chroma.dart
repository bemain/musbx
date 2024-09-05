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

  Chroma transposed(int semitones) => Chroma.values.singleWhere(
        (chroma) => chroma.semitonesFromC == (semitonesFromC + semitones) % 12,
      );
}
