import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' hide AudioSource;
import 'package:musbx/songs/library_page/youtube_search.dart';
import 'package:musbx/songs/looper/looper.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_preferences.dart';
import 'package:musbx/songs/player/song_source.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/ads.dart';
import 'package:musbx/widgets/widgets.dart';

/// The demo song loaded the first time the user launches the app.
/// Access to this song is unrestricted.
final Song demoSong = Song(
  id: "demo",
  title: "In Treble, Spilled Some Jazz Jam",
  artist: "Erik Lagerstedt",
  artUri: Uri.parse("https://bemain.github.io/musbx/demo_album_art.png"),
  source: YoutubeSource("9ytqRUjYJ7s"),
);

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
  late final AudioPipeline audioPipeline = AudioPipeline();

  /// The [AudioPlayer] used for playback.
  late final AudioPlayer player = AudioPlayer(audioPipeline: audioPipeline);

  /// Used internally to load and save preferences for songs.
  final SongPreferences _songPreferences = SongPreferences();

  /// The history of previously loaded songs.
  final HistoryHandler<Song> songs = HistoryHandler<Song>(
    historyFileName: "song_history_old",
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
  Iterable<Song> get songsPlayedThisWeek => songs.map.entries
      .where((entry) =>
          entry.key.difference(DateTime.now()).abs() < const Duration(days: 7))
      .where((entry) => entry.value.id != demoSong.id) // Exclude demo song
      .map((e) => e.value);

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

  /// Stops playing audio and releases decoders and other native platform resources needed to play audio.
  /// The current audio source state will be retained and playback can be resumed at a later point in time.
  Future<void> stop() async {
    await saveSongPreferences();

    stateNotifier.value = MusicPlayerState.idle;
    songNotifier.value = null;

    loadSongLock = () async {
      try {
        await loadSongLock;
      } catch (_) {}
      await player.stop();
    }();
    await loadSongLock;
  }

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    positionNotifier.value = position;
    await player.seek(position);
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
        throw const AccessRestrictedException(
            "Access to the free version of the music player restricted. $freeSongsPerWeek songs have already been played this week.");
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
    // TODO: Try setting preload to false
    await player.setAudioSource(await song.source.toAudioSource());

    // Update song
    songNotifier.value = song;

    // Load new preferences
    await loadSongPreferences(song);

    // Add to song history.
    await songs.add(song);

    stateNotifier.value = MusicPlayerState.ready;
  }

  /// Load preferences for a [song]].
  ///
  /// If no preferences could be found for the song, do nothing.
  Future<void> loadSongPreferences(Song song) async {
    final Map json = await _songPreferences.load(song) ?? {};

    int? position = tryCast<int>(json["position"]);
    seek(Duration(milliseconds: position ?? 0));
  }

  /// Save preferences for the current song.
  ///
  /// If no song is currently loaded, do nothing
  Future<void> saveSongPreferences() async {
    if (song == null) return;

    await _songPreferences.save(song!, {
      "position": position.inMilliseconds,
    });
  }

  /// Listen for changes from [player].
  void _initialize() {
    // Begin fetching history from disk
    youtubeSearchHistory.fetch();
    songs.fetch().then((_) {
      if (songs.map.isEmpty) {
        songs.add(demoSong);
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
  }

  /// Initialize the audio service for [audioHandler] to enable interaction
  /// with the phone's media player, and the audio session to allow playing
  /// and recording simultaneously (required on iOS).
  Future<void> initAudioService() async {
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
