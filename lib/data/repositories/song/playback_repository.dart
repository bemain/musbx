import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/result.dart';

/// The part of a song that playback is confined to. A `null` end is the end of
/// the song, a `null` start its beginning.
typedef LoopSection = ({Duration? start, Duration? end});

/// One separated instrument of the song that is loaded, as the user controls it.
///
/// Exists whether or not the song has been demixed; when it has not, changing
/// it has no audible effect but is still remembered.
class Stem extends ChangeNotifier {
  static const double defaultVolume = 1.0;

  Stem(this.type, this._playback);

  /// Which instrument this stem holds.
  final StemType type;

  final PlaybackRepository _playback;

  SoundGroup? get _sound => _playback._sound;

  AudioEngineService get _audioEngine => _playback._audioEngine;

  /// Whether this stem is heard. A disabled stem is silenced rather than
  /// unloaded, so it keeps its [volume].
  bool get enabled => _playback._stemsState[type]?.enabled ?? true;
  set enabled(bool value) {
    _playback._stemsState[type] = (enabled: value, volume: _volume);

    if (_sound != null) {
      if (enabled) {
        _audioEngine.setStemVolume(_sound!, type, _volume);
      } else {
        _audioEngine.setStemVolume(_sound!, type, 0.0);
      }
    }

    notifyListeners();
  }

  double get _volume => _playback._stemsState[type]?.volume ?? 1.0;

  /// How loud this stem is relative to the others, between `0.0` and `1.0`.
  double get volume => _volume;
  set volume(double value) {
    _playback._stemsState[type] = (enabled: enabled, volume: value);

    if (enabled && _sound != null) {
      _audioEngine.setStemVolume(_sound!, type, _volume);
    }
    notifyListeners();
  }
}

