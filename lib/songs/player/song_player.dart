import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/songs/analyzer/analyzer.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/loop/loop.dart';
import 'package:musbx/songs/player/audio_handler.dart';
import 'package:musbx/songs/player/filter.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/slowdowner/slowdowner.dart';
import 'package:musbx/utils/utils.dart';

abstract class SongPlayerComponent<T extends SongPlayer>
    extends ChangeNotifier {
  SongPlayerComponent(this.player);

  /// The player that this is a part of.
  final T player;

  /// Initialize and activate this component.
  ///
  /// Called when the [player] is created.
  Future<void> initialize() async {}

  /// Free the resources used by this component.
  ///
  /// Called when the [player] that this is part of disposed.
  @override
  @mustCallSuper
  FutureOr<void> dispose() async {
    super.dispose();
  }

  /// Load preferences for a song from a [json] map.
  ///
  /// Called when a song that has preferences saved is loaded.
  ///
  /// Implementations should be able to handle a value being null,
  /// and never expect a specific key to exist.
  ///
  /// If any values were changed, this should call [notifyListeners].
  @mustCallSuper
  void loadPreferencesFromJson(Json json) {}

  /// Save settings for a song to a json map.
  @mustCallSuper
  Json savePreferencesToJson() {
    return {};
  }
}

/// A
abstract class SongPlayer extends ChangeNotifier {
  static final SoLoud soloud = SoLoud.instance;

  SongPlayer._(this.song, this.handle) {
    _positionUpdater = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!isPlaying) return;
        position = soloud.getPosition(handle);
      },
    );

    // Initialize components
    for (final SongPlayerComponent component in components) {
      component.initialize();
    }
  }

  /// Create a [SongPlayer] by loading a [song].
  ///
  /// This delegates the loading process to the correct implementation of this
  /// abstract class, depending on if the [song] is demixed or not.
  ///
  /// The loading generally goes as follows:
  ///  - Load the [song.source], to obtain an [AudioSource].
  ///  - Play the [AudioSource], to obtain a sound [handle].
  ///  - Load the user's preferences for this [song].
  static Future<SongPlayer> load(Song song) async {
    return (await song.isDemixed)
        ? MultiPlayer.load(song)
        : SinglePlayer.load(song);
  }

  /// The song that this player plays.
  final Song song;

  /// Handle for the sound that is playing.
  final SoundHandle handle;

  /// Whether the player is currently playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? resume() : pause();
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  /// Pause playback.
  void pause() {
    soloud.setPause(handle, true);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  Future<void> resume() async {
    soloud.setPause(handle, false);
    isPlayingNotifier.value = true;
    await SongsAudioHandler.session.setActive(true);
  }

  /// Stop playback, and free the resources used by this player.
  ///
  /// See also [SongPlayerComponent.dispose].
  @mustCallSuper
  @override
  Future<void> dispose() async {
    isPlayingNotifier.value = false;

    await SongsAudioHandler.session.setActive(false);

    _positionUpdater.cancel();

    // Save preferences
    song.preferences = toPreferences();

    for (SongPlayerComponent component in components) {
      await component.dispose();
    }

    super.dispose();
  }

  /// The duration of the audio that is playing.
  Duration get duration;

  /// Timer responsible for periodically making sure [position] matches with the
  /// actual position of the audio.
  late final Timer _positionUpdater;

  /// The current position of the player.
  ///
  /// Note that changes to this value are not actually applied, so you are
  /// required to call [seek] for the change to take effect. This is intentional,
  /// as it allows us to update the [position] very frequently without actually
  /// seeking in the audio source, which could freeze the main thread.
  Duration get position => positionNotifier.value;
  set position(Duration value) => positionNotifier.value = value;
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// Seek to a [position] in the current song.
  ///
  /// Note that this should not be called too often, as it could block the main
  /// thread and cause the app to freeze. For frequent position updates, instead
  /// set the [position] value continously, and only [seek] once at the end.
  void seek(Duration position) {
    position = loop.clamp(position);
    soloud.seek(handle, position);
    positionNotifier.value = position;
    notifyListeners();
  }

  /// Get the filters for this audio.
  ///
  /// A [handle] can optionally be passed to get the filter of a specific song.
  Filters get filters;

  /// The components that extend the functionality of this player.
  @mustCallSuper
  List<SongPlayerComponent> get components =>
      List.unmodifiable([slowdowner, equalizer, analyzer, loop]);

  /// Component for changing the pitch and speed of the song.
  late final SlowdownerComponent slowdowner = SlowdownerComponent(this);

  /// Component for adjusting the gain for different frequency bands of the song.
  late final EqualizerComponent equalizer = EqualizerComponent(this);

  /// Component for analyzing the current song, including chord identification and waveform extraction.
  late final AnalyzerComponent analyzer = AnalyzerComponent(this);

  /// Component for looping a section of the song.
  late final LoopComponent loop = LoopComponent(this);

  /// Load song preferences from a [json] map.
  @mustCallSuper
  void loadPreferences(Json json) {
    int? position = tryCast<int>(json['position']);
    seek(Duration(milliseconds: position ?? 0));

    slowdowner.loadPreferencesFromJson(
      tryCast<Json>(json['slowdowner']) ?? {},
    );
    loop.loadPreferencesFromJson(
      tryCast<Json>(json['looper']) ?? {},
    );
    equalizer.loadPreferencesFromJson(
      tryCast<Json>(json['equalizer']) ?? {},
    );
    analyzer.loadPreferencesFromJson(
      tryCast<Json>(json['analyzer']) ?? {},
    );
  }

  /// Create a json map containing the current preferences for this [song].
  @mustCallSuper
  Json toPreferences() {
    return {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.savePreferencesToJson(),
      "looper": loop.savePreferencesToJson(),
      "equalizer": equalizer.savePreferencesToJson(),
      "analyzer": analyzer.savePreferencesToJson(),
    };
  }
}

