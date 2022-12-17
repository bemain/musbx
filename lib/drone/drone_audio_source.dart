import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class DroneAudioSource extends StreamAudioSource {
  DroneAudioSource._(this.bytes);

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
}

List<int> toBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);

List<int> shortToBytes(int value) =>
    Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);

List<int> genWavHeader({required int dataLength, int sampleRate = 44100}) {
  int bitsPerSample = 16;
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

List<int> genSineWave(
  double frequency,
  int cycles, {
  double volume = 256 * 64,
  int sampleRate = 44100,
}) {
  List<int> cycle = [];
  for (int i = 0; i < sampleRate / frequency; i++) {
    cycle.addAll(shortToBytes(
        (volume * sin(i * 2 * frequency * pi / sampleRate)).toInt()));
  }
  List<int> data = [];
  for (int i = 0; i < cycles; i++) {
    data.addAll(cycle);
  }
  return data;
}

class DronePlayer {
  DronePlayer(double frequency) : frequencyNotifier = ValueNotifier(frequency) {
    frequencyNotifier.addListener(() {
      _audioPlayer.setAudioSource(DroneAudioSource(frequency: frequency));
    });
    _audioPlayer.setAudioSource(DroneAudioSource(frequency: frequency));

    _audioPlayer.playingStream.listen((value) {
      isPlayingNotifier.value = value;
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer()..setLoopMode(LoopMode.all);

  double get frequency => frequencyNotifier.value;
  set frequency(double value) => frequencyNotifier.value = value;
  final ValueNotifier<double> frequencyNotifier;

  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  Future<void> play() async => await _audioPlayer.play();

  Future<void> pause() async => await _audioPlayer.pause();
}
