import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/utils/utils.dart';

/// The demo song loaded the first time the user launches the app.
/// Access to this song is unrestricted.
final Song demoSong = Song(
  id: "demo",
  title: "In Treble, Spilled Some Jazz Jam",
  artist: "Erik Lagerstedt",
  artUri: Uri.parse(
    "https://bemain.github.io/musbx/assets/album_art/demo.png",
  ),
  audio: YtdlpAudio(Uri.parse("https://youtu.be/9ytqRUjYJ7s")),
);

enum GetOrder { ascending, descending }

class SongRepository extends ChangeNotifier {
  SongRepository._(this._history) {
    _history.addListener(notifyListeners);
  }

  final HistoryHandler<Song> _history;

  static Future<SongRepository> create() async {
    final history = HistoryHandler<Song>(
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

    await history.fetch();

    if (history.entries.isEmpty) {
      await history.add(demoSong);
    }

    return SongRepository._(history);
  }

  // TODO: Remove once we introduce 'provider'.
  static late final SongRepository instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  bool get isEmpty => _history.entries.isEmpty;
  bool get isNotEmpty => !isEmpty;

  List<Song> getAll({
    GetOrder order = GetOrder.descending,
  }) {
    return _history.sorted(ascending: order == GetOrder.ascending);
  }

  Iterable<Song> getWhere(
    bool Function(Song song, DateTime accessedAt) test,
  ) {
    return _history.entries.entries
        .where((e) => test(e.value, e.key))
        .map((e) => e.value);
  }

  @useResult
  Future<Result<Song>> add(Song song) async {
    try {
      await _history.add(song);
      if (Songs.demixAutomatically) DemixingProcesses.start(song);
      return Result.ok(song);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @useResult
  Future<Result<Song>> addFile(File file) async {
    try {
      return await add(
        Song(
          id: sha1.convert(utf8.encode(file.path)).toString(),
          title: file.path.split("/").last.split(".").first,
          audio: FileAudio(file),
        ),
      );
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @useResult
  Future<Result<Song>> addTrack(SoundCloudTrack track) async {
    try {
      return await add(
        Song(
          id: track.id.toString(),
          title: HtmlUnescape().convert(track.title),
          artist: track.username == null
              ? null
              : HtmlUnescape().convert(track.username!),
          artUri: track.artworkUrl != null
              ? Uri.tryParse(track.artworkUrl!)
              : null,
          audio: YtdlpAudio(Uri.parse(track.permalinkUrl)),
        ),
      );
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @useResult
  Future<Result<Song>> update(Song song) async {
    try {
      await _history.update(song);
      return Result.ok(song);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  Future<Result<void>> remove(Song song) async {
    try {
      await _history.remove(song);
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  Future<Result<void>> removeAll() async {
    try {
      await _history.clear();
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
