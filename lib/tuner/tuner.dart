import 'dart:io';

import 'package:musbx/data/services/audio_capture_service.dart';
import 'package:musbx/domain/models/frequency_detection.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/pitch_detector.dart';

/// Listens to the microphone and reports what pitch is being played.
///
/// [dataStream] is where the work happens: each frame from the microphone is
/// run through pitch detection, matched to the closest [Pitch] under the
/// current [tuning] and [temperament], and kept in [dataBuffer] for the graphs
/// to draw. Nothing is recorded until something listens.
class TunerRepository {
  TunerRepository({required AudioCaptureService audioCapture})
    : _audioCapture = audioCapture,
      _pitchDetector = PitchDetector(sampleRate: audioCapture.sampleRate);

  /// How many cents off a frequency can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The number of previous data entries buffered.
  static const int bufferLength = 32;

  final AudioCaptureService _audioCapture;
  late final PitchDetector _pitchDetector;

  /// Whether permission to access the microphone has been given.
  ///
  /// The `permission_handler` package has no implementation for Linux or
  /// macOS, so requesting permission there would never complete. On macOS
  /// access is instead granted by the `com.apple.security.device.audio-input`
  /// entitlement, which the system prompts for on first use.
  bool hasPermission = Platform.isLinux || Platform.isMacOS;

  /// The recent data recorded from the [dataStream]. [bufferLength] data entries are kept.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  final List<FrequencyDetection> dataBuffer = [];

  /// The realtime data recorded from the microphone.
  Stream<FrequencyDetection> get dataStream =>
      _audioCapture.dataStream.map((frame) {
        final freq = _pitchDetector.add(frame.data);

        final reading = FrequencyDetection(
          frame: frame,
          frequency: freq,
        );
        latestReading = reading;

        // Add to buffer
        dataBuffer.add(reading);
        if (dataBuffer.length > bufferLength) {
          dataBuffer.removeRange(0, dataBuffer.length - bufferLength);
        }

        return reading;
      });

  /// The most recent pitch detected, or `null` until one has been.
  FrequencyDetection? latestReading;
}