class SinglePlayer extends SongPlayer {
  /// An implementation of [SongPlayer] that plays a single audio clip.
  SinglePlayer._(super.song, this.source, super.handle) : super._();

  static Future<SinglePlayer> load(Song song) async {
    final AudioSource source = await song.audio.resolve(song: song);
    // Activate filters. This needs to be done before the sound is played.
    for (var filter in [
      source.filters.pitchShiftFilter,
      source.filters.parametricEq,
    ]) {
      if (!filter.isActive) filter.activate();
    }

    // Play sound
    final SoundHandle handle = await SoLoud.instance.play(
      source,
      paused: true,
      looping: true,
    );

    final SinglePlayer player = SinglePlayer._(song, source, handle);

    // Load preferences
    if (song.preferences != null) player.loadPreferences(song.preferences!);

    return player;
  }

  final AudioSource source;

  @override
  Duration get duration => SoLoud.instance.getLength(source);

  @override
  late final Filters filters = Filters((apply) {
    apply(source.filters, handle: handle);
  });

  /// Whether to demix this song if it isn't already.
  ///
  /// If this is `null`, the default behavior specified by [Songs.demixAutomatically] will be used.
  bool? get demix => demixNotifier.value;
  set demix(bool? value) => demixNotifier.value = value;
  late final ValueNotifier<bool?> demixNotifier = ValueNotifier(null)
    ..addListener(() {
      if (demix == false) {
        DemixingProcesses.cancel(song);
      } else if (demix == true) {
        DemixingProcesses.start(song);
      }
    });

  @override
  Future<void> dispose() async {
    await SongPlayer.soloud.stop(handle);

    return await super.dispose();
  }

  @override
  void loadPreferences(Json json) {
    super.loadPreferences(json);

    demixNotifier.value = tryCast<bool>(json['demix']);
  }

  @override
  Json toPreferences() {
    return {
      ...super.toPreferences(),
      if (demix != null) "demix": demix,
    };
  }
}

class MultiPlayer extends SongPlayer {
  /// An implementation of [SongPlayer] that plays multiple audio clips simultaneously.
  ///
  /// The [demixer] component allows the volume of each audio clip to be controlled separately.
  MultiPlayer._(super.song, this.sources, this.handles, super.handle)
    : super._();

  static Future<MultiPlayer> load(Song song) async {
    assert(await song.isDemixed);

    // We have to resolve the underlying audio provider for the waveform extraction to work.
    final AudioSource _ = await song.audio.resolve(song: song);

    final Map<StemType, File> files = (await song.cachedStems)!;

    final sources = {
      for (final e in files.entries)
        e.key: await SoLoud.instance.loadFile(e.value.path),
    };

    // Activate filters. This needs to be done before the sound is played.
    sources.forEach((stem, source) {
      for (var filter in [
        source.filters.pitchShiftFilter,
        source.filters.parametricEq,
      ]) {
        if (!filter.isActive) filter.activate();
      }
    });

    final handles = {
      for (final e in sources.entries)
        e.key: await SoLoud.instance.play(
          e.value,
          paused: true,
          looping: true,
        ),
    };

    final SoundHandle groupHandle = SoLoud.instance.createVoiceGroup();
    if (groupHandle.isError) {
      throw Exception("[DEMIXER] Failed to create voice group");
    }

    SoLoud.instance.addVoicesToGroup(
      groupHandle,
      handles.values.toList(),
    );

    final MultiPlayer player = MultiPlayer._(
      song,
      sources,
      handles,
      groupHandle,
    );

    // Load preferences
    if (song.preferences != null) player.loadPreferences(song.preferences!);

    return player;
  }

  /// The sources of the individual sounds that are played simultaneously.
  final Map<StemType, AudioSource> sources;

  /// The handles of the individual sounds that are played simultaneously.
  final Map<StemType, SoundHandle> handles;

  @override
  Duration get duration => SoLoud.instance.getLength(sources.values.first);

  @override
  late final Filters filters = Filters((apply) {
    sources.forEach((stem, source) {
      apply(source.filters, handle: handles[stem]);
    });
  });

  @override
  List<SongPlayerComponent> get components =>
      List.unmodifiable([...super.components, demixer]);

  /// Component for isolating or muting specific instruments in the song.
  late final DemixerComponent demixer = DemixerComponent(this);

  @override
  void seek(Duration position) {
    position = loop.clamp(position);
    handles.forEach((stem, handle) {
      SongPlayer.soloud.seek(handle, position);
    });
    positionNotifier.value = position;
    notifyListeners();
  }

  @override
  void loadPreferences(Json json) {
    super.loadPreferences(json);

    demixer.loadPreferencesFromJson(
      tryCast<Json>(json['demixer']) ?? {},
    );
  }

  @override
  Json toPreferences() {
    return {
      ...super.toPreferences(),
      "demixer": demixer.savePreferencesToJson(),
    };
  }

  @override
  Future<void> dispose() async {
    await super.dispose();

    await Future.wait([
      for (var handle in handles.values) SoLoud.instance.stop(handle),
      for (var source in sources.values) SoLoud.instance.disposeSource(source),
    ]);
    SoLoud.instance.destroyVoiceGroup(handle);
  }
}
