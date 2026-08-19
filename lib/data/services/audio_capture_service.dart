import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:musbx/data/models/audio_frame.dart';

/// Service for capturing audio from the microphone.
class AudioCaptureService {
  AudioCaptureService._(
    this._recorder, {
    required this.sampleRate,
    required this.format,
  });

  final Recorder _recorder;

  /// The sample rate of the recording.
  final int sampleRate;

  /// The format used for recording.
  final PCMFormat format;

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

  /// The realtime data recorded from the microphone.
  ///
  /// Recording starts automatically when the stream is listened to.
  Stream<AudioFrame> get dataStream => (StreamController<AudioFrame>(
    onListen: _startStreaming,
    onPause: _stopStreaming,
    onResume: _startStreaming,
    onCancel: _stopStreaming,
  )..addStream(_dataStream)).stream;

  void _startStreaming() {
    _recorder.start();
    _recorder.startStreamingData();
  }

  void _stopStreaming() {
    _recorder.stopStreamingData();
    _recorder.stop();
  }

  /// The stream used internally to receive data.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  late final Stream<AudioFrame> _dataStream = Recorder.instance.uint8ListStream
      .map(_processData);

  /// Process audio data. Performs pitch detection.
  AudioFrame _processData(AudioDataContainer data) {
    final AudioFrame out = AudioFrame(
      data: data.toF32List(from: format),
      wave: Float32List.fromList(_recorder.getWave()),
      fft: Float32List.fromList(_recorder.getFft()),
    );

    return out;
  }
}
