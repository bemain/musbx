import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome_beats.dart';

class Metronome {
  Metronome._();

  /// The instance of this singleton.
  static final Metronome instance = Metronome._();

  /// Minimum [bpm] allowed. [bpm] can never be less than this.
  static const int minBpm = 20;

  /// Maximum [bpm] allowed. [bpm] can never be more than this.
  static const int maxBpm = 250;

  /// Beats per minutes.
  ///
  /// Clamped between [minBpm] and [maxBpm].
  ///
  /// Automatically resets [count] when changed.
  int get bpm => bpmNotifier.value;
  set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  late final ValueNotifier<int> bpmNotifier = ValueNotifier(60)
    ..addListener(reset);

  /// Sounds for beats.
  final MetronomeBeats beatSounds = MetronomeBeats();

  /// Beats per bar.
  ///
  /// Automatically resets [count] when changed.
  int get higher => beatSounds.length;
  set higher(int value) => beatSounds.length = value;
  late final ValueNotifier<int> higherNotifier = ValueNotifier(4)
    ..addListener(reset);

  /// Current beat. Ranges from 0 to [higher] - 1.
  int get count => countNotifier.value;
  set count(int value) => countNotifier.value = value;
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  /// Whether or not the metronome is playing.
  bool get isRunning => isRunningNotifier.value;
  set isRunning(bool value) => isRunningNotifier.value = value;
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier(false);

  /// Internal timer, calls [_onTimeout] [bpm] times per minute.
  Timer _timer = Timer(Duration.zero, () {})..cancel();

  /// Called on [_timer] timeout.
  /// Increases [count] and plays a sound.
  void _onTimeout(Timer timer) {
    count++;
    count %= higher;

    beatSounds.playBeat(count);
  }

  /// Start the metronome.
  void start() {
    if (!_timer.isActive) {
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ bpm), _onTimeout);
      isRunning = true;
    }
  }

  /// Stop the metronome.
  void stop() {
    if (_timer.isActive) {
      _timer.cancel();
      isRunning = false;
    }
  }

  /// Reset [count] and, if it is running, restart [_timer].
  void reset() {
    count = higher - 1;
    if (isRunning) {
      _timer.cancel();
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ bpm), _onTimeout);
    }
  }
}
