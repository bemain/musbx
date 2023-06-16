import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/current_song_card/youtube_api/video.dart';
import 'package:musbx/music_player/demixer/demixer.dart';
import 'package:musbx/music_player/equalizer/equalizer.dart';
import 'package:musbx/music_player/loop_card/looper.dart';
import 'package:musbx/music_player/slowdowner/slowdowner.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_history.dart';
import 'package:musbx/music_player/song_preferences.dart';
import 'package:musbx/music_player/youtube_audio_streams.dart';
import 'package:musbx/widgets.dart';

/// The state of [MusicPlayer].
enum MusicPlayerState {
  /// The player has been initialized, but no audio has been loaded.
  idle,

  /// The user is picking audio to load.
  pickingAudio,

  /// The player has been initialized, and is loading audio.
  loadingAudio,

  /// The player has loaded audio.
  ready,
}

/// Singleton for playing audio.
class MusicPlayer {
  // Only way to access is through [instance].
  MusicPlayer._() {
    _init();
  }

  /// The instance of this singleton.
  static final MusicPlayer instance = MusicPlayer._();

  /// The state of the player.
  MusicPlayerState get state => stateNotifier.value;
  final ValueNotifier<MusicPlayerState> stateNotifier =
      ValueNotifier(MusicPlayerState.idle);

  /// The audio pipeline used by [player].
  late final AudioPipeline audioPipeline = AudioPipeline(androidAudioEffects: [
    if (Platform.isAndroid) equalizer.androidEqualizer
  ]);

  /// The [AudioPlayer] used for playback.
  late final AudioPlayer player = AudioPlayer(audioPipeline: audioPipeline);

  late final MusicPlayerAudioHandler audioHandler = MusicPlayerAudioHandler(
    onPlay: play,
    onPause: pause,
    // TODO: Implement onStop
    playbackStateStream: player.playbackEventStream.map(
      (event) => MusicPlayerAudioHandler.transformEvent(event, player),
    ),
  );

  /// Used internally to load and save preferences for songs.
  final SongPreferences _songPreferences = SongPreferences();

  final SongHistory songHistory = SongHistory();

  /// Start or resume playback.
  Future<void> play() async => await player.play();

