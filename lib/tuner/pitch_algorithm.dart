import 'dart:async';
import 'dart:typed_data';

class PitchDetectorResult {
  const PitchDetectorResult({
    required this.frequency,
    required this.confidence,
  });

  final double frequency;
  final double confidence;
}

/// Defines a contract on how a pitch can be obtained
abstract class PitchAlgorithm {
  FutureOr<PitchDetectorResult?> getPitch(final Float32List audioBuffer);
}