// TODO: Keep all song state in a struct
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

        if ((loopSection.start != null && position < loopSection.start!) ||
            (loopSection.end != null && position > loopSection.end!)) {
          seek(loopSection.start ?? Duration.zero);
        } else {
          positionNotifier.value = _clamp(position);
        }
      },
    );
  }

  final AudioEngineService _audioEngine;
  final AudioSessionService _audioSession;

  Song? get song => _song;
  Song? _song;

  SoundGroup? _sound;

  SongPreferences? _preferences;

  late final Timer _positionUpdater;

  /// Whether the loaded song is playing as separate stems rather than as one
  /// sound.
  bool get isMulti => (_sound?.handles.length ?? 0) > 1;

  /// How long the loaded song is, or `null` when nothing is loaded.
  Duration? get duration =>
      _sound == null ? null : _audioEngine.getDuration(_sound!);

  /// Whether the song is currently being played.
  bool get isPlaying => isPlayingNotifier.value;
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  /// Pause playback, keeping the song loaded.
  void pause() {
    if (_sound == null) return;

    _audioEngine.pause(_sound!);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  Future<void> resume() async {
    if (_sound == null) return;

    // Make sure we are inside the [loopSection], in case it has changed
    seek(position);
    _audioEngine.resume(_sound!);
    isPlayingNotifier.value = true;
    await _audioSession.setActive(true);
  }

  /// How far into the song playback has come.
  ///
  /// Polled from the engine while playing, and always inside [loopSection].
  Duration get position => positionNotifier.value;
  set position(Duration value) => positionNotifier.value = value;
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  Duration _clamp(Duration position) {
    if (loopSection.start != null && position < loopSection.start!) {
      return loopSection.start!;
    }
    if (loopSection.end != null && position > loopSection.end!) {
      return loopSection.end!;
    }
    return position;
  }

  /// Jump to [position], clamped into [loopSection].
  void seek(Duration position) {
    position = _clamp(position);

    if (_sound != null) _audioEngine.seek(_sound!, position);

    positionNotifier.value = position;
  }

  double _speed = 1.0;

  /// How fast the song is played, as a fraction of its original tempo.
  ///
  /// Changing this does not change the perceived pitch: [pitch] is re-applied to
  /// cancel out the shift that the rate change would otherwise cause.
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    if (_sound != null) {
      _audioEngine.setSpeed(_sound!, value);
      _audioEngine.setPitch(_sound!, _pitch);
    }
    notifyListeners();
  }

  double _pitch = 0.0;

  /// How many semitones the song is transposed, independently of [speed].
  double get pitch => _pitch;
  set pitch(double value) {
    _pitch = value;
    if (_sound != null) _audioEngine.setPitch(_sound!, value);
    notifyListeners();
  }

  /// The section playback is confined to. Playback jumps back to its start on
  /// reaching its end.
  LoopSection get loopSection => _loopSection;
  LoopSection _loopSection = (start: null, end: null);

  /// Move one or both ends of [loopSection], leaving the unspecified end alone.
  ///
  /// An end before the start is pushed up to it, and the [position] is pulled
  /// into the new section.
  void setLoopSection({Duration? start, Duration? end}) {
    start ??= loopSection.start;
    end ??= loopSection.end;

    if (start != null && end != null && end < start) end = start;

    _loopSection = (
      start: start,
      end: end,
    );

    if ((start != null && position < start) ||
        (end != null && position > end)) {
      positionNotifier.value = _clamp(position);
    }
    notifyListeners();
  }

  /// How many bands the equalizer is split into, or `null` when nothing is
  /// loaded.
  int? get numEqualizerBands =>
      _sound == null ? null : _audioEngine.getNumBands(_sound!);

  /// The gain of an equalizer [band], or `null` if there is no such band.
  double? getBandGain(int band) {
    final bands = numEqualizerBands;
    if (bands == null || band >= bands) return null;

    return _audioEngine.getBandGain(_sound!, band);
  }

  /// Set the gain of an equalizer [band], clamped between [equalizerMinGain] and
  /// [equalizerMaxGain]. Does nothing if there is no such band.
  void setBandGain(int band, double gain) {
    final bands = numEqualizerBands;
    if (bands == null || band >= bands) return;

    _audioEngine.setBandGain(
      _sound!,
      band,
      gain.clamp(equalizerMinGain, equalizerMaxGain),
    );
    notifyListeners();
  }

  Map<StemType, ({bool enabled, double volume})> _stemsState = {};

  /// Every stem, whether or not the loaded song has been demixed.
  late final Map<StemType, Stem> stems = Map.fromIterables(
    StemType.values,
    StemType.values.map(
      (type) => Stem(type, this)..addListener(notifyListeners),
    ),
  );

  /// Return everything the user can adjust to its default, and rewind to the
  /// start. The song stays loaded.
  void reset() {
    pause();
    _speed = 1.0;
    _pitch = 0.0;
    _loopSection = (start: null, end: null);
    if (numEqualizerBands != null) {
      for (int band = 0; band < numEqualizerBands!; band++) {
        setBandGain(band, 1.0);
      }
    }
    _stemsState = {};

    seek(Duration.zero);
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
    try {
      final sources = {
        for (final e in files.entries)
          e.key: await _audioEngine.loadFile(e.value),
      };
      final SoundGroup sound = _audioEngine.play(sources);

      _sound = sound;
      _song = song;
      _preferences = preferences;

      _loadPreferences(preferences);

      notifyListeners();
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
      _song = null;
      _preferences = null;

      notifyListeners();

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  void _loadPreferences(SongPreferences? prefs) {
    prefs ??= SongPreferences();

    if (prefs.speed != null) speed = prefs.speed!.clamp(0.5, 2.0);
    if (prefs.pitch != null) pitch = prefs.pitch!.clamp(-12, 12);

    _loopSection = (start: prefs.loopStart, end: prefs.loopEnd);

    seek(prefs.position ?? Duration.zero);

    if (prefs.numEqualizerBands != null && _sound != null) {
      _audioEngine.setNumBands(
        _sound!,
        prefs.numEqualizerBands!.clamp(minNumBands, maxNumBands),
      );
    }
    prefs.equalizerGains?.forEach(setBandGain);

    _stemsState = Map<StemType, ({bool enabled, double volume})>.from(
      prefs.stems ?? {},
    );
    prefs.stems?.forEach((type, stem) {
      stems[type]?.enabled = stem.enabled;
      stems[type]?.volume = stem.volume;
    });
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
      loopStart: loopSection.start,
      loopEnd: loopSection.end,
      numEqualizerBands: numEqualizerBands,
      equalizerGains: gains,
      stems: _stemsState,
    );
  }

  @override
  Future<void> dispose() async {
    await stop();

    _positionUpdater.cancel();

    super.dispose();
  }
}
