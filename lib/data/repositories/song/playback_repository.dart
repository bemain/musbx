import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart' show AudioSource;
import 'package:meta/meta.dart';
import 'package:musbx/data/models/playback_state/playback_state.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/result.dart';

/// The song that is loaded, and everything the user can do to it while it
/// plays.
///
/// One song is loaded at a time. If it is loaded as parts, each is played as
/// its own sound and the whole set is driven through a single voice group, so
/// speed, pitch and seeking stay in lockstep; otherwise a single source is
/// played. Either way the audible state — [speed], [pitch], [loopSection], the
/// equalizer and the [parts] — is restored from the [SongPreferences] passed to
/// [load], and handed back by [readPreferences] for the caller to save.
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

  /// How many bands the equalizer is split into unless the song says otherwise.
  static const int equalizerDefaultNumBands = 5;

  /// The volume of a part that is left alone.
  static const double partDefaultVolume = 1.0;

  /// The parts that can be controlled without premium.
  static const List<Part> freeParts = [
    Part.vocals,
    Part.bass,
    Part.drums,
    Part.other,
  ];

  PlaybackRepository({
    required AudioEngineService audioEngine,
    required AudioSessionService audioSession,
  }) : _audioEngine = audioEngine,
       _audioSession = audioSession {
    _audioSessionEvents = _audioSession.eventStream.listen((event) {
      switch (event) {
        case AudioSessionEvent.pause || AudioSessionEvent.duck:
          _resumeAfterInterruption = isPlaying;
          pause();
        case AudioSessionEvent.resume || AudioSessionEvent.unduck:
          if (_resumeAfterInterruption) resume();
          _resumeAfterInterruption = false;
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
  late final StreamSubscription<AudioSessionEvent> _audioSessionEvents;

  /// Whether the song was playing when the current interruption began, so that
  /// its end does not start a song the user had paused.
  bool _resumeAfterInterruption = false;

  SongPartsGroup? _sound;
  PlaybackState? _state;

  /// Everything about the loaded song, or `null` when nothing is loaded.
  PlaybackState? get state => _state;

  /// The preferences the song was loaded with, which [readPreferences] builds
  /// on so that fields this repository does not own are kept.
  SongPreferences? _preferences;

  late final Timer _positionUpdater;

  /// The loaded song, or `null` when nothing is loaded.
  Song? get song => state?.song;

  /// Whether the loaded song is playing as separate parts rather than as one
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

      _updateState(
        equalizerGain: [..._state!.equalizerGain]..[band] = clamped,
      );
    }
  }

  /// The parts that have settings, or `null` when nothing is loaded.
  ///
  /// A song that is not loaded as parts still has settings for them, kept for
  /// when it is.
  Set<Part>? get parts => _state?.parts.keys.toSet();

  /// Whether [type] is heard, or `null` if it has no settings.
  bool? getPartEnabled(Part type) => _state?.parts[type]?.enabled;

  /// How loud [type] is, or `null` if it has no settings.
  double? getPartVolume(Part type) => _state?.parts[type]?.volume;

  /// Turn [type] on or off, or change its volume, leaving whatever is not
  /// specified alone.
  void setPart(Part type, {bool? enabled, double? volume}) => _updateState(
    parts: {
      ..._state!.parts,
      type: (
        enabled: enabled ?? _state!.parts[type]?.enabled ?? true,
        volume: volume ?? _state!.parts[type]?.volume ?? partDefaultVolume,
      ),
    },
  );

  /// Return everything the user can adjust to its default, and rewind to the
  /// start. The song stays loaded. Does nothing when no song is loaded.
  void reset() {
    if (_state == null) return;
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
      parts: {
        for (var type in Part.values)
          type: (enabled: true, volume: PlaybackRepository.partDefaultVolume),
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
    Map<Part, PartData>? parts,
  }) {
    if (song != null) {
      _state = PlaybackState(
        song: song,
        isPlaying: false,
        equalizerGain: List.filled(
          equalizerDefaultNumBands,
          equalizerDefaultGain,
        ),
      );
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
      parts: parts,
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

      if (parts != null) {
        for (var type in sound.parts) {
          final data = parts[type];
          if (data?.enabled ?? true) {
            _audioEngine.setPartVolume(
              _sound!,
              type,
              data?.volume ?? partDefaultVolume,
            );
          } else {
            _audioEngine.setPartVolume(_sound!, type, 0.0);
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

  /// Unload whatever is playing and load [song] paused, restoring
  /// [preferences] if given.
  ///
  /// [files] maps each part to its audio, or holds a single `null` entry to
  /// play the song as one sound.
  @useResult
  Future<Result<void>> load(
    Song song,
    Map<Part?, File> files, {
    SongPreferences? preferences,
  }) async {
    if (_sound != null) {
      if (await stop() case final Failure<void> failure) return failure;
    }

    final Map<Part?, AudioSource> sources = {};
    SongPartsGroup? created;
    try {
      for (final e in files.entries) {
        sources[e.key] = await _audioEngine.loadFile(e.value);
      }
      final SongPartsGroup sound = _audioEngine.createSound(sources);
      created = sound;

      _sound = sound;

      // Load preferences
      _preferences = preferences;
      preferences ??= SongPreferences();

      // Saved loop ends can lie past the end of the audio, which is shorter
      // when played as parts.
      final Duration length = _audioEngine.getDuration(sound);
      Duration? clampToLength(Duration? time) => switch (time) {
        null => null,
        _ when time.isNegative => Duration.zero,
        _ when time > length => length,
        _ => time,
      };
      final Duration? loopStart = clampToLength(preferences.loopStart);
      Duration? loopEnd = clampToLength(preferences.loopEnd);
      if (loopStart != null && loopEnd != null && loopEnd < loopStart) {
        loopEnd = loopStart;
      }

      _updateState(
        song: song,
        position: preferences.position,
        speed: preferences.speed?.clamp(0.5, 2.0),
        pitch: preferences.pitch?.clamp(-12, 12),
        loopSection: (start: loopStart, end: loopEnd),
        equalizerGain: List.generate(
          preferences.numEqualizerBands?.clamp(minNumBands, maxNumBands) ??
              equalizerDefaultNumBands,
          (i) => preferences?.equalizerGains?[i] ?? equalizerDefaultGain,
        ),
        parts: preferences.parts,
      );

      await _audioSession.setActive(true);
      return Result.ok(null);
    } catch (e, s) {
      _sound = null;
      _state = null;
      _preferences = null;
      await _release(created, sources.values);
      notifyListeners();
      return Result.failed(e, s);
    }
  }

  /// Free what a failed [load] got as far as creating, so that the next load
  /// starts from nothing.
  Future<void> _release(
    SongPartsGroup? sound,
    Iterable<AudioSource> sources,
  ) async {
    try {
      if (sound != null) {
        await _audioEngine.stop(sound);
      } else {
        await Future.wait(sources.map(_audioEngine.unload));
      }
    } catch (error) {
      debugPrint("[PLAYBACK] Releasing a failed load failed; $error");
    }
  }

  /// Stop and unload the current song, without saving its preferences.
  @useResult
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

  /// The loaded song's audible state and position, as preferences to save.
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
      parts: state?.parts ?? {},
    );
  }

  @override
  Future<void> dispose() async {
    if (await stop() case Failure(:final error)) {
      debugPrint("[PLAYBACK] Stopping on dispose failed; $error");
    }

    _positionUpdater.cancel();
    await _audioSessionEvents.cancel();

    super.dispose();
  }
}
