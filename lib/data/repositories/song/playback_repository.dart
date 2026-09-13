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

  SoundHandle? get _handle => _playback._handles[type];

  SoLoud get _soLoud => _playback._audioEngine.soLoud;

  /// Whether this stem is heard. A disabled stem is silenced rather than
  /// unloaded, so it keeps its [volume].
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

  /// How loud this stem is relative to the others, between `0.0` and `1.0`.
  double get volume => _volume;
  set volume(double value) {
    _playback._stemsState[type] = (enabled: enabled, volume: value);

    if (enabled && _handle != null) _soLoud.setVolume(_handle!, _volume);

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
/// [load] and written back on [unload].
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
    required AudioRepository audio,
    required AudioEngineService audioEngine,
    required AudioSessionService audioSession,
    required SongPreferencesRepository songPreferences,
    required MediaNotificationService mediaNotification,
    required DemixRepository demix,
  }) : _audio = audio,
       _audioEngine = audioEngine,
       _audioSession = audioSession,
       _songPreferences = songPreferences,
       _mediaNotification = mediaNotification,
       _demix = demix {
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
  final DemixRepository _demix;

  Song? get song => _song;
  Song? _song;

  Map<StemType?, AudioSource> _sources = {};
  Map<StemType?, SoundHandle> _handles = {};

  SoundHandle? _groupHandle;

  SongPreferences? _preferences;

  late final Timer _positionUpdater;

  /// Whether the loaded song is playing as separate stems rather than as one
  /// sound.
  bool get isMulti => _handles.length > 1;

  /// How long the loaded song is, or `null` when nothing is loaded.
  Duration? get duration => _sources.isEmpty
      ? null
      : _audioEngine.soLoud.getLength(_sources.values.first);

  /// Whether the song is currently being played.
  bool get isPlaying => isPlayingNotifier.value;
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  /// Pause playback, keeping the song loaded.
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

    _handles.forEach((stem, handle) {
      _audioEngine.soLoud.seek(handle, position);
    });

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
    if (_groupHandle != null) {
      _audioEngine.soLoud.setRelativePlaySpeed(_groupHandle!, value);
    }
    notifyListeners();
    _setPitch();
  }

  double _pitch = 0.0;

  /// How many semitones the song is transposed, independently of [speed].
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
  int? get numEqualizerBands => _sources
      .values
      .firstOrNull
      ?.filters
      .parametricEqFilter
      .numBands(soundHandle: _handles.values.first)
      .value
      .toInt();

  /// The gain of an equalizer [band], or `null` if there is no such band.
  double? getBandGain(int band) {
    final bands = numEqualizerBands;
    if (bands == null || band >= bands) return null;

    return _sources.values.first.filters.parametricEqFilter
        .bandGain(band, soundHandle: _handles.values.first)
        .value;
  }

  /// Set the gain of an equalizer [band], clamped between [equalizerMinGain] and
  /// [equalizerMaxGain]. Does nothing if there is no such band.
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
  Future<Result<void>> load(Song song) async {
    // Unload previous song
    if (await unload() case Failure(:final error)) {
      debugPrint("[SONGS] Unloading song failed; $error");
    }

    try {
      final AudioSource source = (await _audio.resolve(song)).asOk;
      final stems = await _demix.stemsFor(song);

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

  /// Stop and unload the current song, saving its preferences on the way out.
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
