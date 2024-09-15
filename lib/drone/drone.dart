import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/drone/drone_audio_source.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/widgets.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// The [AudioPlayer] used internally to play audio.
  late final AudioPlayer _player = AudioPlayer()
    ..playingStream.listen((value) => isPlayingNotifier.value = value)
    ..currentIndexStream.listen((value) {
      if ((_player.audioSource is ConcatenatingAudioSource)) {
        final source = _player.audioSource as ConcatenatingAudioSource;
        source.add(DroneAudioSource(
          frequencies: [
            for (Pitch pitch in pitches) pitch.frequency,
          ],
          offset: source.length,
        ));
      }
    });

  /// The minimum octave of the [root].
  static int minOctave = 2;

  /// The maximum octave of the [root].
  static int maxOctave = 5;

  /// The [Pitch] at the root of the scale.
  /// Used as a reference when selecting what pitches to present to the user.
  Pitch get root => rootNotifier.value;
  set root(Pitch value) => rootNotifier.value = value;
  late final ValueNotifier<Pitch> rootNotifier =
      ValueNotifier(const Pitch(PitchClass.a(), 3, 220))
        ..addListener(_onPitchesChanged);

  /// The temperament used for generating notes
  Temperament get temperament => temperamentNotifier.value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const EqualTemperament());

  /// The pitches that are currently playing.
  Iterable<Pitch> get pitches => intervals.map(
      (int interval) => root.transposed(interval, temperament: temperament));

  /// The intervals relative to the [root] that are currently playing.
  List<int> get intervals => intervalsNotifier.value;
  late final ListNotifier<int> intervalsNotifier = ListNotifier([])
    ..addListener(_onPitchesChanged);

  /// Whether the drone is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Start playing the current [pitches].
  Future<void> play() => _player.play();

  /// Pause playback.
  Future<void> pause() => _player.pause();

  Future<void>? loadAudioLock;

  void _onPitchesChanged() async {
    if (intervals.isEmpty) {
      pause();
      return;
    }

    // Make sure no other process is currently setting the audio source
    loadAudioLock = _updateAudioSource(
      awaitBeforeLoading: loadAudioLock,
    );
    await loadAudioLock;
  }

  /// Awaits [awaitBeforeLoading] and updates the audio source.
  /// This is used to implement locking.
  Future<void> _updateAudioSource({
    Future<void>? awaitBeforeLoading,
  }) async {
    try {
      await awaitBeforeLoading;
    } catch (_) {}

    final List<double> frequencies = [
      for (Pitch pitch in pitches) pitch.frequency,
    ];

    // Hack: we use a concatenating audio source so that the current index changes.
    await _player.setAudioSource(ConcatenatingAudioSource(children: [
      DroneAudioSource(frequencies: frequencies),
      DroneAudioSource(frequencies: frequencies, offset: 1),
    ]));
  }
}
