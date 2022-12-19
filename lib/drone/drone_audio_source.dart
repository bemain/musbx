import 'dart:math';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class DroneAudioSource extends StreamAudioSource {
  DroneAudioSource._(this.bytes);

  /// An [AudioSource] that provides a drone tone with a specific [frequency].
  factory DroneAudioSource({
    required double frequency,
    double volume = 256 * 64,
    int sampleRate = 44100,
  }) {
    List<int> wave =
        genSineWave(frequency, 32, volume: volume, sampleRate: sampleRate);
    return DroneAudioSource._(
        genWavHeader(dataLength: wave.length, sampleRate: sampleRate) + wave);
  }

  /// The bytes provided to [AudioPlayer] on a request.
  final List<int> bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: bytes.length,
      offset: start,
      stream: Stream.value(bytes),
      contentType: "audio/wav",
    );
  }

  /// Convert [value] to a list of 4 bytes.
  static List<int> toBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);

  /// Convert [value] to a list of 2 bytes.
  static List<int> shortToBytes(int value) =>
      Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);

  /// Generate the header as for a wav file.
  static List<int> genWavHeader({
    required int dataLength,
    int sampleRate = 44100,
    int bitsPerSample = 16,
  }) {
    return [
      ..."RIFF".codeUnits, // RIFF tag
      ...toBytes(0), // RIFF length
      ..."WAVE".codeUnits, // WAVE tag
      ..."fmt ".codeUnits, // FMT tag
      ...toBytes(16), // FMT length
      ...shortToBytes(1), // audio format
      ...shortToBytes(1), // num channels
      ...toBytes(sampleRate), // sample rate
      ...toBytes(sampleRate * bitsPerSample ~/ 8), // byte rate
      ...shortToBytes(bitsPerSample ~/ 8), // block align
      ...shortToBytes(bitsPerSample),
      ..."data".codeUnits, // DATA tag
      ...toBytes(dataLength) // data length
    ];
  }

  /// Generate [cycles] cycles of a sine wave with a specific [frequency].
  static List<int> genSineWave(
    double frequency,
    int cycles, {
    double volume = 256 * 64,
    int sampleRate = 44100,
  }) {
    // Generate 1 cycle
    List<int> cycle = [];
    for (int i = 0; i < sampleRate / frequency; i++) {
      cycle.addAll(shortToBytes(
          (volume * sin(i * 2 * frequency * pi / sampleRate)).toInt()));
    }
    // Repeat that cycle
    List<int> data = [];
    for (int i = 0; i < cycles; i++) {
      data.addAll(cycle);
    }
    return data;
  }
}
