import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/pitch_algorithm.dart';
import 'package:musbx/domain/pitch_detector.dart';
import 'package:musbx/domain/yin.dart';

import '../helpers/fixtures.dart';

void main() {
  const sampleRate = 22050;
  final silence = Float32List(2048);

  group("Yin", () {
    test("detects the frequency of a sine wave", () {
      for (final frequency in [82.41, 220.0, 440.0, 987.77]) {
        final result = Yin(sampleRate.toDouble(), 2048).getPitch(
          sine(frequency),
        );
        expect(result?.frequency, closeTo(frequency, 1), reason: "$frequency");
        expect(result?.confidence, greaterThan(0.9));
      }
    });

    test("finds no pitch in silence", () {
      expect(Yin(sampleRate.toDouble(), 2048).getPitch(silence), isNull);
    });
  });

  group("BasicPitchAlgorithm", () {
    final algorithm = BasicPitchAlgorithm(sampleRate: sampleRate);

    test("detects the frequency of a sine wave", () async {
      final result = await algorithm.getPitch(sine(440));
      expect(result?.frequency, closeTo(440, 5));
    });

    test("finds no pitch in silence", () async {
      expect(await algorithm.getPitch(silence), isNull);
    });
  });

  group("PitchDetector", () {
    late PitchDetector detector;
    setUp(() => detector = PitchDetector(sampleRate: sampleRate));

    test("averages recent readings close to the current one", () {
      detector.add(sine(440));
      expect(detector.add(sine(446)), closeTo(443, 1));
    });

    test("ignores recent readings far from the current one", () {
      detector.add(sine(440));
      expect(detector.add(sine(660)), closeTo(660, 1));
    });

    test("forgets readings older than averageCount", () {
      detector.add(sine(440));
      for (var i = 0; i < detector.averageCount; i++) {
        detector.add(sine(446));
      }
      expect(detector.add(sine(446)), closeTo(446, 1));
    });

    test("reports null for silence", () {
      detector.add(sine(440));
      expect(detector.add(silence), isNull);
    });
  });
}