  /// Pause playback.
  Future<void> pause() async => await player.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    await player.seek(looper.clampPosition(position, duration: duration));
    await audioHandler.seek(position);
  }

  /// Title of the current song, or `null` if no song loaded.
  Song? get song => songNotifier.value;
  final ValueNotifier<Song?> songNotifier = ValueNotifier<Song?>(null);

  /// Returns `null` if no song loaded, value otherwise.
  T? nullIfNoSongElse<T>(T? value) =>
      (isLoading || state == MusicPlayerState.idle) ? null : value;

  /// If true, the player is currently in a loading state.
  /// If false, the player is either idle or has loaded audio.
  bool get isLoading => (state == MusicPlayerState.loadingAudio ||
      state == MusicPlayerState.pickingAudio);

  /// The current position of the player.
  Duration get position => positionNotifier.value;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The duration of the current audio.
  /// Only valid if a song has been loaded.
  Duration get duration => durationNotifier.value;
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(const Duration(seconds: 1));

  /// Whether the player is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? play() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Whether the player is buffering audio.
  bool get isBuffering => isBufferingNotifier.value;
  final ValueNotifier<bool> isBufferingNotifier = ValueNotifier(false);

  /// Component for changing the pitch and speed of the song.
  final Slowdowner slowdowner = Slowdowner();

  /// Component for looping a section of the song.
  final Looper looper = Looper();

  /// Component for adjusting the gain for different frequency bands of the song.
  final Equalizer equalizer = Equalizer();

  final Demixer demixer = Demixer();

  /// Load a [song].
  ///
  /// Prepares for playing the audio provided by [Song.audioSource], and updates the media player notification.
  Future<void> loadSong(Song song) async {
    await pause();
    stateNotifier.value = MusicPlayerState.loadingAudio;

    // Save preferences for previous song
    await saveSongPreferences();

    // Load audio
    await player.setAudioSource(song.audioSource);

    // Update songTitle
    songNotifier.value = song;
    // Reset loopSection
    looper.section = LoopSection(end: duration);

    // Update the media player notification
    audioHandler.mediaItem.add(
      song.mediaItem.copyWith(duration: duration),
    );

    // Load new preferences
    await loadSongPreferences(song);

    // Add to song history.
    await songHistory.add(song);

    stateNotifier.value = MusicPlayerState.ready;
  }

  /// Load a song to play from a [PlatformFile].
  Future<void> loadFile(PlatformFile file) async {
    await loadSong(Song(
      id: file.path!.hashCode.toString(),
      title: file.name,
      source: SongSource.file,
      audioSource: AudioSource.uri(Uri.file(file.path!)),
    ));
  }

  /// Load a song to play from a [YoutubeVideo].
  Future<void> loadVideo(YoutubeVideo video) async {
    // Get stream info

    HtmlUnescape htmlUnescape = HtmlUnescape();

    await loadSong(Song(
      id: video.id,
      title: htmlUnescape.convert(video.title),
      artist: htmlUnescape.convert(video.channelTitle),
      artUri: Uri.tryParse(video.thumbnails.high.url),
      source: SongSource.youtube,
      audioSource: AudioSource.uri(await getAudioStream(video.id)),
    ));
  }

  /// Load preferences for the song with [songId].
  ///
  /// If no preferences could be found for the song, do nothing.
  Future<void> loadSongPreferences(Song song) async {
    var json = await _songPreferences.load(song.id);
    if (json == null) return;

    int? position = tryCast<int>(json["position"]);
    if (position != null && position < duration.inMilliseconds) {
      seek(Duration(milliseconds: position));
    }

    var slowdownerSettings = tryCast<Map<String, dynamic>>(json["slowdowner"]);
    if (slowdownerSettings != null) {
      slowdowner.loadSettingsFromJson(slowdownerSettings);
    }

    var looperSettings = tryCast<Map<String, dynamic>>(json["looper"]);
    if (looperSettings != null) {
      looper.loadSettingsFromJson(looperSettings);
    }

    var equalizerSettings = tryCast<Map<String, dynamic>>(json["equalizer"]);
    if (equalizerSettings != null) {
      equalizer.loadSettingsFromJson(equalizerSettings);
    }

    var demixerSetttings = tryCast<Map<String, dynamic>>(json["demixer"]);
    if (demixerSetttings != null) {
      demixer.loadSettingsFromJson(demixerSetttings);
    }
  }

  /// Save preferences for the current song.
  ///
  /// If no song is currently loaded, do nothing
  Future<void> saveSongPreferences() async {
    if (song == null) return;

    await _songPreferences.save(song!.id, {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.saveSettingsToJson(),
      "looper": looper.saveSettingsToJson(),
      "equalizer": equalizer.saveSettingsToJson(),
      "demixer": demixer.saveSettingsToJson(),
    });
  }

  /// Listen for changes from [player].
  void _init() {
    songHistory.fetch();

    // isPlaying
    player.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    // position
    player.positionStream.listen((position) async {
      // If we have reached the end of the loop section while looping, seek to the start.
      if ((isPlaying && looper.enabled && position >= looper.section.end)) {
        await seek(Duration.zero);
        return;
      }

      // If we have reached the end of the song, pause.
      if (isPlaying && !looper.enabled && position >= duration) {
        await player.pause();
        await seek(duration);
        return;
      }

      // Update position
      positionNotifier.value = position;
    });

    // duration
    player.durationStream.listen((duration) {
      durationNotifier.value = duration ?? const Duration(seconds: 1);
    });

    // buffering
    player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.buffering) {
        isBufferingNotifier.value = true;
      }

      if (processingState == ProcessingState.ready) {
        isBufferingNotifier.value = false;
      }
    });

    slowdowner.initialize(this);
    looper.initialize(this);
    equalizer.initialize(this);
    demixer.initialize(this);
  }

  /// Initialize the audio service for [audioHandler], to enable interaction
  /// with the phone's media player.
  Future<void> initAudioService() async {
    await AudioService.init(
      builder: () => audioHandler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.music_player',
        androidNotificationChannelName: 'Music player',
      ),
    );
  }
}
