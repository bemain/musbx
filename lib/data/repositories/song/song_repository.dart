import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/data/services/file_cache_service.dart';
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

enum GetOrder { ascending, descending }

class SongRepository extends ChangeNotifier {
  SongRepository._(this._history) {
    _history.addListener(notifyListeners);
  }

  final HistoryHandler<Song> _history;

  static Future<SongRepository> create({
    required FileCacheService fileCache,
  }) async {
    final history = HistoryHandler<Song>(
      file: fileCache.persistent.file("songs/history.json"),
      fromJson: (json) {
        if (json is! Json) {
          throw "[LIBRARY] Incorrectly formatted entry in history file: ($json)";
        }
        try {
          return Song.fromJson(json);
        } catch (error) {
          throw "[LIBRARY] History entry ($json) could not be parsed as a Song; $error";
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

  Song? getById(String id) => getWhere((song, _) => song.id == id).firstOrNull;

  @useResult
  Future<Result<Song>> add(Song song) async {
    try {
      await _history.add(song);
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
          audio: UrlAudio(Uri.parse(track.permalinkUrl)),
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
}
