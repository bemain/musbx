import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:soundpool/soundpool.dart';

class BpmTapper extends StatelessWidget {
  /// Button that sets [Metronome.bpm] based on you tapping.
  /// Measures the interval between each tap and averages your taps to estimate
  /// a bpm.
  const BpmTapper({
    super.key,
    this.resetDuration = const Duration(seconds: 60 ~/ Metronome.minBpm),
    this.tapsRemembered = 10,
  });

  /// [Soundpool] used internally for playing sound.
  static final Soundpool _pool = Soundpool.fromOptions(
    options: const SoundpoolOptions(streamType: StreamType.music),
  );

  /// Id for the sound played when this button is pressed.
  static int? soundId;

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

    // Make sure sound has been loaded.
    if (soundId == null) {
      rootBundle.load("assets/sounds/metronome/bpm_tapper.wav").then(
          (ByteData soundData) =>
              _pool.load(soundData).then((value) => soundId = value));
    }

    return Listener(
      onPointerDown: (_) async {
        // Play sound
        if (soundId != null) _pool.play(soundId!);

        if (await FlutterVolumeController.getMute() == true) {
          // Vibrate
          HapticFeedback.vibrate();
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
        Metronome.instance.pause();

        // Add bpm
        tapBpms.add(60000 ~/ stopwatch.elapsedMilliseconds);
        // Only keep the last [tapsRemembered] taps
        tapBpms.removeRange(0, max(tapBpms.length - tapsRemembered, 0));

        // Update bpm
        Metronome.instance.bpm =
            tapBpms.reduce((a, b) => a + b) ~/ tapBpms.length;
        Metronome.instance.reset();

        // Reset stopwatch
        stopwatch.reset();
      },
      child: IconButton.outlined(
        onPressed: () {},
        icon: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.ads_click),
        ),
      ),
    );
  }
}
