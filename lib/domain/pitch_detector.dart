import 'dart:math';
import 'dart:typed_data';

import 'package:musbx/domain/yin.dart';
import 'package:musbx/utils/num_iterable_extension.dart';

/// Detects the pitch in a stream of audio buffers, smoothing over the last few
/// readings.
class PitchDetector {
  PitchDetector({this.sampleRate = 22050, this.averageCount = 3});

  /// The sample rate of the audio handed to [add], in Hz.
  final int sampleRate;

  /// How many recent readings are averaged into the reported frequency.
  final int averageCount;

  final List<double?> _recent = [];

  /// Detect the pitch in [data] and remember it for smoothing later readings.
  ///
  /// Returns the mean of the recent readings close to this one, or `null` if
  /// no pitch was detected.
  double? add(Float32List data) {
    final double? detected = Yin(
      sampleRate.toDouble(),
      // We need to use a small buffer size so the operation completes before the next data arrives
      // TODO: Maybe use a different method
      min(1024, data.length),
    ).getPitch(data)?.frequency;

    _recent.add(detected);
    if (_recent.length > averageCount) {
      _recent.removeRange(0, _recent.length - averageCount);
    }

    if (detected == null) return null;

    Iterable<double> frequencies = _recent.nonNulls
        // Only frequencies close to the current
        .where((frequency) => (frequency - detected).abs() < 10);

    if (frequencies.isEmpty) return null;

    return frequencies.mean;
  }
}
