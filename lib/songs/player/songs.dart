import 'dart:async';
import 'dart:io' hide Process;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/youtube_search.dart';
import 'package:musbx/songs/player/audio_handler.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/preferences.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/ads.dart';

/// The demo song loaded the first time the user launches the app.
/// Access to this song is unrestricted.
final Song<SinglePlayable> demoSong = Song(
  id: "demo",
  title: "In Treble, Spilled Some Jazz Jam",
  artist: "Erik Lagerstedt",
  artUri: Uri.parse("https://bemain.github.io/musbx/demo_album_art.png"),
  source: YoutubeSource("9ytqRUjYJ7s"),
);

/// A helper class for loading songs.
class Songs extends BaseAudioHandler with SeekHandler {
  Songs._();

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

    // Begin fetching history from disk
    YoutubeSearch.history.fetch();
    history.fetch().then((_) {
      if (history.entries.isEmpty) {
        history.add(demoSong);
      }
    });
  }

  /// Used internally to load and save preferences for songs.
  static final SongPreferences _preferences = SongPreferences();

  /// The history of previously loaded songs.
  static final HistoryHandler<Song> history = HistoryHandler<Song>(
    historyFileName: "song_history",
    fromJson: (json) {
      if (json is! Map<String, dynamic>) {
        throw "[SONG HISTORY] Incorrectly formatted entry in history file: ($json)";
      }
      Song? song = Song.fromJson(json);
      if (song == null) {
        throw "[SONG HISTORY] History entry ($json) could not be parsed as a Song.";
      }
      return song;
    },
    toJson: (value) => value.toJson(),
    onEntryRemoved: (entry) async {
      // Remove cached files
      debugPrint(
          "[SONG HISTORY] Deleting cached files for song ${entry.value.id}");
      final Directory directory = entry.value.cacheDirectory;
      if (await directory.exists()) await directory.delete(recursive: true);
    },
  );

  /// The number of songs the user can play each week on the 'free' flavor of the app.
  static const int freeSongsPerWeek = 3;

  /// The songs played this week. Used by the 'free' flavor of the app to restrict usage.
  static Iterable<Song> get songsPlayedThisWeek => history.entries.entries
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
    Song<P> song, {
    bool ignoreFreeLimit = false,
  }) async {
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

    // Dispose the previous player
    await Songs.dispose();

    // Load audio
    final SongPlayer<P> player = await SongPlayer.load<P>(song);
    final prefs = await _preferences.load(song);
    if (prefs != null) player.loadPreferences(prefs);

    // Add to song history.
    await history.add(song);

    // Update media notification
    player.addListener(handler.updateState);
    handler.mediaItem.add(
      song.mediaItem.copyWith(duration: player.duration),
    );

    playerNotifier.value = player;
    return player;
  }

  /// Dispose the current [player].
  static Future<void> dispose() async {
    final player = Songs.player;
    if (player == null) return;

    playerNotifier.value = null;

    await player.dispose();

    // Save preferences
    await _preferences.save(
      player.song,
      player.toPreferences(),
    );
  }
}
