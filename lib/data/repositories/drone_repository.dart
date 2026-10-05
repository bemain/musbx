import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/models/tone_group.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';
import 'package:musbx/domain/models/music/temperament.dart';

class DroneRepository extends ChangeNotifier {
  /// The minimum octave of the [root].
  static const int minOctave = 2;

  /// The maximum octave of the [root].
  static const int maxOctave = 5;

  DroneRepository({
    required AudioEngineService audioEngine,
    required SharedPreferencesService sharedPreferences,
  }) : _audioEngine = audioEngine,
       _sharedPreferences = sharedPreferences {
    _onPitchesChanged();
  }

  final AudioEngineService _audioEngine;
  final SharedPreferencesService _sharedPreferences;

  /// Replaced by each [AudioEngineService.setTones], which returns a new group.
  late ToneGroup _tones = _audioEngine.createTones();

  /// The latest update to [_tones], which [dispose] waits for so that tones
  /// created while it runs are freed too.
  Future<void> _pendingTones = Future.value();

  Pitch get tuning => tuningNotifier.value;
  set tuning(Pitch value) => tuningNotifier.value = value;
  late final ValueNotifier<Pitch> tuningNotifier =
      _sharedPreferences.transformed<Pitch, String>(
        "drone/tuning",
        initialValue: const Pitch(PitchClass.a(), 4, 440),
        from: Pitch.parse,
        to: (pitch) => pitch.toString(),
      )..addListener(_onPitchesChanged);

  WaveForm get waveform => waveformNotifier.value;
  set waveform(WaveForm value) => waveformNotifier.value = value;
  late final ValueNotifier<WaveForm> waveformNotifier =
      _sharedPreferences.transformed<WaveForm, String>(
        "drone/waveform",
        initialValue: WaveForm.sin,
        to: (waveform) => waveform.name,
        from: (value) => WaveForm.values.firstWhere(
          (waveform) => waveform.name == value,
          orElse: () => WaveForm.sin,
        ),
      )..addListener(_onPitchesChanged);

  Temperament get temperament => _temperament.value;
  set temperament(Temperament value) => _temperament.value = value;
  late final ValueNotifier<Temperament> _temperament = ValueNotifier(
    const EqualTemperament(),
  )..addListener(_onPitchesChanged);

  /// The pitch the [intervals] are counted from, between C[minOctave] and
  /// B[maxOctave].
  Pitch get root => tuning.transposed(_root.value - _semitonesFromC0(tuning));
  set root(Pitch value) {
    _root.value = _semitonesFromC0(
      value,
    ).clamp(minOctave * 12, maxOctave * 12 + 11);
    _onPitchesChanged();
  }

  /// Semitones from C0, so the root stays on the same note when the tuning
  /// changes.
  ///
  /// Defaults to A3.
  late final ValueNotifier<int> _root = _sharedPreferences.value(
    "drone/rootFromC0",
    initialValue: 3 * 12 + 9,
  );

  static int _semitonesFromC0(Pitch pitch) =>
      pitch.octave * 12 + pitch.pitchClass.semitonesFromC;

  /// The pitches that are currently playing.
  Iterable<Pitch> get pitches => intervals.map(
    (interval) => root.transposed(interval, temperament: temperament),
  );

  Set<int> get intervals => Set.unmodifiable(_intervals.value);
  set intervals(Set<int> value) {
    _intervals.value = value;
    _onPitchesChanged();
  }

  late final ValueNotifier<Set<int>> _intervals = _sharedPreferences
      .transformed<Set<int>, List<String>>(
        "drone/intervals",
        initialValue: {},
        from: (strings) => {for (final s in strings) int.parse(s)},
        to: (ints) => [for (final i in ints) '$i'],
      );

  void addInterval(int interval) {
    _intervals.value = {...intervals, interval};
    _onPitchesChanged();
  }

  void removeInterval(int interval) {
    _intervals.value = intervals.where((i) => i != interval).toSet();
    _onPitchesChanged();
  }

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void pause() {
    if (!_isPlaying) return;
    _audioEngine.pauseTones(_tones);
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    if (_isPlaying) return;
    _audioEngine.resumeTones(_tones);
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> _onPitchesChanged() => _pendingTones = _updateTones();

  Future<void> _updateTones() async {
    _tones = await _audioEngine.setTones(
      _tones,
      [for (final pitch in pitches) pitch.frequency],
      waveform,
    );
    if (isPlaying) _audioEngine.resumeTones(_tones);
    if (intervals.isEmpty) pause();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(
      _pendingTones.then((_) => _audioEngine.stopTones(_tones)),
    );

    tuningNotifier.dispose();
    waveformNotifier.dispose();
    _temperament.dispose();
    _root.dispose();
    _intervals.dispose();

    super.dispose();
  }
}
