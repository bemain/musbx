import 'dart:math';

import 'package:flutter/cupertino.dart';

@immutable
abstract class Temperament {
  /// Representation of a musical temperament, determining what frequencies notes are placed at.
  const Temperament();

  /// The ratio between the note at [scaleStep] and the root of the scale.
  /// Multiply with the frequency of the root to get the frequency.
  double frequencyRatio(int scaleStep);
}

class EqualTemperament extends Temperament {
  const EqualTemperament();

  @override
  double frequencyRatio(int scaleStep) =>
      pow(pow(2, 1 / 12), scaleStep).toDouble();
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
  double frequencyRatio(int scaleStep) {
    return (scaleStep ~/ 12 + 1) * _ratios[(scaleStep % 12)];
  }
}
