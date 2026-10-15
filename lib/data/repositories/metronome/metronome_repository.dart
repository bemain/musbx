import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';

enum _TickKind { accented, primary, subdivision }

/// The sounds loaded for each [_TickKind].
class _Ticks {
  const _Ticks({
    required this.accented,
    required this.primary,
    required this.subdivision,
  });

  final AudioSource accented;
  final AudioSource primary;
  final AudioSource subdivision;

  static Future<_Ticks> create({
    required AudioEngineService audioEngine,
    String assetsPath = "assets/sounds/metronome",
  }) async {
    return _Ticks(
      accented: await audioEngine.loadAsset(
        "$assetsPath/beat_accented.mp3",
      ),
      primary: await audioEngine.loadAsset(
        "$assetsPath/beat_primary.mp3",
      ),
      subdivision: await audioEngine.loadAsset(
        "$assetsPath/beat_subdivision.mp3",
      ),
    );
  }

  Future<void> dispose({
    required AudioEngineService audioEngine,
  }) async {
    for (final source in [accented, primary, subdivision]) {
      await audioEngine.unload(source);
    }
  }
}

/// A metronome whose ticks are scheduled on the audio engine's clock.
///
/// A timer looks [_scheduleAhead] into the future and schedules every tick
/// falling inside it, so timing does not depend on when Dart gets to run. With
/// the volume at zero, ticks are felt as haptics instead. [bpm], [higher] and
/// [subdivisions] are persisted.
class MetronomeRepository extends ChangeNotifier {
  static const int minBpm = 20;

  static const int maxBpm = 250;

  static const Duration _scheduleAhead = Duration(milliseconds: 200);

  static const Duration _schedulerInterval = Duration(milliseconds: 50);

  /// Delay before the first tick, so it isn't already late when scheduled.
  static const Duration _startDelay = Duration(milliseconds: 50);

  MetronomeRepository._({
    required AudioEngineService audioEngine,
    required SharedPreferencesService sharedPreferences,
    required _Ticks ticks,
  }) : _audioEngine = audioEngine,
       _sharedPreferences = sharedPreferences,
       _ticks = ticks;

  final SharedPreferencesService _sharedPreferences;
  final AudioEngineService _audioEngine;
  final _Ticks _ticks;

  /// Create the repository, loading the tick sounds into the audio engine.
  static Future<MetronomeRepository> create({
    required SharedPreferencesService sharedPreferences,
    required AudioEngineService audioEngine,
  }) async {
    final ticks = await _Ticks.create(audioEngine: audioEngine);
    return MetronomeRepository._(
      audioEngine: audioEngine,
      sharedPreferences: sharedPreferences,
      ticks: ticks,
    );
  }

  /// Beats per minute, clamped between [minBpm] and [maxBpm].
  int get bpm => _bpm.value;
  set bpm(int value) => _bpm.value = value.clamp(minBpm, maxBpm);
  late final PersistentValue<int> _bpm =
      _sharedPreferences.value(
          "metronome/bpm",
          initialValue: 60,
        )
        ..addListener(_restart)
        ..addListener(notifyListeners);

  /// Beats per bar. The first beat of each bar is accented.
  int get higher => _higher.value;
  set higher(int value) => _higher.value = value;
  late final PersistentValue<int> _higher =
      _sharedPreferences.value(
          "metronome/higher",
          initialValue: 4,
        )
        ..addListener(_restart)
        ..addListener(notifyListeners);

  /// Ticks per beat, the first of which is the beat itself.
  int get subdivisions => _subdivisions.value;
  set subdivisions(int value) => _subdivisions.value = value;
  late final PersistentValue<int> _subdivisions =
      _sharedPreferences.value(
          "metronome/subdivisions",
          initialValue: 1,
        )
        ..addListener(_restart)
        ..addListener(notifyListeners);

  double get volume => volumeNotifier.value;
  set volume(double value) => volumeNotifier.value = value;
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0)
    ..addListener(notifyListeners);

  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? resume() : pause();
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  Duration get _beatDuration =>
      Duration(microseconds: 60e6 ~/ (bpm * subdivisions));

  _TickKind _tickKind(int count) => (count % (higher * subdivisions) == 0)
      ? _TickKind.accented
      : (count % subdivisions == 0)
      ? _TickKind.primary
      : _TickKind.subdivision;
  AudioSource _beatTick(int count) => switch (_tickKind(count)) {
    _TickKind.accented => _ticks.accented,
    _TickKind.primary => _ticks.primary,
    _TickKind.subdivision => _ticks.subdivision,
  };
  Duration _beatTime(int count) => _anchor + _beatDuration * count;

  /// The tick currently being heard. Negative before the first tick.
  int get _count {
    final Duration time = _audioEngine.getPlayheadTime() - _anchor;
    if (time.isNegative) return -1;
    return time.inMicroseconds ~/ _beatDuration.inMicroseconds;
  }

  /// The beat of the bar currently being heard, from `0` to [higher] - 1.
  int get beat => _beat;
  int _beat = 0;

  Duration _anchor = Duration.zero;

  final Map<int, SoundHandle> _scheduled = {};
  final Map<int, Timer> _haptics = {};
  Timer? _scheduler;

  void _schedule() {
    final Duration horizon = _audioEngine.getEngineTime() + _scheduleAhead;
    final int current = _count;

    // Schedule
    for (int count = current + 1; _beatTime(count) < horizon; count++) {
      // Sound
      if (_scheduled.containsKey(count)) continue;
      _scheduled[count] = _audioEngine.schedule(
        _beatTick(count),
        _beatTime(count),
        volume: volume,
      );

      // Haptics
      if (volume == 0) {
        _haptics[count] = Timer(
          _beatTime(count) - _audioEngine.getPlayheadTime(),
          () => _vibrate(count),
        );
      }
    }

    // Remove past
    _scheduled.removeWhere((count, handle) => count < current);
    _haptics.removeWhere((count, timer) => count < current);

    // Update [beat]
    if (current < 0) return;
    final int beat = (current ~/ subdivisions) % higher;
    if (beat != _beat) {
      _beat = beat;
      notifyListeners();
    }
  }

  Future<void> _vibrate(int count) => switch (_tickKind(count)) {
    _TickKind.accented => HapticFeedback.vibrate(),
    _TickKind.primary => HapticFeedback.heavyImpact(),
    _TickKind.subdivision => HapticFeedback.selectionClick(),
  };

  void resume() {
    if (isPlaying) return;
    _start();
    isPlayingNotifier.value = true;
  }

  void pause() {
    _stop();
    _beat = 0;
    isPlayingNotifier.value = false;
  }

  void _start() {
    _anchor = _audioEngine.getEngineTime() + _startDelay;
    _scheduler = Timer.periodic(_schedulerInterval, (_) => _schedule());
    _schedule();
  }

  void _stop() {
    _scheduler?.cancel();
    _scheduler = null;
    for (final handle in _scheduled.values) {
      _audioEngine.unschedule(handle);
    }
    _scheduled.clear();
    for (final timer in _haptics.values) {
      timer.cancel();
    }
    _haptics.clear();
  }

  /// Restart from the first beat, since the old tick grid no longer applies.
  void _restart() {
    if (!isPlaying) return;
    _stop();
    _beat = 0;
    _start();
  }

  @override
  Future<void> dispose() async {
    pause();
    isPlayingNotifier.dispose();
    volumeNotifier.dispose();
    await _ticks.dispose(audioEngine: _audioEngine);
    super.dispose();
  }
}
