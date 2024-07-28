import 'dart:math';

import 'package:flutter/cupertino.dart';

@immutable
abstract class Temperament {
  /// Representation of a musical temperament, determining what frequencies notes are placed at.
  const Temperament();

  /// The ratio of the frequency between the note at [scaleStep] and the root of the scale.
  /// Multiply with the frequency of the root to get the note's frequency.
  double frequencyRatio(int scaleStep);

  /// The number of scale steps that fits within the given [frequencyRatio].
  /// Pass a frequency divided by the frequency of the root note to get the note's degree.
  int scaleStep(double frequencyRatio);
}

class EqualTemperament extends Temperament {
  const EqualTemperament();

  @override
  double frequencyRatio(int scaleStep) =>
      pow(pow(2, 1 / 12), scaleStep).toDouble();

  @override
  int scaleStep(double frequencyRatio) =>
      (12 * log(frequencyRatio) / log(2)).round();
}

class PythagoreanTuning extends Temperament {
  const PythagoreanTuning();

  /// The list of ratios used to determine the frequencies for the notes.
  static const List<double> _ratios = [
    1,
    256 / 243,
    9 / 8,
    32 / 27,
    81 / 64,
    4 / 3,
    1024 / 729,
    3 / 2,
    128 / 81,
    27 / 16,
    16 / 9,
    243 / 128,
  ];

  @override
  double frequencyRatio(int scaleStep) =>
      pow(2, (scaleStep / 12).floor()) * _ratios[(scaleStep % 12)];

  @override
  int scaleStep(double frequencyRatio) {
    final int octave = (log(frequencyRatio) / log(2)).floor();
    final double targetRatio = frequencyRatio / pow(2, octave);

    double closestRatio = _ratios.first;
    for (final double ratio in _ratios) {
      if ((targetRatio - ratio).abs() < (targetRatio - closestRatio)) {
        closestRatio = ratio;
      }
    }
    return octave * 12 + _ratios.indexOf(closestRatio);
  }
}
