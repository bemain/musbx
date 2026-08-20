import 'dart:convert';
import 'dart:io' hide Process;

import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/jobs/analyze.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/utils/utils.dart';

class ChordIdentificationProcess extends Process<Map<Duration, Chord?>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  /// The file where the chords for this [song] are cached.
  CacheFile get cacheFile => song.cacheDirectory.file("chords.json");

  @override
  Future<Map<Duration, Chord?>> execute() async {
    Map<double, String>? data;
    // Check cache
    final String? s = await cacheFile.readString();
    if (s != null) {
      try {
        final Json json = jsonDecode(s) as Json;
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

      data = await analyzeSource(song.audio, client);

      // Save to cache
      await cacheFile.writeString(
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
    AudioProvider source,
    MusbxApiClient client,
  ) async {
    final FileHandle file;
    switch (source) {
      case FileAudio() || BytesAudio():
        file = await client.uploadFile(File(source.cacheFile!.path));
      case YtdlpAudio():
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
