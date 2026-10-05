import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/jobs/analyze.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/utils/utils.dart';

/// Analyses songs through the Musbx API, caching every result on disk.
///
/// Both analyses are expensive enough to only ever run once per song: a cached
/// result short-circuits the work. Chords are identified server-side, while
/// waveforms are extracted locally and only on mobile.
class AnalysisRepositoryRemote extends AnalysisRepository {
  AnalysisRepositoryRemote({
    required SongCache cache,
  }) : _cache = cache;

  final SongCache _cache;

  @override
  Future<Result<Map<Duration, Chord?>>> chords(Song song) async {
    try {
      final cacheFile = _cache.chords(song);
      Map<double, String>? data;
      // Check cache
      final Json? json = await cacheFile.readJson();
      if (json != null) {
        data = json.map(
          (key, value) => MapEntry(
            double.parse(key),
            value as String,
          ),
        );
      }

      if (data == null) {
        final client = await MusbxApi.getClient();
        // Perform chords identification
        final FileHandle file;
        switch (song.audio) {
          case FileAudio() || BytesAudio():
            file = await client.uploadFile(
              File(_cache.audio(song).path),
            );
          case UrlAudio(:final url):
            file = await client.uploadYtdlp(url);
        }

        final AnalyzeJob job = await client.analyze(file);
        data = await job.complete();

        // Save to cache
        await cacheFile.writeJson(
          data.map((key, value) => MapEntry("$key", value)),
        );
      }

      return Result.ok(
        data.map(
          (key, value) => MapEntry(
            Duration(milliseconds: (key * 1000).toInt()),
            Chord.tryParse(value),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint("[ANALYZER] Chord analysis failed: $e'");
      return Result.failed(e, s);
    }
  }

  @override
  Future<Result<Waveform>> waveform(Song song) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return Result.unavailable(
          "Waveform extraction is only available on mobile",
        );
      }

      final CacheFile outFile = _cache.waveform(song);
      if (await outFile.exists()) {
        // Use cached waveform
        return Result.ok(await JustWaveform.parse(File(outFile.path)));
      }

      final CacheFile inFile = _cache.audio(song);
      if (!await inFile.exists()) {
        throw FileSystemException("File doesn't exist", inFile.path);
      }

      // Perform extraction
      final progressStream = JustWaveform.extract(
        audioInFile: File(inFile.path),
        waveOutFile: File(outFile.path),
        zoom: const WaveformZoom.pixelsPerSecond(100),
      );

      await for (var event in progressStream) {
        if (event.waveform != null) return Result.ok(event.waveform!);
      }
      throw Exception("Waveform extraction never completed");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
