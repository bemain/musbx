import 'dart:math';

import 'package:flutter/cupertino.dart';

@immutable
abstract class Temperament {
  /// Representation of a musical temperament, determining what frequencies notes are placed at.
  const Temperament();

  /// The ratio between the note at [scaleStep] and the root of the scale.
  /// Multiply with the frequency of the root to get the frequency.
  double frequencyRatio(int scaleStep) =>
      throw UnimplementedError("No implementation for frequencyForNote()");
}

class EqualTemperament extends Temperament {
  const EqualTemperament();

  @override
  double frequencyRatio(int scaleStep) =>
      pow(pow(2, 1 / 12), scaleStep).toDouble();
}
