import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/songs/musbx_api/chords_api.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/process.dart';

class ChordIdentificationProcess extends Process<Map<Duration, Chord?>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  /// The file where the chords for this [song] are cached.
  File get cacheFile => File("${song.cacheDirectory.path}/chords.json");

  /// Perform chord analysis on the [source] using the given [host].
  Future<Map> _analyzeSource(SongSource source, ChordsApiHost host) async {
    switch (source) {
      case FileSource():
        return await host.analyzeFile(source.file);
      case YoutubeSource():
        return await host.analyzeYoutubeSong(source.youtubeId);
      case DemixedSource():
        return await _analyzeSource(source.parent, host);
      default:
        throw "Chord analysis cannot be performed on the source $source.";
    }
  }

  @override
  Future<Map<Duration, Chord?>> execute() async {
    Map? chords;
    // Check cache
    if (await cacheFile.exists()) {
      try {
        chords = jsonDecode(await cacheFile.readAsString()) as Map;
      } catch (e) {
        debugPrint("[ANALYZER] Malformed chords file: '${cacheFile.path}'");
      }
    }

    breakIfCancelled();

    if (chords == null) {
      // Perform chords identification
      final ChordsApiHost host = await MusbxApi.findChordsHost();

      chords = await _analyzeSource(song.source, host);

      // Save to cache
      await cacheFile.create(recursive: true);
      await cacheFile.writeAsString(jsonEncode(chords));
    }

    breakIfCancelled();

    return chords.map((key, value) => MapEntry(
          Duration(milliseconds: (double.parse(key) * 1000).toInt()),
          Chord.tryParse(value),
        ));
  }
}
