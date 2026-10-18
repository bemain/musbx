import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/temperament.dart';

void main() {
  group("EqualTemperament", () {
    const temperament = EqualTemperament();

    test("frequencyRatio", () {
      expect(temperament.frequencyRatio(0), 1);
      expect(temperament.frequencyRatio(12), closeTo(2, 1e-9));
      expect(temperament.frequencyRatio(-12), closeTo(0.5, 1e-9));
      expect(temperament.frequencyRatio(7), closeTo(1.498307, 1e-6));
    });

    test("scaleStep rounds to the nearest semitone", () {
      expect(temperament.scaleStep(2), 12);
      expect(temperament.scaleStep(1.5), 7);
      expect(temperament.scaleStep(0.5), -12);
      expect(temperament.scaleStep(1.99), 12);
      expect(temperament.scaleStep(0.995), 0);
    });
  });

  group("PythagoreanTuning", () {
    const temperament = PythagoreanTuning();

    test("frequencyRatio stacks pure ratios across octaves", () {
      expect(temperament.frequencyRatio(7), 1.5);
      expect(temperament.frequencyRatio(4), 81 / 64);
      expect(temperament.frequencyRatio(19), 3);
      expect(temperament.frequencyRatio(-5), 0.75);
    });

    test("scaleStep inverts frequencyRatio", () {
      for (var step = -24; step <= 24; step++) {
        expect(
          temperament.scaleStep(temperament.frequencyRatio(step)),
          step,
          reason: "step $step",
        );
      }
    });

    test("scaleStep rounds up to the next octave when slightly flat", () {
      expect(temperament.scaleStep(1.99), 12);
      expect(temperament.scaleStep(0.995), 0);
    });
  });
}
