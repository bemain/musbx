import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/utils/persistent_value.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._() : handle = _soloud.createVoiceGroup() {
    _onPitchesChanged();
  }

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  static final SoLoud _soloud = SoLoud.instance;

  /// The minimum octave of the [root].
  static int minOctave = 2;

  /// The maximum octave of the [root].
  static int maxOctave = 5;

  /// The [Pitch] at the root of the scale.
  /// Used as a reference when selecting what pitches to present to the user.
  Pitch get root => rootNotifier.value;
  set root(Pitch value) => rootNotifier.value = value;
  late final ValueNotifier<Pitch> rootNotifier =
      TransformedPersistentValue<Pitch, String>(
        "drone/root",
        initialValue: const Pitch(PitchClass.a(), 3, 220),
        from: Pitch.parse,
        to: (pitch) => pitch.toString(),
      )..addListener(_onPitchesChanged);

  /// The temperament used for generating pitches
  Temperament get temperament => temperamentNotifier.value;
  late final ValueNotifier<Temperament> temperamentNotifier = ValueNotifier(
    const EqualTemperament(),
  )..addListener(_onPitchesChanged);

  /// The pitches that are currently playing.
  Iterable<Pitch> get pitches => intervals.map(
    (interval) => root.transposed(interval, temperament: temperament),
  );

  /// The intervals relative to the [root] that are currently playing.
  List<int> get intervals => List.unmodifiable(intervalsNotifier.value);
  set intervals(List<int> value) => intervalsNotifier.value = value;
  late final ValueNotifier<List<int>> intervalsNotifier =
      TransformedPersistentValue<List<int>, List<String>>(
        "drone/intervals",
        initialValue: [],
        from: (strings) => [for (final s in strings) int.parse(s)],
        to: (ints) => [for (final i in ints) '$i'],
      )..addListener(_onPitchesChanged);

  /// Whether the drone is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  final List<FrequencyPlayer> players = [];

  final SoundHandle handle;

  /// Pause playback.
  void pause() {
    _soloud.setPause(handle, true);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  void resume() {
    _soloud.setPause(handle, false);
    isPlayingNotifier.value = true;
  }

  Future<void> _onPitchesChanged() async {
    // Add missing players
    for (int i = players.length; i < intervals.length; i++) {
      final player = await FrequencyPlayer.load();
      _soloud.addVoicesToGroup(handle, [player.handle]);
      players.add(player);
    }

    // Remove excess players
    for (int i = players.length - 1; i >= intervals.length; i--) {
      await players[i].dispose();
      players.removeAt(i);
    }

    // Set frequencies
    for (int i = 0; i < players.length; i++) {
      players[i].frequency = pitches.toList()[i].frequency;
    }

    if (intervals.isEmpty) {
      pause();
    } else if (isPlaying) {
      resume();
    }
  }
}

class FrequencyPlayer {
  static final SoLoud _soloud = SoLoud.instance;

  /// Helper class for playing a single [frequency], using [SoLoud] waveforms.
  FrequencyPlayer._(this.source, this.handle, {double frequency = 440}) {
    this.frequency = frequency;
  }

  static Future<FrequencyPlayer> load({
    WaveForm type = WaveForm.sin,
    double frequency = 440,
  }) async {
    final source = await _soloud.loadWaveform(type, false, 1.0, 0.0);
    final handle = await _soloud.play(source, paused: true);
    return FrequencyPlayer._(source, handle, frequency: frequency);
  }

  final AudioSource source;

  final SoundHandle handle;

  /// Free the resources used by this player.
  Future<void> dispose() async {
    await _soloud.stop(handle);
    await _soloud.disposeSource(source);
  }

  set frequency(double value) => _soloud.setWaveformFreq(source, value);
}
