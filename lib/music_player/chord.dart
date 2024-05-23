enum ChordQuality {
  major(""),
  minor("m"),
  augmented("aug"),
  diminshed("dim"),
  halfDiminished("ø");

  const ChordQuality(this.abbreviation);

  final String abbreviation;
}

class Chord {
  const Chord(
    this.root,
    this.quality, {
    this.extension,
    this.alterations,
    String? bassNote,
  }) : bassNote = bassNote ?? root;

  final String root;

  final ChordQuality quality;

  final String? extension;

  final String? alterations;

  final String bassNote;

  static Chord? tryParse(String string) {
    RegExp regExp = RegExp(r"([A-G][#♯b♭]?)" // Root
        r"(m(?!aj)|dim|aug)?" // Quality
        r"((maj|Δ)?\d*)?" // Extension
        r"(sus\d*)?" // Sus
        r"((([#♯b♭]|add)\d+)*)?" // Alterations
        r"\/?([A-G])?$" // Bass note
        );
    var matches = regExp.allMatches(string);
    if (matches.isEmpty) return null;
    RegExpMatch match = matches.elementAt(0);
    if (match.groupCount < 2) return null;

    final String root = match.group(1)!;
    final String? quality = match.group(2);
    final String? extension = match.group(3);
    // final String? suspension = match.group(5);
    final String? alterations = match.group(6);
    final String? bassNote = match.group(9);

    final matchedQualities = ChordQuality.values.where(
      (element) => element.name == quality,
    );

    return Chord(
      root,
      matchedQualities.isNotEmpty ? matchedQualities.first : ChordQuality.major,
      extension: extension,
      alterations: alterations,
      bassNote: bassNote,
    );
  }

  @override
  String toString() {
    return "$root${quality.abbreviation}"
        "${extension ?? ""}"
        "${alterations ?? ""}"
        "${bassNote != root ? "/$bassNote" : ""}";
  }
}
