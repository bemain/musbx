/// A set of pitches that are a whole number of octaves apart, e.g. "C" or "F♯".
enum PitchClass {
  a("A"),
  bFlat("A♯", "B♭"),
  b("B", "C♭", true),
  c("B♯", "C"),
  dFlat("C♯", "D♭", true),
  d("D"),
  eFlat("D♯", "E♭"),
  e("E", "F♭", true),
  f("E♯", "F"),
  gFlat("F♯", "G♭", true),
  g("G"),
  aFlat("G♯", "A♭");

  const PitchClass(
    this.sharpAbbreviation, [
    String? flatAbbreviation,
    this._preferSharp = false,
  ]) : flatAbbreviation = flatAbbreviation ?? sharpAbbreviation;

  /// The name of this pitch class with a flat ♭ (or no) accidental.
  final String flatAbbreviation;

  /// The name of this pitch class with a sharp ♯ (or no) accidental.
  final String sharpAbbreviation;

  /// Whether [sharpAbbreviation] is preferred over [flatAbbreviation] for the default string representation.
  final bool _preferSharp;

  /// Parse [string] as a pitch class.
  /// Returns `null` if [string] is not a valid pitch class.
  static PitchClass? tryParse(String string) {
    final String trimmed = string.replaceAll("b", "♭").replaceAll("#", "♯");
    return PitchClass.values
        .where(
          (pitch) =>
              pitch.flatAbbreviation == trimmed ||
              pitch.sharpAbbreviation == trimmed,
        )
        .firstOrNull;
  }

  /// Transpose this pitch class a number of semitones.
  PitchClass transposed(int semitones) {
    return PitchClass.values[(index + semitones) % PitchClass.values.length];
  }

  @override
  String toString() => _preferSharp ? sharpAbbreviation : flatAbbreviation;
}
