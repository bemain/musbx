import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/audio_frame.dart';

/// Captures audio from the microphone.
///
/// Hands out whole [AudioFrame]s rather than raw bytes: each one carries the
/// samples together with the waveform and spectrum the recorder computed for
/// exactly those samples. Reading them separately afterwards would pair a frame
/// with whatever the microphone had heard by then instead.
///
/// The microphone is only running while [dataStream] is listened to, so nothing
/// here holds it open.
///
/// Optional: [disabled] returns a service with no microphone behind it. Callers
/// are expected to check [isEnabled] and show something else instead of
/// listening to nothing.
class AudioCaptureService extends OptionalService {
  AudioCaptureService._(
    this.__recorder, {
    required this.sampleRate,
    required this.format,
  });

  /// The plugin handle, or `null` when this service is [disabled].
  final Recorder? __recorder;

  Recorder get _recorder {
    throwIfDisabled();
    return __recorder!;
  }

  @override
  bool get isEnabled => __recorder != null;

  /// The sample rate of the recording.
  ///
  /// Bounds the highest frequency that can be detected at half its value, so
  /// lowering it silently costs the top of the range.
  final int sampleRate;

  /// The format used for recording.
  ///
  /// Determines how [AudioFrame.data] is decoded, so the two have to agree —
  /// which is why it is kept rather than assumed.
  final PCMFormat format;

  /// Create the service, claiming the microphone at [sampleRate].
  ///
  /// Throws if the recorder cannot be set up, which includes the device having
  /// no input at all. It does not start recording, and does not need the
  /// microphone permission yet; that is only asked for on the first listen.
  ///
  /// The device may not support [sampleRate] and can settle on a nearby one, so
  /// callers that care about the exact rate should read it back rather than
  /// assume what they asked for.
  static Future<AudioCaptureService> create({
    Recorder? recorder,
    int sampleRate = 22050,
    PCMFormat format = PCMFormat.f32le,
  }) async {
    final r = recorder ?? Recorder.instance;
    await r.init(
      format: format,
      sampleRate: sampleRate,
      channels: RecorderChannels.mono,
    );
    return AudioCaptureService._(
      r,
      sampleRate: sampleRate,
      format: format,
    );
  }

  /// A service with no microphone behind it, for a device that has none.
  static AudioCaptureService disabled() =>
      AudioCaptureService._(null, sampleRate: 22050, format: PCMFormat.f32le);

  /// The realtime data recorded from the microphone.
  ///
  /// The microphone opens when the first listener arrives and closes when the
  /// last one leaves, so holding on to this stream costs nothing while nothing
  /// is reading it, and a screen that comes back can listen again.
  ///
  /// Frames are dropped rather than queued while nobody is listening. This
  /// describes what the microphone is hearing now, and a backlog of stale audio
  /// would be worse than a gap.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  Stream<AudioFrame> get dataStream {
    throwIfDisabled();
    return _controller.stream;
  }

  /// What ties [_controller] to the recorder, held only while someone is
  /// listening.
  StreamSubscription<AudioFrame>? _subscription;

  /// Wraps [_dataStream] so that the microphone runs only while something is
  /// listening to it.
  ///
  /// Broadcast so that leaving a screen and coming back works: a
  /// single-subscription stream cannot be listened to a second time, and the
  /// tuner is left and returned to constantly.
  late final StreamController<AudioFrame> _controller =
      StreamController<AudioFrame>.broadcast(
        onListen: () {
          _recorder.start();
          _recorder.startStreamingData();
          _subscription = _dataStream.listen(_controller.add);
        },
        onCancel: () async {
          _recorder.stopStreamingData();
          _recorder.stop();
          await _subscription?.cancel();
          _subscription = null;
        },
      );

  /// The stream used internally to receive data.
  ///
  /// Built once, but only attached to while [_controller] has listeners, so the
  /// recorder is left alone the rest of the time.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  late final Stream<AudioFrame> _dataStream = _recorder.uint8ListStream.map(
    _processData,
  );

  /// Assemble one frame from the samples the recorder just delivered.
  ///
  /// The waveform and spectrum are pulled here rather than on demand, because
  /// the recorder only ever reports what it heard most recently — asking later
  /// would describe a different moment than [AudioFrame.data] holds.
  ///
  /// Both are copied out. What the recorder returns is a view onto memory it
  /// owns and overwrites on the next capture, so a frame that kept the view
  /// would change under whoever was reading it.
  AudioFrame _processData(AudioDataContainer data) {
    final AudioFrame out = AudioFrame(
      data: data.toF32List(from: format),
      wave: Float32List.fromList(_recorder.getWave()),
      fft: Float32List.fromList(_recorder.getFft()),
    );

    return out;
  }

  /// Give up the microphone and close [dataStream].
  ///
  /// Nothing recovers from this: the recorder is torn down rather than merely
  /// stopped, so it belongs to the app shutting down and not to a screen going
  /// away — [dataStream] already releases the microphone when its listener
  /// leaves.
  ///
  /// Unlike the rest of this service, does nothing rather than throwing when
  /// [disabled].
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
    __recorder?.deinit();
  }
}
