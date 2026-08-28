import 'dart:math';
import 'dart:typed_data';

import 'package:musbx/domain/use_case/yin.dart';
import 'package:musbx/utils/num_iterable_extension.dart';

/// Detect a pitch in audio data.
class PitchDetector {
  PitchDetector({this.sampleRate = 22050, this.averageCount = 3});

  final int sampleRate;

  final int averageCount;

  final List<double?> _recent = [];

  /// Use pitch detection to try and detect a pitch in the given [data], and feed the buffer.
  ///
  /// Returns a smoothed frequency, or `null` if not confident.
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
