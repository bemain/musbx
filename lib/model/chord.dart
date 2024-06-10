import 'package:musbx/model/pitch_class.dart';

enum ChordQuality {
  major(""),
  minor("m"),
  augmented("aug"),
  diminshed("dim"),
  halfDiminished("ø");

  const ChordQuality(this.abbreviation);

  final String abbreviation;

  /// Parse [string] as a chord quality.
  /// Returns `null` if [string] is not a valid chord quality.
  static ChordQuality? tryParse(String string) {
    return ChordQuality.values
        .where((element) => element.abbreviation == string)
        .firstOrNull;
  }

  @override
  String toString() => abbreviation;
}

enum ChordExtension {
  sixth(6),

  minorSeventh(7),
  majorSeventh(7, true),

  minorNinth(9),
  majorNinth(9, true),

  minorEleventh(11),
  majorEleventh(11, true),

  minorThirteenth(13),
  majorThirteenth(13, true);

  const ChordExtension(this.degree, [this.isMajor = false]);

  /// The degree of the extension, e.g. 7 or 13.
  final int degree;

  /// Whether the seventh (if any) is a major seventh.
  final bool isMajor;

  String get abbreviation =>
      (isMajor && degree == 7) ? "Δ" : "${isMajor ? "Δ" : ""}$degree";

  /// Parse [string] as a chord extension.
  /// Returns `null` if [string] is not a valid chord extension.
  static ChordExtension? tryParse(String string) {
    final bool isMajor = string.contains(RegExp("Δ|maj"));
    int? degree = int.tryParse(string.replaceAll(RegExp(r'[^0-9]'), ''));
    if ((degree == null || degree < 3) && isMajor) degree = 7;

    return ChordExtension.values
        .where(
          (element) => element.degree == degree && element.isMajor == isMajor,
        )
        .firstOrNull;
  }

  @override
  String toString() => abbreviation;
}

class Chord {
  /// Representation of a musical chord.
  const Chord(
    this.root,
    this.quality, {
    this.extension,
    this.alterations,
    PitchClass? bassNote,
  }) : bassNote = bassNote ?? root;

  /// The root note of this chord, e.g. C or G♭
  final PitchClass root;

  final ChordQuality quality;

  final ChordExtension? extension;

  final String? alterations;

  final PitchClass bassNote;

  /// Parse [string] as a chord.
  /// Returns `null` if [string] is not a valid chord.
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

    final PitchClass? root = PitchClass.tryParse(match.group(1)!);
    if (root == null) return null;

    final String? quality = match.group(2);
    final String? extension = match.group(3);
    // final String? suspension = match.group(5);
    final String? alterations = match.group(6);
    final String? bassName = match.group(9);

    return Chord(
      root,
      (quality == null ? null : ChordQuality.tryParse(quality)) ??
          ChordQuality.major,
      extension: extension == null ? null : ChordExtension.tryParse(extension),
      alterations: alterations?.replaceAll("b", "♭").replaceAll("#", "♯"),
      bassNote: bassName == null ? null : PitchClass.tryParse(bassName),
    );
  }

  /// Transpose this chord a number of semitones.
  Chord transposed(int semitones) {
    return Chord(
      root.transposed(semitones),
      quality,
      extension: extension,
      alterations: alterations,
      bassNote: bassNote.transposed(semitones),
    );
  }

  @override
  String toString() {
    return "$root$quality"
        "${extension ?? ""}"
        "${alterations ?? ""}"
        "${bassNote != root ? "/$bassNote" : ""}";
  }
}
