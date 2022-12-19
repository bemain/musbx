import 'package:flutter/material.dart';
import 'package:musbx/drone/drone_player.dart';
import 'package:musbx/note/note.dart';
import 'package:musbx/note/temperament.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// Whether the Drone has been initialized or not.
  /// If true, [players] have been created.
  bool initialized = false;

  /// The [Note] at the root of the scale.
  /// Used as a reference for all the drone tones.
  Note get root => rootNotifier.value;
  final ValueNotifier<Note> rootNotifier = ValueNotifier(Note.a4());

  /// The temperament used for generating notes
  Temperament get temperament => temperamentNotifier.value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const PythagoreanTuning());

  /// The [DronePlayer]s used for playing drone tones.
  late final List<DronePlayer> players;

  /// Whether any of the [players] are playing.
  bool get isActive => isActiveNotifier.value;
  final ValueNotifier<bool> isActiveNotifier = ValueNotifier(false);

  /// Pause all the [players].
  void pauseAll() async {
    for (DronePlayer player in players) {
      await player.pause();
    }
  }

  /// Generate [players].
  Future<void> initialize() async {
    if (initialized) return;

    players = [];
    for (int semitonesShifted = 0; semitonesShifted < 12; semitonesShifted++) {
      players.add(await _createPlayer(semitonesShifted));
    }

    rootNotifier.addListener(_updatePlayers);

    initialized = true;
  }

  /// Create a [DronePlayer].
  Future<DronePlayer> _createPlayer(int semitonesShifted) async {
    double toneFrequency = Note.inScale(
      root,
      semitonesShifted,
      temperament: temperament,
    ).frequency;

    DronePlayer player = DronePlayer(toneFrequency);

    player.isPlayingNotifier.addListener(_updateIsActive);

    return player;
  }

  /// Update [isActive] when a [DronePlayer] starts/stops playing
  void _updateIsActive() {
    isActiveNotifier.value = players.any((player) => player.isPlaying);
  }

  /// Update the frequency of all the [players]
  /// when the [root] or [temperament] changes.
  Future<void> _updatePlayers() async {
    for (int index = 0; index < 12; index++) {
      players[index].frequency = Note.inScale(
        root,
        index,
        temperament: temperament,
      ).frequency;
    }
  }
}
