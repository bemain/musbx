import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/music_player/musbx_api/chords_api.dart';
import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/process.dart';

class ChordIdentificationProcess extends Process<Map<Duration, Chord?>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  /// The file where the chords for this [song] are cached.
  Future<File> get cacheFile async =>
      File("${(await song.cacheDirectory).path}/chords.json");

  @override
  Future<Map<Duration, Chord?>> process() async {
    Map? chords;
    // Check cache
    File cache = await cacheFile;
    if (await cache.exists()) {
      try {
        chords = jsonDecode(await cache.readAsString()) as Map;
      } catch (e) {
        debugPrint("[ANALYZER] Malformed chords file: '${cache.path}'");
      }
    }

    breakIfCancelled();

    if (chords == null) {
      // Perform chords identification
      final ChordsApiHost host = await MusbxApi.findChordsHost();

      if (song.source is FileSource) {
        chords = await host.analyzeFile(
          (song.source as FileSource).file,
        );
      } else {
        chords = await host.analyzeYoutubeSong(
          (song.source as YoutubeSource).youtubeId,
        );
      }

      // Save to cache
      await cache.writeAsString(jsonEncode(chords));
    }

    breakIfCancelled();

    return chords.map((key, value) => MapEntry(
          Duration(milliseconds: (double.parse(key) * 1000).toInt()),
          Chord.tryParse(value),
        ));
  }
}
