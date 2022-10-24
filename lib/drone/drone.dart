import 'dart:math';

import 'package:just_audio/just_audio.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// AudioPlayers used for playing the drone tones.
  final List<AudioPlayer> players = List.generate(
    12,
    (semitonesShifted) => AudioPlayer()
      ..setAsset("assets/drone_440Hz")
      ..setPitch(pow(2, semitonesShifted / 12).toDouble()),
  );

  /// Pause all the drone tones.
  Future<void> pauseAll() async {
    for (AudioPlayer player in players) {
      await player.pause();
    }
  }
}
