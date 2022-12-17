import 'package:drone_player/drone_player.dart';
import 'package:flutter/material.dart';
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

  /// The [Note] used as a reference for all the drone tones.
  Note get root => rootNotifier.value;
  final ValueNotifier<Note> rootNotifier = ValueNotifier(Note.a4());

  /// The temperament used when generating notes
  Temperament get temperament => temperamentNotifier.value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const PythagoreanTuning());

  /// AudioPlayers used for playing the drone tones.
  late final List<DronePlayer> players;

  /// Whether any of the [players] are playing.
  bool get isActive => isActiveNotifier.value;
  final ValueNotifier<bool> isActiveNotifier = ValueNotifier(false);

  /// Pause all the drone tones.
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

  /// Update [isActive] when a player starts/stops playing
  void _updateIsActive() {
    isActiveNotifier.value = players.any((player) => player.isPlaying);
  }

  Future<void> _updatePlayers() async {
    for (int index = 0; index < 12; index++) {
      players[index].setFrequency(Note.relativeToA4(index).frequency);
    }
  }

  /// Create a [DronePlayer].
  Future<DronePlayer> _createPlayer(int semitonesShifted) async {
    DronePlayer player = DronePlayer();

    double toneFrequency = Note.inScale(
      root,
      semitonesShifted,
      temperament: temperament,
    ).frequency;

    await player.initialize();
    await player.setFrequency(toneFrequency);
    player.isPlayingNotifier.addListener(_updateIsActive);

    return player;
  }
}
