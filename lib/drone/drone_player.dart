import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/drone/drone_audio_source.dart';

class DronePlayer {
  /// An AudioPlayer used for playing a note of a specific [frequency].
  DronePlayer(double frequency) : frequencyNotifier = ValueNotifier(frequency) {
    frequencyNotifier.addListener(() {
      _audioPlayer.setAudioSource(DroneAudioSource(frequency: frequency));
    });
    _audioPlayer.setAudioSource(DroneAudioSource(frequency: frequency));

    _audioPlayer.playingStream.listen((value) {
      isPlayingNotifier.value = value;
    });
  }

  /// The [AudioPlayer] used internally to play audio.
  final AudioPlayer _audioPlayer = AudioPlayer()..setLoopMode(LoopMode.all);

  /// The frequency of the note that this [DronePlayer] plays.
  double get frequency => frequencyNotifier.value;
  set frequency(double value) => frequencyNotifier.value = value;
  final ValueNotifier<double> frequencyNotifier;

  /// Whether this [DronePlayer] is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Start the drone tone.
  Future<void> play() async => await _audioPlayer.play();

  /// Pause the drone tone.
  Future<void> pause() async => await _audioPlayer.pause();
}
