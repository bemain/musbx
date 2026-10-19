import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

void main() {
  group("Chord.tryParse", () {
    test("reads root, quality, extension, alterations and bass", () {
      expect(
        Chord.tryParse("C"),
        const Chord(PitchClass.c(), ChordQuality.major),
      );
      expect(
        Chord.tryParse("Am"),
        const Chord(PitchClass.a(), ChordQuality.minor),
      );
      expect(
        Chord.tryParse("F#m7"),
        const Chord(
          PitchClass.fSharp(),
          ChordQuality.minor,
          extension: ChordExtension.minorSeventh,
        ),
      );
      expect(
        Chord.tryParse("Bbmaj7"),
        const Chord(
          PitchClass.bFlat(),
          ChordQuality.major,
          extension: ChordExtension.majorSeventh,
        ),
      );
      expect(
        Chord.tryParse("Cm7b5"),
        const Chord(
          PitchClass.c(),
          ChordQuality.minor,
          extension: ChordExtension.minorSeventh,
          alterations: "♭5",
        ),
      );
      expect(
        Chord.tryParse("C/G"),
        const Chord(
          PitchClass.c(),
          ChordQuality.major,
          bassNote: PitchClass.g(),
        ),
      );
      expect(
        Chord.tryParse("Gdim")?.quality,
        ChordQuality.diminshed,
      );
      expect(
        Chord.tryParse("Eaug")?.quality,
        ChordQuality.augmented,
      );
    });

    test("returns null for non-chords", () {
      expect(Chord.tryParse("N"), isNull);
      expect(Chord.tryParse(""), isNull);
      expect(() => Chord.parse("H7"), throwsFormatException);
    });
  });

  test("ChordExtension.tryParse", () {
    expect(ChordExtension.tryParse("7"), ChordExtension.minorSeventh);
    expect(ChordExtension.tryParse("Δ"), ChordExtension.majorSeventh);
    expect(ChordExtension.tryParse("maj"), ChordExtension.majorSeventh);
    expect(ChordExtension.tryParse("Δ13"), ChordExtension.majorThirteenth);
    expect(ChordExtension.tryParse("6"), ChordExtension.sixth);
    expect(ChordExtension.tryParse("5"), isNull);
  });

  test("toString writes the normalized chord symbol", () {
    final cases = {
      "C": "C",
      "F#m7": "F♯m7",
      "Bbmaj7": "B♭Δ",
      "Cmaj9": "CΔ9",
      "Cm7b5": "Cm7♭5",
      "C/G": "C/G",
    };
    cases.forEach((input, expected) {
      expect(Chord.parse(input).toString(), expected, reason: input);
    });
  });

  test("transposed moves the root and bass together", () {
    expect(Chord.parse("Am7").transposed(2), Chord.parse("Bm7"));
    expect(Chord.parse("C/G").transposed(2), Chord.parse("D/A"));
  });
}
