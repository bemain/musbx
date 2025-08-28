import 'dart:typed_data';

import 'package:musbx/tuner/pitch_algorithm.dart';

/// An implementation of the AUBIO_YIN pitch tracking algorithm.
/// This is a port of the TarsosDSP library developed by Joren Six and Paul Brossier at IPEM, University Ghent
/// Original implementation : https://github.com/JorenSix/TarsosDSP
///
/// Ported by Techpotatoes - Lucas Bento
class Yin extends PitchAlgorithm {
  /// The default YIN threshold value. Should be around 0.10~0.15. See YIN
  /// paper for more information.
  static final double defaultThreshold = 0.20;

  /// The default size of an audio buffer (in samples).
  static final int defaultBufferSize = 2048;

  /// The default overlap of two consecutive audio buffers (in samples).
  static final int defaultOverlap = 1536;

  final double _threshold;
  final double _sampleRate;
  final Float32List _yinBuffer;

  Yin(double audioSampleRate, int bufferSize)
    : _sampleRate = audioSampleRate,
      _threshold = defaultThreshold,
      _yinBuffer = Float32List(bufferSize ~/ 2);

  @override
  PitchDetectorResult? getPitch(final Float32List audioBuffer) {
    final double pitchInHertz;

    // step 2
    _difference(audioBuffer);

    // step 3
    _cumulativeMeanNormalizedDifference();

    // step 4
    final pitched = _absoluteThreshold();

    // step 5
    if (pitched.tau != -1) {
      final double betterTau = _parabolicInterpolation(pitched.tau);

      // step 6
      // TODO Implement optimization for the AUBIO_YIN algorithm.
      // 0.77% => 0.5% error rate,
      // using the data of the YIN paper
      // bestLocalEstimate()

      // conversion to Hz
      pitchInHertz = _sampleRate / betterTau;
    } else {
      // no pitch found
      pitchInHertz = -1;
    }

    if (!pitched.pitched) return null;

    return PitchDetectorResult(
      frequency: pitchInHertz,
      confidence: pitched.probability,
    );
  }

  /// Implements the difference function as described in step 2 of the YIN
  void _difference(final List<double> audioBuffer) {
    final int bufferLength = _yinBuffer.length;

    // Clear buffer
    _yinBuffer.fillRange(0, bufferLength, 0.0);

    for (int tau = 1; tau < bufferLength; tau++) {
      double sum = 0.0;
      for (int i = 0; i < bufferLength; i++) {
        final double delta = audioBuffer[i] - audioBuffer[i + tau];
        sum += delta * delta;
      }

      _yinBuffer[tau] = sum;
    }
  }

  /// The cumulative mean normalized difference function as described in step 3 of the YIN paper.
  void _cumulativeMeanNormalizedDifference() {
    _yinBuffer[0] = 1;
    double runningSum = 0;
    for (int tau = 1; tau < _yinBuffer.length; tau++) {
      runningSum += _yinBuffer[tau];
      _yinBuffer[tau] *= tau / runningSum;
    }
  }

  /// Implements step 4 of the AUBIO_YIN paper.
  Pitched _absoluteThreshold() {
    int tau = -1;
    double probability = 0.0;
    bool pitched = false;

    final int bufferLength = _yinBuffer.length;

    // Start at index 2 as first two positions are always 1
    for (int i = 2; i < bufferLength; i++) {
      if (_yinBuffer[i] < _threshold) {
        tau = i;

        // Find local minimum
        while (tau + 1 < bufferLength &&
            _yinBuffer[tau + 1] < _yinBuffer[tau]) {
          tau++;
        }

        // Calculate probability (periodicity = 1 - aperiodicity)
        probability = 1.0 - _yinBuffer[tau];
        pitched = true;
        break;
      }
    }

    return Pitched(tau, probability, pitched);
  }

  /// Implements step 5 of the AUBIO_YIN paper. It refines the estimated tau
  /// value using parabolic interpolation. This is needed to detect higher
  /// frequencies more precisely. See http://fizyka.umk.pl/nrbook/c10-2.pdf and
  /// for more background
  /// http://fedc.wiwi.hu-berlin.de/xplore/tutorials/xegbohtmlnode62.html
  double _parabolicInterpolation(final int tauEstimate) {
    final int bufferLength = _yinBuffer.length;

    // Determine bounds for parabolic interpolation
    final int x0 = (tauEstimate < 1) ? tauEstimate : tauEstimate - 1;
    final int x2 = (tauEstimate + 1 < bufferLength)
        ? tauEstimate + 1
        : tauEstimate;

    // Handle edge cases
    if (x0 == tauEstimate) {
      return (_yinBuffer[tauEstimate] <= _yinBuffer[x2])
          ? tauEstimate.toDouble()
          : x2.toDouble();
    }

    if (x2 == tauEstimate) {
      return (_yinBuffer[tauEstimate] <= _yinBuffer[x0])
          ? tauEstimate.toDouble()
          : x0.toDouble();
    }

    // Parabolic interpolation
    final double s0 = _yinBuffer[x0];
    final double s1 = _yinBuffer[tauEstimate];
    final double s2 = _yinBuffer[x2];

    final double denominator = 2.0 * (2.0 * s1 - s2 - s0);

    // Avoid division by zero
    if (denominator.abs() < 1e-10) {
      return tauEstimate.toDouble();
    }

    return tauEstimate + (s2 - s0) / denominator;
  }
}

class Pitched {
  final int tau;
  final double probability;
  final bool pitched;

  Pitched(this.tau, this.probability, this.pitched);
}
