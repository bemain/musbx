import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/songs/musbx_api/client.dart';
import 'package:musbx/songs/musbx_api/jobs/analyze.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/process.dart';
import 'package:musbx/utils/utils.dart';

class ChordIdentificationProcess extends Process<Map<Duration, Chord?>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  /// The file where the chords for this [song] are cached.
  File get cacheFile => File("${song.cacheDirectory.path}/chords.json");

  @override
  Future<Map<Duration, Chord?>> execute() async {
    Map<double, String>? data;
    // Check cache
    if (await cacheFile.exists()) {
      try {
        final Json json = jsonDecode(await cacheFile.readAsString()) as Json;
        data = json.map(
          (key, value) => MapEntry(
            double.parse(key),
            value as String,
          ),
        );
      } catch (e) {
        debugPrint("[ANALYZER] Malformed chords file: '${cacheFile.path}'");
      }
    }

    breakIfCancelled();

    if (data == null) {
      // Perform chords identification
      final MusbxApiClient client = await MusbxApi.getClient();

      data = await analyzeSource(song.source, client);

      // Save to cache
      await cacheFile.create(recursive: true);
      await cacheFile.writeAsString(
        jsonEncode(data.map((key, value) => MapEntry("$key", value))),
      );
    }

    breakIfCancelled();

    return data.map(
      (key, value) => MapEntry(
        Duration(milliseconds: (key * 1000).toInt()),
        Chord.tryParse(value),
      ),
    );
  }

  /// Perform chord analysis on the [source] using the given [client].
  Future<Map<double, String>> analyzeSource(
    SongSource source,
    MusbxApiClient client,
  ) async {
    final FileHandle file;
    switch (source) {
      case FileSource():
        file = await client.uploadFile(source.cacheFile!);
      case YtdlpSource():
        file = await client.uploadYtdlp(source.url);

      default:
        throw UnsupportedError(
          "Chord analysis cannot be performed on the source $source.",
        );
    }

    final AnalyzeJob job = await client.analyze(file);
    return await job.complete();
  }
}
