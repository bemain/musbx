import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/playback_state/playback_state.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/result.dart';

/// The song that is loaded, and everything the user can do to it while it
/// plays.
///
/// One song is loaded at a time. If it has been demixed, each stem is played as
/// its own sound and the whole set is driven through a single voice group, so
/// speed, pitch and seeking stay in lockstep; otherwise a single source is
/// played. Either way the audible state — [speed], [pitch], [loopSection], the
/// equalizer and the [stems] — is read from that song's [SongPreferences] on
/// [load] and written back on [stop].
class PlaybackRepository extends ChangeNotifier {
  /// The minimum number of frequency bands.
  static const int minNumBands = 4;

  /// The maximum number of frequency bands.
  static const int maxNumBands = 15;

  /// The lowest gain an equalizer band can be set to.
  static const double equalizerMinGain = 0.0;

  /// The highest gain an equalizer band can be set to.
  ///
  /// SoLoud technically allows values up to 4.0, but too high values make the
  /// audio very distorted.
  static const double equalizerMaxGain = 2.0;

  /// The gain of a band that is left alone.
  static const double equalizerDefaultGain = 1.0;

  static const int equalizerDefaultNumBands = 3;

  static const double stemDefaultVolume = 1.0;

  /// The stems that can be controlled without premium.
  static const List<StemType> freeStems = [
    StemType.vocals,
    StemType.bass,
    StemType.drums,
    StemType.other,
  ];

  PlaybackRepository({
    required AudioEngineService audioEngine,
    required AudioSessionService audioSession,
  }) : _audioEngine = audioEngine,
       _audioSession = audioSession {
    _audioSession.eventStream.listen((event) {
      switch (event) {
        case AudioSessionEvent.resume || AudioSessionEvent.unduck:
          resume();
        case AudioSessionEvent.pause || AudioSessionEvent.duck:
          pause();
      }
    });

    _positionUpdater = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!isPlaying || _sound == null) return;

        final position = _audioEngine.getPosition(_sound!);

