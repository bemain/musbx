import 'package:musbx/domain/models/audio_frame.dart';
import 'package:musbx/domain/models/music/pitch.dart';

/// Data recorded from the microphone at a given [time].
class TunerReading {
  TunerReading({
    DateTime? time,
    required this.frame,
    required this.pitch,
  }) : time = time ?? DateTime.now();

  /// When this data was recorded.
  final DateTime time;

  /// Waveform data.
  final AudioFrame frame;

  /// The pitch detected, if any.
  final Pitch? pitch;
}
