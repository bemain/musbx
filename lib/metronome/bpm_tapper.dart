import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class BpmTapper extends StatelessWidget {
  /// Button that sets [Metronome.bpm] based on you tapping.
  /// Measures the interval between each tap and averages your taps to estimate
  /// a bpm.
  const BpmTapper({
    super.key,
    this.resetDuration = const Duration(seconds: 60 ~/ Metronome.minBpm),
    this.tapsRemembered = 10,
  });

  /// How long between two taps for them to be considered seperate, and not
  /// part of the same tempo.
  ///
  /// Defaults to the time between two beats if bpm is [Metronome.minBpm].
  final Duration resetDuration;

  /// How many taps to remember. Only keeps this many of the most recent taps.
  final int tapsRemembered;

  @override
  Widget build(BuildContext context) {
    final Stopwatch stopwatch = Stopwatch();
    List<int> tapBpms = [];

    final AudioPlayer audioPlayer = AudioPlayer();
    final AudioCache audioCache = AudioCache(
      fixedPlayer: audioPlayer,
    );

    return OutlinedButton(
      onPressed: () {
        if (!stopwatch.isRunning || stopwatch.elapsed > resetDuration) {
          // Complete reset
          stopwatch.stop();
          stopwatch.reset();
          tapBpms = [];
          stopwatch.start();
          return;
        }

        // Stop metronome so it doesn't play sound while user is tapping
        Metronome.stop();

        // Play sound
        audioCache.play("bpm_tapper.mp3", mode: PlayerMode.LOW_LATENCY);

        tapBpms.add(60000 ~/ stopwatch.elapsedMilliseconds); // Add bpm
        // Only keep the last [tapsRemembered] taps
        tapBpms.removeRange(0, max(tapBpms.length - tapsRemembered, 0));

        // Calculate average
        Metronome.bpm = tapBpms.reduce((a, b) => a + b) ~/ tapBpms.length;

        stopwatch.reset(); // Reset stopwatch
      },
      child: const Padding(
        padding: EdgeInsets.all(10.0),
        child: Icon(Icons.ads_click_rounded),
      ),
    );
  }
}
