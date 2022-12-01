import 'dart:math';

import 'package:drone_player/drone_player.dart';
import 'package:flutter/material.dart';
import 'package:musbx/tuner/note.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._() {
    players = List.generate(
        12,
        (semitonesShifted) => _createPlayer(semitonesShifted)
          ..isPlayingNotifier.addListener(_updateIsActive));
  }

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// AudioPlayers used for playing the drone tones.
  late final List<DronePlayer> players;

  /// Whether any of the [players] are playing.
  bool get isActive => isActiveNotifier.value;
  ValueNotifier<bool> isActiveNotifier = ValueNotifier(false);

  /// Pause all the drone tones.
  void pauseAll() {
    for (DronePlayer player in players) {
      player.pause();
    }
  }

  /// Update [isActive] when a player starts/stops playing
  void _updateIsActive() {
    isActiveNotifier.value = !players.any((player) => player.isPlaying);
  }

  /// Create a [DronePlayer].
  DronePlayer _createPlayer(int semitonesShifted) {
    DronePlayer player = DronePlayer();
    player.initialize().then((_) {
      player.setFrequency(_semitoneToFrequency(semitonesShifted));
    });
    return player;
  }

  double _semitoneToFrequency(int semitonesFromA) {
    double a = pow(2, 1 / 12).toDouble();
    return Note.a4().frequency * pow(a, semitonesFromA);
  }
}
