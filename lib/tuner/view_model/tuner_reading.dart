import 'package:musbx/data/models/audio_frame.dart';
import 'package:musbx/model/pitch.dart';

class TunerReading {
  /// Data recorded from the microphone at a given [time].
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
