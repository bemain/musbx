import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/chroma.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

void main() {
  group("PitchClass.fromChroma", () {
    test("spells natural chromas without an accidental", () {
      for (final accidental in Accidental.values) {
        expect(
          PitchClass.fromChroma(Chroma.f, preferredAccidental: accidental),
          const PitchClass.f(),
        );
        expect(
          PitchClass.fromChroma(Chroma.e, preferredAccidental: accidental),
          const PitchClass.e(),
        );
      }
    });

    test("uses the preferred accidental for non-natural chromas", () {
      expect(
        PitchClass.fromChroma(
          Chroma.fSharp,
          preferredAccidental: Accidental.flat,
        ),
        const PitchClass.gFlat(),
      );
      expect(
        PitchClass.fromChroma(
          Chroma.aSharp,
          preferredAccidental: Accidental.sharp,
        ),
        const PitchClass.aSharp(),
      );
    });

    test("falls back to the most common spelling", () {
      expect(PitchClass.fromChroma(Chroma.cSharp), const PitchClass.dFlat());
      expect(PitchClass.fromChroma(Chroma.fSharp), const PitchClass.fSharp());
      expect(
        PitchClass.fromChroma(
          Chroma.gSharp,
          preferredAccidental: Accidental.natural,
        ),
        const PitchClass.aFlat(),
      );
    });
  });

  group("PitchClass.tryParse", () {
    test("parses letters with ASCII or Unicode accidentals", () {
      expect(PitchClass.tryParse("C"), const PitchClass.c());
      expect(PitchClass.tryParse("F#"), const PitchClass.fSharp());
      expect(PitchClass.tryParse("F♯"), const PitchClass.fSharp());
      expect(PitchClass.tryParse("Bb"), const PitchClass.bFlat());
      expect(PitchClass.tryParse("B♭"), const PitchClass.bFlat());
    });

    test("rejects anything that is not a note name", () {
      expect(PitchClass.tryParse("H"), isNull);
      expect(PitchClass.tryParse("c"), isNull);
      expect(() => PitchClass.parse("X"), throwsFormatException);
    });
  });

  test("enharmonic pitch classes share a chroma but are not equal", () {
    expect(const PitchClass.fSharp().chroma, Chroma.fSharp);
    expect(const PitchClass.gFlat().chroma, Chroma.fSharp);
    expect(const PitchClass.fSharp(), isNot(const PitchClass.gFlat()));
    expect(
      const PitchClass(NaturalPitchClass.b, Accidental.sharp).chroma,
      Chroma.c,
    );
  });

  test("abbreviation omits the natural sign", () {
    expect(const PitchClass.c().abbreviation, "C");
    expect(const PitchClass.fSharp().abbreviation, "F♯");
    expect(const PitchClass.bFlat().abbreviation, "B♭");
  });

  group("transposed", () {
    test("spells the result like the major key on the original", () {
      expect(const PitchClass.c().transposed(7), const PitchClass.g());
      expect(const PitchClass.f().transposed(5), const PitchClass.bFlat());
      expect(const PitchClass.g().transposed(6), const PitchClass.cSharp());
      expect(const PitchClass.e().transposed(-1), const PitchClass.dSharp());
    });

    test("wraps around the octave", () {
      expect(const PitchClass.b().transposed(1), const PitchClass.c());
      expect(const PitchClass.c().transposed(-1), const PitchClass.b());
      expect(const PitchClass.d().transposed(24), const PitchClass.d());
    });

    test("uses an explicitly preferred accidental", () {
      expect(
        const PitchClass.c().transposed(
          1,
          preferredAccidental: Accidental.flat,
        ),
        const PitchClass.dFlat(),
      );
    });
  });
}
