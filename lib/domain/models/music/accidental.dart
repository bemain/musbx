/// A symbol that raises or lowers a pitch by a number of semitones.
enum Accidental {
  natural("♮", 0),
  sharp("♯", 1),
  flat("♭", -1);

  const Accidental(this.abbreviation, this.alteration);

  /// The number of semitones that this alters the given pitch.
  final int alteration;

  /// The symbol written before the note, e.g. "♯".
  final String abbreviation;
}
