import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musbx/metronome/beat_players.dart';

class Metronome {
  /// Minimum [bpm] allowed. [bpm] can never be less than this.
  static const int minBpm = 20;

  /// Maximum [bpm] allowed. [bpm] can never be more than this.
  static const int maxBpm = 300;

  /// Beats per minutes.
  ///
  /// Will always be between [minBpm] and [maxBpm].
  ///
  /// Automatically resets [count] when changed.
  static int get bpm => bpmNotifier.value;
  static set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  static ValueNotifier<int> bpmNotifier = ValueNotifier(60)..addListener(reset);

  /// Sounds for beats.
  static MetronomeBeatPlayers beatSounds = MetronomeBeatPlayers();

  /// Beats per bar.
  ///
  /// Automatically resets [count] when changed.
  static int get higher => beatSounds.length;
  static set higher(int value) => beatSounds.length = value;
  static ValueNotifier<int> higherNotifier = ValueNotifier(4)
    ..addListener(reset);

  /// Current beat. Ranges from 0 to [higher] - 1.
  static int get count => countNotifier.value;
  static set count(int value) => countNotifier.value = value;
  static ValueNotifier<int> countNotifier = ValueNotifier(0);

  /// Whether or not the metronome is playing.
  static bool get isRunning => isRunningNotifier.value;
  static set isRunning(bool value) => isRunningNotifier.value = value;
  static ValueNotifier<bool> isRunningNotifier = ValueNotifier(false);

  /// Internal [Timer], calls [_onTimeout] [bpm] times per minute.
  static Timer _timer = Timer(const Duration(), () {});

  /// Called on [_timer] timeout.
  /// Increases [count] and plays a sound.
  static void _onTimeout(Timer timer) {
    beatSounds[count].play();

    count++;
    count %= higher;
  }

  /// Start the metronome.
  static void start() {
    if (!_timer.isActive) {
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ bpm), _onTimeout);
      isRunning = true;
    }
  }

  /// Stop the metronome.
  static void stop() {
    if (_timer.isActive) {
      _timer.cancel();
      isRunning = false;
    }
  }

  /// Reset [count] and, if it is running, restart [_timer].
  static void reset() {
    count = 0;
    if (isRunning) {
      _timer.cancel();
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ bpm), _onTimeout);
    }
  }
}
