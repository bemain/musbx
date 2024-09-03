import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/drone/drone_audio_source.dart';
import 'package:musbx/model/note.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';

/// Singleton for playing drone tones.
class Drone {
  // Only way to access is through [instance].
  Drone._();

  /// The instance of this singleton.
  static final Drone instance = Drone._();

  /// The [AudioPlayer] used internally to play audio.
  late final AudioPlayer _player = AudioPlayer()
    ..setLoopMode(LoopMode.off)
    ..playingStream.listen((value) => isPlayingNotifier.value = value)
    ..currentIndexStream.listen((value) {
      if ((_player.audioSource is ConcatenatingAudioSource)) {
        final source = _player.audioSource as ConcatenatingAudioSource;
        source.add(DroneAudioSource(
          frequencies: _frequencies,
          offset: source.length,
        ));
      }
    });

  /// The [Note] at the root of the scale.
  /// Used as a reference for all the drone tones.
  Note get root => rootNotifier.value;
  late final ValueNotifier<Note> rootNotifier =
      ValueNotifier(Note(PitchClass.c, 4, temperament: temperament));

  /// The temperament used for generating notes
  Temperament get temperament => temperamentNotifier.value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const EqualTemperament());

  /// The frequencies currently played.
  List<double> get frequencies => _frequencies;
  final List<double> _frequencies = [];

  /// Whether the drone is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Start playing a [frequency].
  void play(double frequency) async {
    if (_frequencies.contains(frequency)) return;

    _frequencies.add(frequency);
    _onFrequenciesChanged();
  }

  /// Stop playing a [frequency].
  void pause(double frequency) async {
    if (!_frequencies.contains(frequency)) return;

    _frequencies.removeWhere((element) => element == frequency);
    _onFrequenciesChanged();
  }

  /// Stop playing all frequencies.
  void pauseAll() async {
    _frequencies.clear();
    _onFrequenciesChanged();
  }

  /// Update [isPlaying] when a frequency is added or removed.
  void _onFrequenciesChanged() async {
    if (_frequencies.isEmpty) {
      _player.pause();
      return;
    }

    // Hack: we use a concatenating audio source so that the current index changes.
    await _player.setAudioSource(ConcatenatingAudioSource(children: [
      DroneAudioSource(frequencies: _frequencies),
      DroneAudioSource(frequencies: _frequencies, offset: 1),
    ]));
    _player.play();
  }
}
