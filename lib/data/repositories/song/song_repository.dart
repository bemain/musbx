import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/domain/models/song.dart';
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
  audio: UrlAudio(Uri.parse("https://youtu.be/9ytqRUjYJ7s")),
);

/// Whether the oldest or the most recently played song comes first.
enum GetOrder { ascending, descending }

/// The user's song library.
///
/// Backed by a [HistoryHandler], so the library doubles as a play history: each
/// song carries the time it was last played, and adding a song that is already
/// there just moves it to the top.
class SongRepository extends ChangeNotifier {
  SongRepository._(this._history) {
    _history.addListener(notifyListeners);
  }

  final HistoryHandler<Song> _history;

  /// Read the library from disk, seeding it with [demoSong] when empty.
  static Future<SongRepository> create({
    required FileCacheService fileCache,
  }) async {
    final history = HistoryHandler<Song>(
      file: fileCache.persistent.file("songs/history.json"),
      fromJson: (json) {
        if (json is! Json) {
          throw FormatException(
            "[LIBRARY] Incorrectly formatted entry in history file: ($json)",
          );
        }
        try {
          return Song.fromJson(json);
        } catch (error) {
          throw FormatException(
            "[LIBRARY] History entry ($json) could not be parsed as a Song; $error",
          );
        }
      },
      toJson: (value) => value.toJson(),
    );

    await history.fetch();

    if (history.entries.isEmpty) {
      await history.add(demoSong);
    }

    return SongRepository._(history);
  }

  bool get isEmpty => _history.entries.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Every song in the library, ordered by when it was last played.
  List<Song> getAll({
    GetOrder order = GetOrder.descending,
  }) {
    return _history.sorted(ascending: order == GetOrder.ascending);
  }

  /// The songs for which [test] holds, given the song and when it was last
  /// played.
  Iterable<Song> getWhere(
    bool Function(Song song, DateTime accessedAt) test,
  ) {
    return _history.entries.entries
        .where((e) => test(e.value, e.key))
        .map((e) => e.value);
  }

  /// The song with this [id], if the library holds it.
  Song? getById(String id) => getWhere((song, _) => song.id == id).firstOrNull;

  /// Add [song], or move it to the top if it is already in the library.
  @useResult
  Future<Result<Song>> add(Song song) async {
    try {
      await _history.add(song);
      return Result.ok(song);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// Add a song read from a local [file], titled after the file name.
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

  /// Add a song streamed from an online [track].
  @useResult
  Future<Result<Song>> addTrack(OnlineTrack track) async {
    try {
      return await add(
        Song(
          id: track.id,
          title: track.title,
          artist: track.artist,
          artUri: track.artUri,
          audio: UrlAudio(track.sourceUrl),
        ),
      );
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// Replace the stored song with the same id, keeping its place in the history.
  @useResult
  Future<Result<Song>> update(Song song) async {
    try {
      await _history.update(song);
      return Result.ok(song);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// Remove [song] from the library. Its cached files are left alone; see
  /// `DeleteSong` to be rid of those too.
  @useResult
  Future<Result<void>> remove(Song song) async {
    try {
      await _history.remove(song);
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
