import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/youtube_search.dart';
import 'package:musbx/songs/player/audio_handler.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/song_preferences.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/ads.dart';

/// The demo song loaded the first time the user launches the app.
/// Access to this song is unrestricted.
final SongNew demoSong = SongNew(
  id: "demo",
  title: "In Treble, Spilled Some Jazz Jam",
  artist: "Erik Lagerstedt",
  artUri: Uri.parse("https://bemain.github.io/musbx/demo_album_art.png"),
  source: YoutubeSource("9ytqRUjYJ7s"),
);

/// A helper class for loading songs.
class Songs extends BaseAudioHandler with SeekHandler {
  /// The [AudioHandler] that handles interaction with the media notification.
  ///
  /// This is created when [initialize] is called.
  static late final SongsAudioHandler handler;

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  static bool isInitialized = false;

  /// Initialize [SoLoud], create the audio [handler] and configure the audio session.
  /// Must be done before any song is [load]ed.
  ///
  /// If [isInitialized] is `true`, do nothing.
  static Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();

    // Initialize audio handler
    handler = await SongsAudioHandler.initialize();
    AudioService.notificationClicked.listen((bool event) {
      if (event) {
        // Navigate to the music player page
        // TODO: Don't hard code this value
        Navigation.navigationShell.goBranch(1);
      }
    });

    // Configure audio session
    final AudioSession session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
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

    // Begin fetching history from disk
    youtubeSearchHistory.fetch();
    history.fetch().then((_) {
      if (history.map.isEmpty) {
        history.add(demoSong);
      }
    });
  }

  /// Used internally to load and save preferences for songs.
  static final SongPreferencesNew _preferences = SongPreferencesNew();

  /// The history of previously loaded songs.
  static final HistoryHandler<SongNew> history = HistoryHandler<SongNew>(
    historyFileName: "song_history",
    fromJson: (json) {
      if (json is! Map<String, dynamic>) {
        throw "[SONG HISTORY] Incorrectly formatted entry in history file: ($json)";
      }
      SongNew? song = SongNew.fromJson(json);
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
  static Iterable<SongNew> get songsPlayedThisWeek => history.map.entries
      .where((entry) =>
          entry.key.difference(DateTime.now()).abs() < const Duration(days: 7))
      .where((entry) => entry.value.id != demoSong.id) // Exclude demo song
      .map((e) => e.value);

  /// Whether the user's access to playing [Songs] has been restricted
  /// because the number of [freeSongsPerWeek] has been reached.
  ///
  /// This is only ever `true` on the 'free' flavor of the app.
  static bool get isAccessRestricted =>
      !Purchases.hasPremium && songsPlayedThisWeek.length >= freeSongsPerWeek;

  /// The player responsible for playing the song that is currently loaded.
  /// TODO: Remove this in favor for a more decentralized structure using provider.
  static SongPlayer? get player => playerNotifier.value;
  static final ValueNotifier<SongPlayer?> playerNotifier = ValueNotifier(null);

  /// Load a [song].
  ///
  /// Prepares for playing the audio provided by [Song.source], and updates the media player notification.
  ///
  /// If premium hasn't been unlocked and [ignoreFreeLimit] is `false`, shows an ad before loading the song.
  static Future<SongPlayer<P>> load<P extends Playable>(
    SongNew<P> song, {
    bool ignoreFreeLimit = false,
  }) async {
    if (player?.song == song) return player! as SongPlayer<P>;

    if (!Purchases.hasPremium && !ignoreFreeLimit) {
      // Make sure the weekly limit has not been exceeded
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

    await player?.dispose();

    if (player != null) {
      // Save preferences
      await _preferences.save(
        player!.song,
        player!.toPreferences(),
      );
    }

    // Load audio
    print(P);
    final SongPlayer<P> newPlayer = await SongPlayer.load<P>(song);

    // Load new preferences
    final prefs = await _preferences.load(song);
    if (prefs != null) newPlayer.loadPreferences(prefs);

    // Add to song history.
    await history.add(song);
    // Add demixed variant
    if (song.source is! DemixedSource) {
      await history.add(song.copyWith<MultiPlayable>(
        id: "${song.id}-demixed",
        source: DemixedSource(song.source),
      ));
    }

    // Update media notification
    newPlayer.addListener(handler.updateState);
    handler.mediaItem.add(
      song.mediaItem.copyWith(duration: newPlayer.duration),
    );

    playerNotifier.value = newPlayer;
    return newPlayer;

  }
}
