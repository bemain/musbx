enum Accidental {
  natural("♮", 0),
  sharp("♯", 1),
  flat("♭", -1);

  /// A symbol that indicates an alteration of a given pitch.
  const Accidental(this.abbreviation, this.alteration);

  /// The number of semitones that this alters the given pitch.
  final int alteration;

  final String abbreviation;
}
