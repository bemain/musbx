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

  @override
  Future<Map<Duration, Chord?>> execute() async {
    Map<String, dynamic>? data;
    // Check cache
    if (await cacheFile.exists()) {
      try {
        data = jsonDecode(await cacheFile.readAsString());
      } catch (e) {
        debugPrint("[ANALYZER] Malformed chords file: '${cacheFile.path}'");
      }
    }

    breakIfCancelled();

    if (data == null) {
      // Perform chords identification
      final ChordsApiHost host = await MusbxApi.findChordsHost();

      data = await analyzeSource(song.source, host);

      // Save to cache
      await cacheFile.create(recursive: true);
      await cacheFile.writeAsString(jsonEncode(data));
    }

    breakIfCancelled();

    return data.map((key, value) => MapEntry(
          Duration(milliseconds: (double.parse(key) * 1000).toInt()),
          Chord.tryParse(value),
        ));
  }

  /// Perform chord analysis on the [source] using the given [host].
  Future<Map<String, dynamic>> analyzeSource(
      SongSource source, ChordsApiHost host) async {
    switch (source) {
      case FileSource():
        return await host.analyzeFile(source.file);
      case YoutubeSource():
        return await host.analyzeYoutubeSong(source.youtubeId);
      case DemixedSource():
        return await analyzeSource(source.parent, host);
      default:
        throw "Chord analysis cannot be performed on the source $source.";
    }
  }
}
