import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/current_song_card/youtube_api/video.dart';
import 'package:musbx/music_player/equalizer/equalizer.dart';
import 'package:musbx/music_player/loop_card/looper.dart';
import 'package:musbx/music_player/pitch_speed_card/slowdowner.dart';
import 'package:musbx/music_player/song_preferences.dart';
import 'package:musbx/widgets.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

  MusicPlayerState get state => stateNotifier.value;
  final ValueNotifier<MusicPlayerState> stateNotifier =
      ValueNotifier(MusicPlayerState.idle);

  /// The [AudioPlayer] used for playback.
  late final AudioPlayer player = AudioPlayer(
    audioPipeline:
        AudioPipeline(androidAudioEffects: [equalizer.androidEqualizer]),
  );

  /// Used internally to get audio from YouTube.
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  /// Used internally to load and save preferences for songs.
  final SongPreferences songPreferences = SongPreferences();

  /// Start or resume playback.
  Future<void> play() async => await player.play();

  /// Pause playback.
  Future<void> pause() async => await player.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    await player.seek(looper.clampPosition(position, duration: duration));
    await MusicPlayerAudioHandler.instance.seek(position);
  }

  /// Title of the current song, or `null` if no song loaded.
  String? get songTitle => songTitleNotifier.value;
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// Returns `null` if no song loaded, value otherwise.
  T? nullIfNoSongElse<T>(T? value) =>
      (isLoading || state == MusicPlayerState.idle) ? null : value;

  /// If true, the player is currently in a loading state.
  /// If false, the player is either idle or have loaded audio.
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

  /// Load a song to play from [audioSource].
  ///
  /// Prepares for playing the audio provided by the source, and updates the media player notification.
  /// The song title is determined using the values offered by [mediaItem].
  Future<void> loadAudioSource(
    AudioSource audioSource,
    MediaItem mediaItem,
  ) async {
    await pause();
    stateNotifier.value = MusicPlayerState.loadingAudio;

    if (songTitle != null) {
      // Save preferences for previous song
      await songPreferences.savePreferencesForSong(saveSettingsToJson());
    }

    // Load audio
    await player.setAudioSource(audioSource);

    // Update songTitle
    songTitleNotifier.value = mediaItem.title;
    // Reset loopSection
    looper.section = LoopSection(end: duration);

    // Update the media player notification
    MusicPlayerAudioHandler.instance.mediaItem.add(mediaItem);

    // Load new preferences
    loadSettingsFromJson(await songPreferences.loadPreferencesForSong());

    stateNotifier.value = MusicPlayerState.ready;
  }

  /// Load a song to play from a [PlatformFile].
  Future<void> loadFile(PlatformFile file) async {
    await loadAudioSource(
      AudioSource.uri(Uri.file(file.path!)),
      MediaItem(
        id: file.path!,
        title: file.name,
        duration: player.duration,
      ),
    );
  }

  /// Load a song to play from a [YoutubeVideo].
  Future<void> loadVideo(YoutubeVideo video) async {
    // Get stream info
    StreamManifest manifest =
        await _youtubeExplode.videos.streams.getManifest(video.id);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

    HtmlUnescape htmlUnescape = HtmlUnescape();

    await loadAudioSource(
      AudioSource.uri(Uri.parse(streamInfo.url.toString())),
      MediaItem(
        id: video.id,
        title: htmlUnescape.convert(video.title),
        duration: duration,
        artist: htmlUnescape.convert(video.channelTitle),
        artUri: Uri.tryParse(video.thumbnails.high.url),
      ),
    );
  }

  /// Load settings for a song from a [json] map.
  ///
  /// Called when a song that has preferences saved is loaded.
  void loadSettingsFromJson(Map<String, dynamic> json) {
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
  }

  /// Save preferences for a song to a json map.
  Map<String, dynamic> saveSettingsToJson() {
    return {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.saveSettingsToJson(),
      "looper": looper.saveSettingsToJson(),
      "equalizer": equalizer.saveSettingsToJson(),
    };
  }

  /// Listen for changes from [player].
  void _init() {
    songPreferences.clearPreferences();

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
  }
}
