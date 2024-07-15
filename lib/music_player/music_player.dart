import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/ads.dart';
import 'package:musbx/music_player/analyzer/analyzer.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/pick_song_button/components/search_youtube_button.dart';
import 'package:musbx/music_player/pick_song_button/youtube_api/video.dart';
import 'package:musbx/music_player/demixer/demixer.dart';
import 'package:musbx/music_player/equalizer/equalizer.dart';
import 'package:musbx/music_player/looper/looper.dart';
import 'package:musbx/music_player/slowdowner/slowdowner.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/history_handler.dart';
import 'package:musbx/music_player/song_preferences.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/purchases.dart';
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
    _initialize();
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

  /// The history of previously loaded songs.
  final HistoryHandler<Song> songHistory = HistoryHandler<Song>(
    historyFileName: "song_history",
    maxEntries: 8,
    fromJson: (json) {
      if (json is! Map<String, dynamic>) {
        throw "[SONG HISTORY] Incorrectly formatted entry in history file: ($json)";
      }
      Song? song = Song.fromJson(json);
      if (song == null) {
        throw "[SONG HISTORY] History entry ($json) is missing required fields";
      }
      return song;
    },
    toJson: (value) => value.toJson(),
    onEntryRemoved: (entry) async {
      // Remove cached files
      debugPrint(
          "[SONG HISTORY] Deleting cached files for song ${entry.value.id}");
      final Directory directory = await entry.value.cacheDirectory;
      if (await directory.exists()) directory.delete(recursive: true);
    },
  );

  /// The number of songs the user can play each week on the 'free' flavor of the app.
  static const int freeSongsPerWeek = 3;

  /// The songs played this week. Used by the 'free' flavor of the app to restrict usage.
  List<Song> get songsPlayedThisWeek => songHistory.history.entries
      .where((entry) =>
          entry.key.difference(DateTime.now()) < const Duration(days: 7))
      .map((e) => e.value)
      .toList();

  /// Whether the user's access to the [MusicPlayer] has been restricted
  /// because the number of [freeSongsPerWeek] has been reached.
  ///
  /// This is only ever `true` on the 'free' flavor of the app.
  bool get isAccessRestricted =>
      !Purchases.hasPremium && songsPlayedThisWeek.length >= freeSongsPerWeek;

  /// Start or resume playback.
  Future<void> play() async => await player.play();

  /// Pause playback.
  Future<void> pause() async => await player.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    position = looper.clampPosition(position, duration: duration);
    positionNotifier.value = position;
    await player.seek(position);
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

  /// Component for isolating or music specific instruments of the song.
  final Demixer demixer = Demixer();

  /// Component for analyzing the current song, including chord identification and waveform extraction.
  final Analyzer analyzer = Analyzer();

  /// The process currently loading a song, or `null` if no song has been loaded.
  ///
  /// This is used to make sure two processes don't try to load a song at the same time.
  /// Every process wanting to set [player]'s audio source must:
  ///  1. Create a future that first awaits [loadSongLock] and then sets [player]'s audio source.
  ///  2. Override [loadSongLock] with the newly created future.
  ///  3. Await the future it created.
  ///
  /// Here is an example of how that could be done:
  /// ```
  /// Future<void> loadAudioSource() async {
  ///   loadSongLock = _loadAudioSource(loadSongLock);
  ///   await loadSongLock;
  /// }
  ///
  /// Future<void> _loadAudioSource(Future<void>? awaitBeforeLoading) async {
  ///   try { // This needs to be done in a `try` block. Otherwise when one load fails, all the following ones will fail, too.
  ///     await awaitBeforeLoading;
  ///   } catch (_) {}
  ///   await player.setAudioSource(...)
  /// }
  ///
  /// ```
  Future<void>? loadSongLock;

  /// Load a [song].
  ///
  /// Prepares for playing the audio provided by [Song.source], and updates the media player notification.
  ///
  /// If premium hasn't been unlocked and [ignoreFreeLimit] is `false`, shows an ad before loading the song.
  Future<void> loadSong(Song song, {bool ignoreFreeLimit = false}) async {
    if (!Purchases.hasPremium && !ignoreFreeLimit) {
      if (isAccessRestricted && !songsPlayedThisWeek.contains(song)) {
        throw "Access to the free version of the music player restricted. $freeSongsPerWeek songs have already been played this week.";
      }

      try {
        // Show interstitial ad
        (await loadInterstitialAd())?.show();
      } catch (e) {
        debugPrint("[ADS] Failed to load interstitial ad: $e");
      }
    }

    // Make sure no other process is currently setting the audio source
    loadSongLock = _loadSong(song, awaitBeforeLoading: loadSongLock);
    await loadSongLock;
  }

  /// Awaits [awaitBeforeLoading] and then loads [song].
  /// See [loadSongLock] for more info why this is required.
  Future<void> _loadSong(
    Song song, {
    Future<void>? awaitBeforeLoading,
  }) async {
    try {
      await awaitBeforeLoading;
    } catch (_) {}

    await pause();
    stateNotifier.value = MusicPlayerState.loadingAudio;

    // Save preferences for previous song
    await saveSongPreferences();

    // Load audio
    await player.setAudioSource(await song.source.toAudioSource());

    // Update song
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
      source: FileSource(file.path!),
    ));
  }

  /// Load a song to play from a [YoutubeVideo].
  Future<void> loadVideo(YoutubeVideo video) async {
    HtmlUnescape htmlUnescape = HtmlUnescape();

    await loadSong(Song(
      id: video.id,
      title: htmlUnescape.convert(video.title),
      artist: htmlUnescape.convert(video.channelTitle),
      artUri: Uri.tryParse(video.thumbnails.high.url),
      source: YoutubeSource(video.id),
    ));
  }

  /// Load preferences for a [song]].
  ///
  /// If no preferences could be found for the song, do nothing.
  Future<void> loadSongPreferences(Song song) async {
    final Map json = await _songPreferences.load(song) ?? {};

    int? position = tryCast<int>(json["position"]);
    seek(Duration(milliseconds: position ?? 0));

    slowdowner.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["slowdowner"]) ?? {},
    );
    looper.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["looper"]) ?? {},
    );
    equalizer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["equalizer"]) ?? {},
    );
    demixer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["demixer"]) ?? {},
    );
    analyzer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["analyzer"]) ?? {},
    );
  }

  /// Save preferences for the current song.
  ///
  /// If no song is currently loaded, do nothing
  Future<void> saveSongPreferences() async {
    if (song == null) return;

    await _songPreferences.save(song!, {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.saveSettingsToJson(),
      "looper": looper.saveSettingsToJson(),
      "equalizer": equalizer.saveSettingsToJson(),
      "demixer": demixer.saveSettingsToJson(),
      "analyzer": analyzer.saveSettingsToJson(),
    });
  }

  /// Listen for changes from [player].
  void _initialize() {
    // Begin fetching history from disk
    youtubeSearchHistory.fetch();
    songHistory.fetch().then((_) {
      // Load most recent song
      if (songHistory.history.isNotEmpty) {
        loadSong(songHistory.sorted().first, ignoreFreeLimit: true);
      }
    });

    // Listen to app lifecycle
    AppLifecycleListener(
      onInactive: () async {
        await MusicPlayer.instance.saveSongPreferences();
      },
    );

    player.setVolume(0.5);

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
      if (isPlaying) positionNotifier.value = position;
    });

    // duration
    player.durationStream.listen((duration) {
      // On iOS, duration can sometimes become very close to 0 which causes problems. Avoid this...
      if (duration?.inMilliseconds == 0) return;

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
    analyzer.initialize(this);
  }

  /// Initialize the audio service for [audioHandler] to enable interaction
  /// with the phone's media player, and the audio session to allow playing
  /// and recording simultaneously (required on iOS).
  Future<void> initAudioService() async {
    await AudioService.init(
      builder: () => audioHandler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.music_player',
        androidNotificationChannelName: 'Music player',
        androidNotificationIcon: "drawable/ic_notification",
      ),
    );

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }
}
