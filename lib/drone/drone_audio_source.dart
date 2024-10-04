import 'dart:math';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class DroneAudioSource extends StreamAudioSource {
  /// An [AudioSource] that provides a drone tone with specific [frequencies].
  DroneAudioSource({
    required this.frequencies,
    this.length = 128 * 256,
    this.offset = 0,
    this.amplitude = 128 * 64,
    this.sampleRate = 44100,
  });

  /// The frequencies generated.
  final List<double> frequencies;

  /// The number of bytes generated.
  final int length;

  /// The sample rate of the generated wave.
  /// Defaults to 44100.
  final int sampleRate;

  /// The amplitude of the generated waves.
  /// Defaults to 2^13.
  final double amplitude;

  /// The multiples of [length] to offset the generated wave with.
  /// This is used to remove stuttering between loops by offsetting the generate wave files to match the previous iteration.
  final int offset;

  late final List<int> bytes = generateHeader() + generateWave();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: bytes.length,
      offset: start,
      stream: Stream.value(bytes),
      contentType: "audio/wav",
    );
  }

  /// Convert [value] to a list of 4 bytes.
  static List<int> longToBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);

  /// Convert [value] to a list of 2 bytes.
  static List<int> shortToBytes(int value) =>
      Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);

  /// Generate the header as for a wav file.
  List<int> generateHeader({
    int bitsPerSample = 16,
    int channels = 1,
  }) {
    return [
      ..."RIFF".codeUnits, // RIFF tag
      ...longToBytes(44), // RIFF length
      ..."WAVE".codeUnits, // WAVE tag
      ..."fmt ".codeUnits, // FMT tag
      ...longToBytes(16), // FMT length
      ...shortToBytes(1), // audio format
      ...shortToBytes(channels), // num channels
      ...longToBytes(sampleRate), // sample rate
      ...longToBytes(channels * sampleRate * bitsPerSample ~/ 8), // byte rate
      ...shortToBytes(2 * channels), // block align
      ...shortToBytes(bitsPerSample), // bits per sample
      ..."data".codeUnits, // DATA tag
      ...longToBytes(channels * length * 2) // data length
    ];
  }

  /// Generate one sample of the specified [frequencies] mixed.
  /// The sample will have the length [length].
  List<int> generateWave() {
    List<int> wave = [];
    for (int i = 0; i < length; i++) {
      wave.addAll(shortToBytes(
        amplitude *
            frequencies.fold(0.0, (sum, frequency) {
              final double value =
                  sin((offset * length + i) * frequency * 2 * pi / sampleRate);
              return sum + value;
            }) ~/
            frequencies.length,
      ));
    }

    return wave;
  }
}
