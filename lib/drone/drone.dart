import 'package:drone_player/drone_player.dart';
import 'package:flutter/material.dart';
import 'package:musbx/tuner/note.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// The octave that all the drone tones are played in.
  static const int octave = 3;

  /// The [Note] used as a reference for all the drone tones.
  Note get referenceNote => referenceNoteNotifier.value;
  final ValueNotifier<Note> referenceNoteNotifier = ValueNotifier(Note.a4());

  /// Whether the Drone has been initialized or not.
  /// If true, [players] have been created.
  bool initialized = false;

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

    referenceNoteNotifier.addListener(_updatePlayers);

    initialized = true;
  }

  /// Update [isActive] when a player starts/stops playing
  void _updateIsActive() {
    isActiveNotifier.value = players.any((player) => player.isPlaying);
  }

  Future<void> _updatePlayers() async {
    for (int index = 0; index < 12; index++) {
      players[index]
          .setFrequency(Note.relativeToA4(index + 12 * (octave - 4)).frequency);
    }
  }

  /// Create a [DronePlayer].
  Future<DronePlayer> _createPlayer(int semitonesShifted) async {
    DronePlayer player = DronePlayer();
    Note droneTone = Note.relativeToA4(
        referenceNote.semitonesFromA4 + semitonesShifted + 12 * (octave - 4));

    await player.initialize();
    await player.setFrequency(droneTone.frequency);
    player.isPlayingNotifier.addListener(_updateIsActive);

    return player;
  }
}
