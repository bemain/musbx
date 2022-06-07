import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class BpmTapper extends StatelessWidget {
  /// Button that sets [Metronome.bpm] based on you tapping.
  /// Measures the interval between each tap and averages your taps to estimate
  /// a bpm.
  const BpmTapper({
    super.key,
    this.resetDuration = const Duration(seconds: 60 ~/ Metronome.minBpm),
  });

  /// How long between two taps for them to be considered seperate, and not
  /// part of the same tempo.
  ///
  /// Defaults to the time between two beats if bpm is [Metronome.minBpm].
  final Duration resetDuration;

  @override
  Widget build(BuildContext context) {
    final Stopwatch stopwatch = Stopwatch();
    List<int> tapBpms = [];

    return ElevatedButton(
      onPressed: () {
        if (!stopwatch.isRunning || stopwatch.elapsed > resetDuration) {
          // Complete reset
          stopwatch.stop();
          stopwatch.reset();
          tapBpms = [];
          stopwatch.start();
          return;
        }

        tapBpms.add(60000 ~/ stopwatch.elapsedMilliseconds); // Add bpm
        // Calculate average
        Metronome.bpm = tapBpms.reduce((a, b) => a + b) ~/ tapBpms.length;

        stopwatch.reset(); // Reset stopwatch
      },
      child: const Padding(
        padding: EdgeInsets.all(10.0),
        child: Icon(Icons.tap_and_play),
      ),
    );
  }
}
