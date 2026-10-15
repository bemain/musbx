import 'dart:typed_data';

/// One buffer of microphone audio, and the two views of it the tuner draws.
class AudioFrame {
  AudioFrame({
    DateTime? time,
    required this.data,
    required this.wave,
    required this.fft,
  }) : time = time ?? DateTime.now();

  /// When this data was recorded.
  final DateTime time;

  /// The recorded samples.
  final Float32List data;

  /// The waveform of [data], as the recorder computed it for drawing.
  final Float32List wave;

  /// The frequency spectrum of [data].
  final Float32List fft;
}
