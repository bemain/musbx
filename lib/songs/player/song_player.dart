import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/analyzer/analyzer.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/loop/loop.dart';
import 'package:musbx/songs/player/audio_handler.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/songs/slowdowner/slowdowner.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

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
abstract class SongPlayer<P extends Playable> extends ChangeNotifier {
  static final SoLoud soloud = SoLoud.instance;

  SongPlayer._(this.song, this.playable, this.handle) {
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
  /// abstract class, depending on the type of the `Playable` [P].
  ///
  /// The workflow is as follows:
  ///  - Load the [song.source], to obtain a [playable].
  ///  - Play the [playable], to obtain a sound [handle].
  static Future<SongPlayer<P>> load<P extends Playable>(Song<P> song) async {
    final P playable = await song.source.load(
      cacheDirectory: Directory("${song.cacheDirectory.path}/source/"),
    );
    // Activate filters. This needs to be done before the sound is played.
    playable.filters().pitchShift.activate();
    // FIXME: Equalizer temporarily disabled to reduce artifacts.
    // ..equalizer.activate();

    // Play sound
    final SoundHandle handle = await playable.play();
    final SongPlayer<P> player;
    if (song.source is SongSource<SinglePlayable>) {
      player =
          SinglePlayer(
                song as Song<SinglePlayable>,
                playable as SinglePlayable,
                handle,
              )
              as SongPlayer<P>;
    } else if (song.source is SongSource<MultiPlayable>) {
      player =
          MultiPlayer(
                song as Song<MultiPlayable>,
                playable as MultiPlayable,
                handle,
              )
              as SongPlayer<P>;
    } else {
      throw ("No player exists for the given source ${song.source}");
    }

    return player;
  }

  /// The song that this player plays.
  final Song<P> song;

  /// The object created from [song.source], that in turn created the current song [handle].
  final P playable;

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
  /// See also:
  ///  - [Playable.dispose]
  ///  - [SongPlayerComponent.dispose]
  @override
  Future<void> dispose() async {
    isPlayingNotifier.value = false;

    await SongsAudioHandler.session.setActive(false);

    _positionUpdater.cancel();

    for (SongPlayerComponent component in components) {
      await component.dispose();
    }

    await playable.dispose();
    super.dispose();
  }

  /// The duration of the audio that is playing.
  Duration get duration => playable.duration;

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

class SinglePlayer extends SongPlayer<SinglePlayable> {
  /// An implementation of [SongPlayer] that plays a single audio clip.
  SinglePlayer(super.song, super.playable, super.handle) : super._() {
    restartDemixing(); // Start demixing
    if (!Songs.demixAutomatically) {
      demixingProcess.cancel();
    }
  }

  /// The process responsible for demixing the song.
  ///
  /// This process is started automatically when the [SinglePlayer] is created.
  late DemixingProcess demixingProcess;

  /// Whether to demix this song if it is't already.
  ///
  /// If this is ´null´, the default behavior specified by [Songs.demixAutomatically] will be used.
  bool? get demix => demixNotifier.value;
  late final ValueNotifier<bool?> demixNotifier = ValueNotifier(null)
    ..addListener(() {
      if (demix == false) {
        demixingProcess.cancel();
      } else if (demix == true && demixingProcess.isCancelled) {
        restartDemixing();
      }
    });

  /// Restart the [demixingProcess].
  void restartDemixing() {
    demixingProcess = DemixingProcess(
      song.source,
      cacheDirectory: Directory("${song.cacheDirectory.path}/source/"),
    );
  }

  @override
  Future<void> dispose() async {
    await SongPlayer.soloud.stop(handle);

    demixingProcess.cancel();
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

class MultiPlayer extends SongPlayer<MultiPlayable> {
  /// An implementation of [SongPlayer] that plays multiple audio clips simultaneously.
  ///
  /// The [demixer] component allows the volume of each audio clip to be controlled separately.
  MultiPlayer(super.song, super.playable, super.handle) : super._();

  /// The handles of the individual sounds that are played simultaneously.
  ///
  /// Forwarded from the [playable].
  Iterable<SoundHandle> get handles => playable.handles!.values;

  @override
  Future<void> dispose() async {
    await super.dispose();
    SoLoud.instance.destroyVoiceGroup(handle);
  }

  @override
  List<SongPlayerComponent> get components =>
      List.unmodifiable([...super.components, demixer]);

  /// Component for isolating or muting specific instruments in the song.
  late final DemixerComponent demixer = DemixerComponent(this);

  @override
  void seek(Duration position) {
    position = loop.clamp(position);
    for (SoundHandle handle in handles) {
      SongPlayer.soloud.seek(handle, position);
    }
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
}
