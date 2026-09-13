import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/models/media_command.dart';
import 'package:musbx/data/models/media_notification_state.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/audio_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/data/services/media_notification_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/result.dart';

typedef LoopSection = ({Duration? start, Duration? end});

class Stem extends ChangeNotifier {
  static const double defaultVolume = 1.0;

  Stem(this.type, this._playback);

  final StemType type;

  final PlaybackRepository _playback;

  SoundHandle? get _handle => _playback._handles[type];

  SoLoud get _soLoud => _playback._audioEngine.soLoud;

  bool get enabled => _playback._stemsState[type]?.enabled ?? true;
  set enabled(bool value) {
    _playback._stemsState[type] = (enabled: value, volume: _volume);

    if (_handle != null) {
      if (enabled) {
        _soLoud.setVolume(_handle!, _volume);
      } else {
        _soLoud.setVolume(_handle!, 0.0);
      }
    }

    notifyListeners();
  }

  double get _volume => _playback._stemsState[type]?.volume ?? 1.0;

  double get volume => _volume;
  set volume(double value) {
    _playback._stemsState[type] = (enabled: enabled, volume: value);

    if (enabled && _handle != null) _soLoud.setVolume(_handle!, _volume);

    notifyListeners();
  }
}

// TODO: Keep all song state in a struct
class PlaybackRepository extends ChangeNotifier {
  /// The minimum number of frequency bands.
  static const int minNumBands = 4;

  /// The maximum number of frequency bands.
  static const int maxNumBands = 15;

  /// The minimum value for the [gain].
  static const double equalizerMinGain = 0.0;

  /// The maximum value for the [gain].
  ///
  /// [SoLoud] technically allows values up to 4.0, but too high values makes
  /// the audio very distorted.
  static const double equalizerMaxGain = 2.0;

  static const double equalizerDefaultGain = 1.0;

  /// The stems that are available on the free version of the app.
  static const List<StemType> freeStems = [
    StemType.vocals,
    StemType.bass,
    StemType.drums,
    StemType.other,
  ];

