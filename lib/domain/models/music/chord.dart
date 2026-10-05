import 'package:musbx/domain/models/music/pitch_class.dart';

/// The triad a chord is built on, which decides whether it sounds major,
/// minor, augmented or diminished.
enum ChordQuality {
  major(""),
  minor("m"),
  augmented("aug"),
  diminshed("dim"),
  halfDiminished("ø");

  const ChordQuality(this.abbreviation);

  /// What is written after the root note, e.g. "m". Empty for [major].
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

/// A note stacked on top of a chord's triad, named by the scale degree it sits
/// at.
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

  /// What is written after the quality, e.g. "7" or "Δ13".
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

/// A group of notes sounding together, named by its [root] and the intervals
/// stacked above it.
class Chord {
  const Chord(
    this.root,
    this.quality, {
    this.extension,
    this.alterations,
    PitchClass? bassNote,
  }) : bassNote = bassNote ?? root;

  /// The root note of this chord, e.g. C or G♭
  final PitchClass root;

  /// The triad this chord is built on.
  final ChordQuality quality;

  /// The note stacked on top of the triad, if any.
  final ChordExtension? extension;

  /// Any further alterations, written as they appear in the chord symbol,
  /// e.g. "♭5add9".
  final String? alterations;

  /// The lowest note. Equal to [root] unless the chord is inverted or has a
  /// slash bass.
  final PitchClass bassNote;

  /// Parse [string] as a chord.
  /// Returns `null` if [string] is not a valid chord.
  static Chord? tryParse(String string) {
    RegExp regExp = RegExp(
      r"([A-G][#♯b♭]?)" // Root
      r"(m(?!aj)|dim|aug)?" // Quality
      r"((maj|Δ)?\d*)?" // Extension
      r"(sus\d*)?" // Sus
      r"((([#♯b♭]|add)\d+)*)?" // Alterations
      r"\/?([A-G])?$", // Bass note
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

  /// Parse [string] as a chord.
  /// Throws a [FormatException] if [string] is not a valid chord.
  static Chord parse(String string) {
    Chord? chord = tryParse(string);
    if (chord == null) {
      throw FormatException("Unable to parse string as a Chord: $string");
    }
    return chord;
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

  @override
  bool operator ==(Object other) =>
      other is Chord &&
      root == other.root &&
      quality == other.quality &&
      extension == other.extension &&
      alterations == other.alterations &&
      bassNote == other.bassNote;

  @override
  int get hashCode =>
      Object.hash(root, quality, extension, alterations, bassNote);
}
