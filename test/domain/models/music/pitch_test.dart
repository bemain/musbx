import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';
import 'package:musbx/domain/models/music/temperament.dart';

void main() {
  group("Pitch.closest", () {
    test("names the nearest pitch but keeps the measured frequency", () {
      final pitch = Pitch.closest(445);
      expect(pitch.abbreviation, "A4");
      expect(pitch.frequency, 445);
    });

    test("crosses octaves at C", () {
      expect(Pitch.closest(261.63).abbreviation, "C4");
      expect(Pitch.closest(246.94).abbreviation, "B3");
      expect(Pitch.closest(523.25).abbreviation, "C5");
      expect(Pitch.closest(110).abbreviation, "A2");
    });

    test("respects the preferred accidental", () {
      expect(Pitch.closest(466.16).abbreviation, "A♯4");
      expect(
        Pitch.closest(
          466.16,
          preferredAccidental: Accidental.flat,
        ).abbreviation,
        "B♭4",
      );
    });

    test("measures against a custom tuning", () {
      const a432 = Pitch(PitchClass.a(), 4, 432);
      expect(Pitch.closest(432, tuning: a432).abbreviation, "A4");
      expect(Pitch.closest(440, tuning: a432).abbreviation, "A4");
      expect(Pitch.closest(457.7, tuning: a432).abbreviation, "A♯4");
    });

    test("works with Pythagorean tuning", () {
      expect(
        Pitch.closest(
          660,
          temperament: const PythagoreanTuning(),
        ).abbreviation,
        "E5",
      );
    });
  });

  test("offsetFrom is in cents", () {
    const a4 = Pitch.a440();
    expect(a4.offsetFrom(440), 0);
    expect(a4.offsetFrom(220), closeTo(1200, 1e-9));
    expect(a4.offsetFrom(880), closeTo(-1200, 1e-9));
    expect(a4.offsetFrom(466.1638), closeTo(-100, 0.01));
  });

  group("transposed", () {
    test("moves pitch class, octave and frequency", () {
      final up = const Pitch.a440().transposed(12);
      expect(up.abbreviation, "A5");
      expect(up.frequency, closeTo(880, 1e-9));

      final down = const Pitch.a440().transposed(-9);
      expect(down.abbreviation, "C4");
      expect(down.frequency, closeTo(261.626, 0.001));
    });

    test("uses the temperament's ratios", () {
      final fifth = const Pitch.a440().transposed(
        7,
        temperament: const PythagoreanTuning(),
      );
      expect(fifth.abbreviation, "E5");
      expect(fifth.frequency, 660);
    });
  });

  test("semitonesTo counts across octaves", () {
    final a4 = const Pitch.a440();
    final c5 = Pitch.parse("C5@523.25Hz");
    expect(a4.semitonesTo(c5), 3);
    expect(c5.semitonesTo(a4), -3);
  });

  group("parse", () {
    test("round-trips toString", () {
      for (final pitch in [
        const Pitch.a440(),
        const Pitch(PitchClass.bFlat(), 3, 233.08),
      ]) {
        expect(Pitch.parse(pitch.toString()), pitch);
      }
    });

    test("accepts ASCII accidentals and a missing unit", () {
      expect(
        Pitch.tryParse("A#4@466"),
        const Pitch(PitchClass.aSharp(), 4, 466),
      );
    });

    test("rejects strings without a frequency", () {
      expect(Pitch.tryParse("A4"), isNull);
      expect(() => Pitch.parse("H4@440Hz"), throwsFormatException);
    });
  });
}
