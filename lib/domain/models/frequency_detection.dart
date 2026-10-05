import 'package:musbx/domain/models/audio_frame.dart';

/// Frequency detected from the microphone at a given [time].
class FrequencyDetection {
  FrequencyDetection({
    DateTime? time,
    required this.frame,
    required this.frequency,
  }) : time = time ?? DateTime.now();

  /// When this data was recorded.
  final DateTime time;

  /// Waveform data.
  final AudioFrame frame;

  /// The pitch detected, if any.
  final double? frequency;
}
