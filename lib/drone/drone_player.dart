import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';

class DronePlayer {
  /// An AudioPlayer used for playing a note of a specific [frequency].
  DronePlayer(double frequency) : frequencyNotifier = ValueNotifier(frequency);

  /// The frequency of the note that this [DronePlayer] plays.
  double get frequency => frequencyNotifier.value;
  set frequency(double value) => frequencyNotifier.value = value;
  final ValueNotifier<double> frequencyNotifier;

  /// Whether this [DronePlayer] is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Start the drone tone.
  Future<void> play() async => Drone.instance.play(frequency);

  /// Pause the drone tone.
  Future<void> pause() async => Drone.instance.pause(frequency);
}
