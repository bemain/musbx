import 'dart:math';

import 'package:drone_player/drone_player.dart';
import 'package:musbx/tuner/note.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// AudioPlayers used for playing the drone tones.
  late final List<DronePlayer> players =
      List.generate(12, (semitonesShifted) => createPlayer(semitonesShifted));

  /// Pause all the drone tones.
  Future<void> pauseAll() async {
    for (DronePlayer player in players) {
      await player.pause();
    }
  }

  DronePlayer createPlayer(int semitonesShifted) {
    DronePlayer player = DronePlayer();
    player.initialize().then((_) {
      player.setFrequency(semitoneToFrequency(semitonesShifted));
    });
    return player;
  }

  double semitoneToFrequency(int semitonesFromA) {
    double a = pow(2.0, 1 / 12).toDouble();
    return Note.a4().frequency * pow(a, semitonesFromA);
  }
}
