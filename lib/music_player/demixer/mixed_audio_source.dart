import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:wav/wav.dart';

class MixedAudioSource extends StreamAudioSource {
  /// An [AudioSource] that mixes multiple .wav files.
  ///
  /// All [wavs] must have the same duration
  MixedAudioSource(this.wavs) : super(tag: 'MixedAudioSource') {
    assert(wavs.every((wav) => wav.duration == wavs[0].duration),
        "All wavs must have the same duration");
  }

  final List<Wav> wavs;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print("[DEMIXER] Request");
    int sourceLength = (wavs[0].duration * wavs[0].samplesPerSecond).toInt();

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: (end ?? sourceLength) - (start ?? 0),
      offset: start ?? 0,
      stream: Stream.fromIterable(
          [wavs[0].channels[0].buffer.asInt64List().sublist(start ?? 0, end)]),
      contentType: 'audio/wav',
    );
  }
}

List<int> mixWavs(List<Wav> wavs) {
  /// The bytes of [wavs] converted to mono.
  List<Float64List> wavsBytes = wavs.map((wav) => wav.toMono()).toList();

  assert(
      wavsBytes
          .skip(1)
          .every((wavBytes) => wavBytes.length == wavsBytes.first.length),
      "All wavs must have the same number of bytes");

  int nWavs = wavs.length;
  return List.generate(wavsBytes.first.length, (i) {
    // TODO: Consider volume of each wav
    return wavsBytes.fold(0.0, (sum, wavBytes) => sum + wavBytes[i]) ~/ nWavs;
  });
}
