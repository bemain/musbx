import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/songs/library_page/soundcloud_search.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/utils.dart';

/// The demo song loaded the first time the user launches the app.
/// Access to this song is unrestricted.
final Song demoSong = Song(
  id: "demo",
  title: "In Treble, Spilled Some Jazz Jam",
  artist: "Erik Lagerstedt",
  artUri: Uri.parse("https://bemain.github.io/musbx/demo_album_art.png"),
  audio: YtdlpAudio(Uri.parse("https://youtu.be/9ytqRUjYJ7s")),
);

class SongLibrary {
  SongLibrary._();

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  static bool isInitialized = false;

  /// Fetch [history] from disk.
  static Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    await history.fetch();

    if (history.entries.isEmpty) {
      await history.add(demoSong);
    }
  }

  /// The history of previously loaded songs.
  static final HistoryHandler<Song> history = HistoryHandler<Song>(
    historyFileName: "songs/history",
    fromJson: (json) {
      if (json is! Json) {
        throw "[LIBRARY] Incorrectly formatted entry in history file: ($json)";
      }
      Song? song = Song.fromJson(json);
      if (song == null) {
        throw "[LIBRARY] History entry ($json) could not be parsed as a Song.";
      }
      return song;
    },
    toJson: (value) => value.toJson(),
    onEntryRemoved: (entry) async {
      // Remove cached files
      debugPrint(
        "[LIBRARY] Deleting cached files for song ${entry.value.id}",
      );
      await entry.value.clearCache();
    },
  );

  /// Adds a [song] to the user's library.
  static Future<Song> add(Song song) async {
    await history.add(song);
    if (Songs.demixAutomatically) DemixingProcesses.start(song);
    return song;
  }

  /// Loads a [file] into the user's library.
  static Future<Song> addFile(File file) async {
    return await add(
      Song(
        id: sha1.convert(utf8.encode(file.path)).toString(),
        title: file.path.split("/").last.split(".").first,
        audio: FileAudio(file),
      ),
    );
  }

  /// Loads a [track] from SoundCloud into the user's library.
  static Future<Song> addTrack(SoundCloudTrack track) async {
    return await add(
      Song(
        id: track.id.toString(),
        title: HtmlUnescape().convert(track.title),
        artist: HtmlUnescape().convert(track.username),
        artUri: track.artworkUrl != null
            ? Uri.tryParse(track.artworkUrl!)
            : null,
        audio: YtdlpAudio(Uri.parse(track.permalinkUrl)),
      ),
    );
  }
}
