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

  /// Whether the Drone has been initialized or not.
  /// If true, [players] have been created.
  bool initialized = false;

  /// AudioPlayers used for playing the drone tones.
  late final List<DronePlayer> players;

  /// Whether any of the [players] are playing.
  bool get isActive => isActiveNotifier.value;
  ValueNotifier<bool> isActiveNotifier = ValueNotifier(false);

  /// Pause all the drone tones.
  void pauseAll() async {
    for (DronePlayer player in players) {
      await player.pause();
    }
  }

  /// Generate [players].
  Future<void> initialize() async {
    if (initialized) return;
    // Create players
    players = [];
    for (int semitonesShifted = 0; semitonesShifted < 12; semitonesShifted++) {
      players.add(await _createPlayer(semitonesShifted)
        ..isPlayingNotifier.addListener(_updateIsActive));
    }

    initialized = true;
  }

  /// Update [isActive] when a player starts/stops playing
  void _updateIsActive() {
    isActiveNotifier.value = players.any((player) => player.isPlaying);
  }

  /// Create a [DronePlayer].
  Future<DronePlayer> _createPlayer(int semitonesShifted) async {
    DronePlayer player = DronePlayer();
    await player.initialize();
    await player.setFrequency(Note.relativeToA4(semitonesShifted).frequency);
    return player;
  }
}