        if ((loopSection?.start != null && position < loopSection!.start!) ||
            (loopSection?.end != null && position > loopSection!.end!)) {
          seek(loopSection!.start ?? Duration.zero);
        } else {
          positionNotifier.value = _clamp(position);
        }
      },
    );
  }

  final AudioEngineService _audioEngine;
  final AudioSessionService _audioSession;

  SoundGroup? _sound;
  PlaybackState? _state;
  PlaybackState? get state => _state;

  SongPreferences? _preferences;

  late final Timer _positionUpdater;

  Song? get song => state?.song;

  /// Whether the loaded song is playing as separate stems rather than as one
  /// sound.
  bool get isMulti => (_sound?.handles.length ?? 0) > 1;

  /// How long the loaded song is, or `null` when nothing is loaded.
  Duration? get duration =>
      _sound == null ? null : _audioEngine.getDuration(_sound!);

  /// Whether the song is currently being played.
  bool get isPlaying => state?.isPlaying ?? false;

  /// Pause playback, keeping the song loaded.
  void pause() {
    if (_sound == null) return;

    _audioEngine.pause(_sound!);
    _updateState(isPlaying: false);
    notifyListeners();
  }

  /// Resume playback.
  Future<void> resume() async {
    if (_sound == null) return;

    // Make sure we are inside the [loopSection], in case it has changed
    seek(position);
    _audioEngine.resume(_sound!);
    _updateState(isPlaying: true);
    await _audioSession.setActive(true);
    notifyListeners();
  }

  /// How far into the song playback has come.
  ///
  /// Polled from the engine while playing, and always inside [loopSection].
  Duration get position => positionNotifier.value;
  set position(Duration value) => positionNotifier.value = value;
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  Duration _clamp(Duration position) {
    if (loopSection?.start != null && position < loopSection!.start!) {
      return loopSection!.start!;
    }
    if (loopSection?.end != null && position > loopSection!.end!) {
      return loopSection!.end!;
    }
    return position;
  }

  /// Jump to [position], clamped into [loopSection].
  void seek(Duration position) {
    position = _clamp(position);
    _updateState(position: position);
    positionNotifier.value = position;
  }

  /// How fast the song is played, as a fraction of its original tempo.
  ///
  /// Changing this does not change the perceived pitch: [pitch] is re-applied to
  /// cancel out the shift that the rate change would otherwise cause.
  double? get speed => state?.speed;
  set speed(double value) => _updateState(speed: value);

  /// How many semitones the song is transposed, independently of [speed].
  double? get pitch => state?.pitch;
  set pitch(double value) => _updateState(pitch: value);

  /// The section playback is confined to. Playback jumps back to its start on
  /// reaching its end.
  LoopSection? get loopSection => state?.loopSection;

  /// Move one or both ends of [loopSection], leaving the unspecified end alone.
  ///
  /// An end before the start is pushed up to it, and the [position] is pulled
  /// into the new section.
  void setLoopSection({Duration? start, Duration? end}) {
    start ??= loopSection?.start;
    end ??= loopSection?.end;

    if (start != null && end != null && end < start) end = start;

    _updateState(loopSection: (start: start, end: end));

    if ((start != null && position < start) ||
        (end != null && position > end)) {
      positionNotifier.value = _clamp(position);
    }
  }

  /// How many bands the equalizer is split into, or `null` when nothing is
  /// loaded.
  int? get numEqualizerBands => _state?.equalizerGain.length;

  /// The gain of an equalizer [band], or `null` if there is no such band.
  double? getBandGain(int band) {
    if (numEqualizerBands case final bands? when band < bands) {
      return _state?.equalizerGain[band] ?? equalizerDefaultGain;
    }
    return null;
  }

  /// Set the gain of an equalizer [band], clamped between [equalizerMinGain] and
  /// [equalizerMaxGain]. Does nothing if there is no such band.
  void setBandGain(int band, double gain) {
    if (numEqualizerBands case final bands? when band < bands) {
      // TODO: Move to ViewModel?
      final double clamped = gain.clamp(equalizerMinGain, equalizerMaxGain);
      final gains = _state!.equalizerGain;
      gains[band] = clamped;

      _updateState(equalizerGain: gains);
    }
  }

  Set<StemType>? get stems => _state?.stems.keys.toSet();

  bool? getStemEnabled(StemType type) => _state?.stems[type]?.enabled;
  double? getStemVolume(StemType type) => _state?.stems[type]?.volume;

  void setStem(StemType type, {bool? enabled, double? volume}) => _updateState(
    stems: {
      ..._state!.stems,
      type: (
        enabled: enabled ?? _state!.stems[type]?.enabled ?? true,
        volume: volume ?? _state!.stems[type]?.volume ?? stemDefaultVolume,
      ),
    },
  );

  /// Return everything the user can adjust to its default, and rewind to the
  /// start. The song stays loaded.
  void reset() {
    _updateState(
      isPlaying: false,
      position: Duration.zero,
      speed: 1.0,
      pitch: 0.0,
      loopSection: (start: null, end: null),
      equalizerGain: List.generate(
        _state!.equalizerGain.length,
        (_) => equalizerDefaultGain,
      ),
      stems: {
        for (var type in StemType.values)
          type: (enabled: true, volume: PlaybackRepository.stemDefaultVolume),
      },
    );
  }

  void _updateState({
    Song? song,
    bool? isPlaying,
    Duration? position,
    double? speed,
    double? pitch,
    LoopSection? loopSection,
    List<double>? equalizerGain,
    Map<StemType, StemData>? stems,
  }) {
    if (song != null) {
      _state = PlaybackState(song: song, isPlaying: false);
      reset();
    }

    if (state == null) return;
    _state = state?.copyWith(
      song: song,
      isPlaying: isPlaying,
      position: position,
      speed: speed,
      pitch: pitch,
      loopSection: loopSection,
      equalizerGain: equalizerGain,
      stems: stems,
    );

    if (_sound case final sound?) {
      if (speed != null) _audioEngine.setSpeed(sound, speed);
      if (pitch != null || speed != null) {
        _audioEngine.setPitch(sound, pitch ?? this.pitch!);
      }

      if (equalizerGain != null) {
        _audioEngine.setNumBands(sound, equalizerGain.length);
        equalizerGain.asMap().forEach((band, gain) {
          _audioEngine.setBandGain(_sound!, band, gain);
        });
      }

      if (stems != null) {
        for (var type in sound.handles.keys) {
          final data = stems[type];
          if (data?.enabled ?? true) {
            _audioEngine.setStemVolume(
              _sound!,
              type,
              data?.volume ?? stemDefaultVolume,
            );
          } else {
            _audioEngine.setStemVolume(_sound!, type, 0.0);
          }
        }
      }

      if (position != null) _audioEngine.seek(_sound!, position);

      switch (isPlaying) {
        case true:
          _audioEngine.resume(sound);
        case false:
          _audioEngine.pause(sound);
        case null:
      }
    }

    notifyListeners();
  }

  /// Unload whatever is playing and load [song], paused at wherever it was left
  /// off.
  ///
  /// Plays the demixed stems if the cache holds all of them, and the song as one
  /// sound otherwise.
  @useResult
  Future<Result<void>> load(
    Song song,
    Map<StemType?, File> files, {
    SongPreferences? preferences,
  }) async {
    if (_sound != null) await stop();

    try {
      final sources = {
        for (final e in files.entries)
          e.key: await _audioEngine.loadFile(e.value),
      };
      final SoundGroup sound = _audioEngine.createSound(sources);

      _sound = sound;

      // Load preferences
      _preferences = preferences;
      preferences ??= SongPreferences();
      _updateState(
        song: song,
        position: preferences.position,
        speed: preferences.speed?.clamp(0.5, 2.0),
        pitch: preferences.pitch?.clamp(-12, 12),
        loopSection: (start: preferences.loopStart, end: preferences.loopEnd),
        equalizerGain: List.generate(
          preferences.numEqualizerBands?.clamp(minNumBands, maxNumBands) ??
              equalizerDefaultNumBands,
          (i) => preferences?.equalizerGains?[i] ?? equalizerDefaultGain,
        ),
        stems: preferences.stems,
      );

      await _audioSession.setActive(true);
      return Result.ok(null);
    } catch (e, s) {
      // TODO: Dispose handles already played
      return Result.failed(e, s);
    }
  }

  /// Stop and unload the current song.
  /// TODO: Should I mark all functions that return Result with @useResult?
  Future<Result<void>> stop() async {
    try {
      reset();
      await _audioSession.setActive(false);

      if (_sound != null) await _audioEngine.stop(_sound!);

      _sound = null;
      _state = null;
      _preferences = null;

      notifyListeners();

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  SongPreferences readPreferences() {
    final Map<int, double> gains = {};
    for (int band = 0; band < (numEqualizerBands ?? 0); band++) {
      final gain = getBandGain(band);
      if (gain != null) gains[band] = gain;
    }

    return (_preferences ?? SongPreferences()).copyWith(
      position: position,
      speed: speed,
      pitch: pitch,
      loopStart: loopSection?.start,
      loopEnd: loopSection?.end,
      numEqualizerBands: numEqualizerBands,
      equalizerGains: gains,
      stems: state?.stems ?? {},
    );
  }

  @override
  Future<void> dispose() async {
    await stop();

    _positionUpdater.cancel();

    super.dispose();
  }
}
