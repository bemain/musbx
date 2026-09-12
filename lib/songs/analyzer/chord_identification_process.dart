import 'dart:io' hide Process;

import 'package:flutter/material.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/jobs/analyze.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/process.dart';
import 'package:musbx/utils/utils.dart';

// TODO: Make this just a Future<Result<...>>
class ChordIdentificationProcess extends Process<Map<Duration, Chord?>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  /// The file where the chords for this [song] are cached.
  CacheFile get cacheFile => SongCache.instance.chords(song);

  @override
  Future<Map<Duration, Chord?>> execute() async {
    Map<double, String>? data;
    // Check cache
    try {
      final Json? json = await cacheFile.readJson();
      if (json != null) {
        data = json.map(
          (key, value) => MapEntry(
            double.parse(key),
            value as String,
          ),
        );
      }
    } catch (e) {
      debugPrint("[ANALYZER] Malformed chords file: '${cacheFile.path}'");
    }

    breakIfCancelled();

    if (data == null) {
      // Perform chords identification
      final MusbxApiClient client = await MusbxApi.getClient();
      data = await analyzeSource(song.audio, client);

      // Save to cache
      await cacheFile.writeJson(
        data.map((key, value) => MapEntry("$key", value)),
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
    AudioReference source,
    MusbxApiClient client,
  ) async {
    final FileHandle file;
    switch (source) {
      case FileAudio() || BytesAudio():
        file = await client.uploadFile(
          File(SongCache.instance.audio(song).path),
        );
      case UrlAudio():
        file = await client.uploadYtdlp(source.url);
    }

    final AnalyzeJob job = await client.analyze(file);
    return await job.complete();
  }
}
