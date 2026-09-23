import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// A pitch found in a buffer of audio.
class PitchDetectorResult {
  const PitchDetectorResult({
    required this.frequency,
    required this.confidence,
  });

  /// The detected frequency, in Hz.
  final double frequency;

  /// How sure the algorithm is of [frequency], between `0.0` and `1.0`.
  final double confidence;
}

/// Defines a contract on how a pitch can be obtained
/// Detect a pitch from audio data.
abstract class PitchAlgorithm {
  FutureOr<PitchDetectorResult?> getPitch(final Float32List audioBuffer);
}

/// Pitch detection by autocorrelation over the C1–C7 range.
///
/// Cheaper and less accurate than [Yin], and weighted slightly against low
/// frequencies to avoid reporting an octave too low.
class BasicPitchAlgorithm extends PitchAlgorithm {
  BasicPitchAlgorithm({required this.sampleRate});

  final int sampleRate;

  @override
  Future<PitchDetectorResult?> getPitch(Float32List buffer) async {
    final int lower = sampleRate ~/ 2093; // 2093 Hz C7
    final int upper = sampleRate ~/ 32.7032; // 32.7032 Hz C1
    final int samples = buffer.length - upper;
    int bestOffset = -1;
    double bestCorrelation = 0.0;
    double rms = 0.0;

    if (buffer.length < (samples + upper - lower)) {
      return null; // Not enough data
    }

    for (int i = 0; i < samples; i++) {
      final double val = buffer[i];
      rms += val * val;
    }
    rms = sqrt(rms / samples);

    for (int offset = lower; offset < upper; offset++) {
      double correlation = 0.0;

      for (int i = 0; i < samples; i++) {
        correlation += (buffer[i] - buffer[i + offset]).abs();
      }
      correlation = 1 - (correlation / samples);
      //weight slightly against lower freq to avoid octave erros
      correlation =
          correlation * .9 + (upper - offset) / (upper - lower) / 185;
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestOffset = offset;
      }
    }

    if (rms > .009 && bestCorrelation > 0.5) {
      return PitchDetectorResult(
        frequency: sampleRate / bestOffset,
        confidence: bestCorrelation * rms * 10000,
      );
    }
    return null;
  }
}
