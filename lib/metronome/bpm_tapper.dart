import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/metronome/metronome_repository.dart';
import 'package:provider/provider.dart';
import 'package:volume_controller/volume_controller.dart';

/// Button that sets [Metronome.bpm] based on you tapping.
/// Measures the interval between each tap and averages your taps to estimate
/// a bpm.
class BpmTapper extends StatelessWidget {
  const BpmTapper({
    super.key,
    this.resetDuration = const Duration(
      seconds: 60 ~/ MetronomeRepository.minBpm,
    ),
    this.tapsRemembered = 10,
  });

  /// The sound played when this button is pressed.
  static AudioSource? sound;

  /// How long between two taps for them to be considered seperate, and not
  /// part of the same tempo.
  ///
  /// Defaults to the time between two beats if bpm is [Metronome.minBpm].
  final Duration resetDuration;

  /// How many taps to remember. Only keeps this many of the most recent taps.
  final int tapsRemembered;

  @override
  Widget build(BuildContext context) {
    final MetronomeRepository metronome = context.read();

    final Stopwatch stopwatch = Stopwatch();
    List<int> tapBpms = [];

    // Make sure sound has been loaded.
    if (sound == null) {
      () async {
        sound = await SoLoud.instance.loadAsset(
          "assets/sounds/metronome/bpm_tapper.mp3",
        );
      }();
    }

    return Listener(
      onPointerDown: (_) async {
        // Play sound
        if (sound != null) SoLoud.instance.play(sound!);

        if (await VolumeController.instance.isMuted() ||
            metronome.volume == 0.0) {
          // Vibrate
          await HapticFeedback.vibrate();
        }

        if (!stopwatch.isRunning || stopwatch.elapsed > resetDuration) {
          // Complete reset
          stopwatch.stop();
          stopwatch.reset();
          tapBpms = [];
          stopwatch.start();
          return;
        }

        // Stop metronome so it doesn't play sound while user is tapping
        metronome.pause();

        // Add bpm
        if (stopwatch.elapsed > Duration.zero) {
          tapBpms.add(60000 ~/ stopwatch.elapsedMilliseconds);
        }
        // Only keep the last [tapsRemembered] taps
        tapBpms.removeRange(0, max(tapBpms.length - tapsRemembered, 0));

        // Update bpm
        metronome.bpm = tapBpms.reduce((a, b) => a + b) ~/ tapBpms.length;

        // Reset stopwatch
        stopwatch.reset();
      },
      child: IconButton.outlined(
        onPressed: () {},
        icon: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Symbols.touch_app),
        ),
      ),
    );
  }
}
