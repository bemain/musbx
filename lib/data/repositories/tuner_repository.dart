import 'dart:async';
import 'dart:io';

import 'package:musbx/config/service_loader.dart';
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
  TunerRepository({required ServiceLoader<AudioCaptureService> audioCapture})
    : _audioCapture = audioCapture;

  /// How many cents off a frequency can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The number of previous data entries buffered.
  static const int bufferLength = 32;

  final ServiceLoader<AudioCaptureService> _audioCapture;

  /// Whether permission to access the microphone has been given.
  ///
  /// The `permission_handler` package has no implementation for Linux or
  /// macOS, so requesting permission there would never complete. On macOS
  /// access is instead granted by the `com.apple.security.device.audio-input`
  /// entitlement, which the system prompts for on first use.
  /// TODO: Move to ViewModel
  bool hasPermission = Platform.isLinux || Platform.isMacOS;

  /// The recent data recorded from the [dataStream]. [bufferLength] data entries are kept.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  final List<FrequencyDetection> dataBuffer = [];

  /// The realtime data recorded from the microphone.
  ///
  /// Shared between listeners, so each frame is detected and buffered once no
  /// matter how many widgets draw it.
  Stream<FrequencyDetection> get dataStream => _controller.stream;

  StreamSubscription<FrequencyDetection>? _subscription;

  /// Attaches to the microphone only while something listens. Each attach
  /// reads the current service, so one created after this repository is used.
  late final StreamController<FrequencyDetection> _controller =
      StreamController<FrequencyDetection>.broadcast(
        onListen: () {
          _subscription = _detect(_audioCapture.value).listen(
            _controller.add,
            onError: _controller.addError,
          );
        },
        onCancel: () async {
          await _subscription?.cancel();
          _subscription = null;
        },
      );

  /// A generator so that [ServiceDisabled] reaches listeners as a stream error
  /// rather than escaping from [StreamController.onListen].
  Stream<FrequencyDetection> _detect(AudioCaptureService audioCapture) async* {
    final pitchDetector = PitchDetector(sampleRate: audioCapture.sampleRate);
    await for (final frame in audioCapture.dataStream) {
      final reading = FrequencyDetection(
        frame: frame,
        frequency: pitchDetector.add(frame.data),
      );
      latestReading = reading;

      dataBuffer.add(reading);
      if (dataBuffer.length > bufferLength) {
        dataBuffer.removeRange(0, dataBuffer.length - bufferLength);
      }

      yield reading;
    }
  }

  /// The most recent pitch detected, or `null` until one has been.
  FrequencyDetection? latestReading;

  /// Stop listening to the microphone and end [dataStream].
  Future<void> dispose() => _controller.close();
}
