import 'dart:typed_data';

class AudioFrame {
  /// Data recorded from the microphone at a given [time].
  AudioFrame({
    DateTime? time,
    required this.data,
    required this.wave,
    required this.fft,
  }) : time = time ?? DateTime.now();

  /// When this data was recorded.
  final DateTime time;

  /// The streamed audio data.
  final Float32List data;

  /// Waveform data.
  final Float32List wave;

  /// FFT Data.
  final Float32List fft;
}