  PlaybackRepository({
    required AudioRepository audio,
    required AudioEngineService audioEngine,
    required AudioSessionService audioSession,
    required SongPreferencesRepository songPreferences,
    required MediaNotificationService mediaNotification,
  }) : _audio = audio,
       _audioEngine = audioEngine,
       _audioSession = audioSession,
       _songPreferences = songPreferences,
       _mediaNotification = mediaNotification {
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
        if (!isPlaying || _groupHandle == null) return;

        final position = _audioEngine.soLoud.getPosition(_groupHandle!);

        if ((loopSection.start != null && position < loopSection.start!) ||
            (loopSection.end != null && position > loopSection.end!)) {
          seek(loopSection.start ?? Duration.zero);
        } else {
          positionNotifier.value = _clamp(position);
        }
      },
    );

    if (_mediaNotification.isEnabled) {
      _mediaNotification.commands.listen(
        (command) => switch (command) {
          Play() => resume(),
          Pause() => pause(),
          Stop() => unload(),
          Seek(:final position) => seek(position),
        },
      );

      addListener(() {
        _mediaNotification.update(
          song == null
              ? null
              : MediaNotificationState(
                  id: song!.id,
                  title: song!.title,
                  artist: song!.artist,
                  album: song!.album,
                  genre: song!.genre,
                  artUri: song!.artUri,
                  duration: duration,
                  isPlaying: isPlaying,
                  position: position,
                  speed: speed,
                ),
        );
      });
    }
  }

  final AudioRepository _audio;
  final AudioEngineService _audioEngine;
  final AudioSessionService _audioSession;
  final SongPreferencesRepository _songPreferences;
  final MediaNotificationService _mediaNotification;

  // TODO: Remove once we introduce 'provider'.
  static late final PlaybackRepository instance;
  static Future<void> initialize() async {
    instance = PlaybackRepository(
      audio: AudioRepository.instance,
      audioEngine: AudioEngineService.instance,
      audioSession: AudioSessionService.instance,
      songPreferences: SongPreferencesRepository.instance,
      mediaNotification: MediaNotificationService.instance,
    );
  }

  Song? get song => _song;
  Song? _song;

  Map<StemType?, AudioSource> _sources = {};
  Map<StemType?, SoundHandle> _handles = {};

  SoundHandle? _groupHandle;

  SongPreferences? _preferences;

  late final Timer _positionUpdater;

  bool get isMulti => _handles.length > 1;

  Duration? get duration => _sources.isEmpty
      ? null
      : _audioEngine.soLoud.getLength(_sources.values.first);

  bool get isPlaying => isPlayingNotifier.value;
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  void pause() {
    if (_groupHandle == null) return;

    _audioEngine.soLoud.setPause(_groupHandle!, true);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  Future<void> resume() async {
    if (_groupHandle == null) return;

    // Make sure we are inside the [loopSection], in case it has changed
    seek(position);
    _audioEngine.soLoud.setPause(_groupHandle!, false);
    isPlayingNotifier.value = true;
    await _audioSession.setActive(true);
  }

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

  void seek(Duration position) {
    position = _clamp(position);

    _handles.forEach((stem, handle) {
      _audioEngine.soLoud.seek(handle, position);
    });

    positionNotifier.value = position;
  }

  double _speed = 1.0;
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    if (_groupHandle != null) {
      _audioEngine.soLoud.setRelativePlaySpeed(_groupHandle!, value);
    }
    notifyListeners();
    _setPitch();
  }

  double _pitch = 0.0;
  double get pitch => _pitch;
  set pitch(double value) {
    _pitch = value;
    _setPitch();
    notifyListeners();
  }

  void _setPitch() {
    for (final stem in _sources.keys) {
      _sources[stem]?.filters.pitchShiftFilter
              .semitones(soundHandle: _handles[stem])
              .value =
          pitch - 12 * (log(speed) / ln2);
    }
  }

  LoopSection get loopSection => _loopSection;
  LoopSection _loopSection = (start: null, end: null);

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

  int? get numEqualizerBands => _sources
      .values
      .firstOrNull
      ?.filters
      .parametricEqFilter
      .numBands(soundHandle: _handles.values.first)
      .value
      .toInt();

  double? getBandGain(int band) {
    final bands = numEqualizerBands;
    if (bands == null || band >= bands) return null;

    return _sources.values.first.filters.parametricEqFilter
        .bandGain(band, soundHandle: _handles.values.first)
        .value;
  }

  void setBandGain(int band, double gain) {
    final bands = numEqualizerBands;
    if (bands == null || band >= bands) return;

    _sources.forEach((type, source) {
      source.filters.parametricEqFilter
          .bandGain(band, soundHandle: _handles[type])
          .value = gain.clamp(
        equalizerMinGain,
        equalizerMaxGain,
      );
    });
    notifyListeners();
  }

  Map<StemType, ({bool enabled, double volume})> _stemsState = {};

  late final Map<StemType, Stem> stems = Map.fromIterables(
    StemType.values,
    StemType.values.map(
      (type) => Stem(type, this)..addListener(notifyListeners),
    ),
  );

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

  Future<Result<void>> load(Song song) async {
    // Unload previous song
    if (await unload() case Failure(:final error)) {
      debugPrint("[SONGS] Unloading song failed; $error");
    }

    try {
      final AudioSource source = (await _audio.resolve(song)).asOk;
      final stems = await DemixRepository.instance.stemsFor(song);

      final Map<StemType?, AudioSource> sources;
      if (stems != null) {
        // Load stems
        sources = {
          for (final e in stems.entries)
            e.key: await _audioEngine.soLoud.loadFile(e.value.path),
        };
        await _audioEngine.soLoud.disposeSource(source);
      } else {
        sources = {null: source};
      }

      // Activate filters. This needs to be done before the sound is played.
      sources.forEach((stem, source) {
        for (var filter in [
          source.filters.pitchShiftFilter,
          source.filters.parametricEqFilter,
        ]) {
          if (!filter.isActive) filter.activate();
        }
      });

      // Play sounds
      final Map<StemType?, SoundHandle> handles = {
        for (final e in sources.entries)
          e.key: _audioEngine.soLoud.play(
            e.value,
            paused: true,
            looping: true,
          ),
      };

      // Create group
      final SoundHandle groupHandle = _audioEngine.soLoud.createVoiceGroup();
      if (groupHandle.isError) {
        throw Exception("Failed to create voice group");
      }

      _audioEngine.soLoud.addVoicesToGroup(
        groupHandle,
        handles.values.toList(),
      );

      _preferences = (await _songPreferences.read(song)).asOk;

      _sources = sources;
      _handles = handles;
      _groupHandle = groupHandle;
      _song = song;

      _loadPreferences(_preferences);

      notifyListeners();

      await _audioSession.setActive(true);

      return Result.ok(null);
    } catch (e, s) {
      // TODO: Dispose handles already played
      debugPrint("[SONGS] Loading song failed; $e");
      return Result.failed(e, s);
    }
  }

  Future<Result<void>> unload() async {
    try {
      final song = _song;
      final prefs = _readPreferences(_preferences);

      reset();
      await _audioSession.setActive(false);

      await Future.wait([
        for (var handle in _handles.values) _audioEngine.soLoud.stop(handle),
        for (var source in _sources.values)
          _audioEngine.soLoud.disposeSource(source),
      ]);

      if (_groupHandle != null) {
        _audioEngine.soLoud.destroyVoiceGroup(_groupHandle!);
      }

      _sources = {};
      _handles = {};
      _groupHandle = null;

      _song = null;
      _preferences = null;

      if (song != null) {
        // Save preferences
        (await _songPreferences.write(song, prefs)).asOk;
      }

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

    if (prefs.numEqualizerBands != null) {
      _sources.forEach((stem, source) {
        source.filters.parametricEqFilter
            .numBands(soundHandle: _handles[stem])
            .value = prefs!.numEqualizerBands!
            .clamp(minNumBands, maxNumBands)
            .toDouble();
      });
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

  SongPreferences _readPreferences(SongPreferences? prefs) {
    final Map<int, double> gains = {};
    for (int band = 0; band < (numEqualizerBands ?? 0); band++) {
      final gain = getBandGain(band);
      if (gain != null) gains[band] = gain;
    }

    return (prefs ?? SongPreferences()).copyWith(
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
    await unload();

    _positionUpdater.cancel();

    super.dispose();
  }
}
