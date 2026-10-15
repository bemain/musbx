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

  /// The audio the frequency was detected in.
  final AudioFrame frame;

  /// The frequency detected, in Hz, or `null` if none could be.
  final double? frequency;
}
