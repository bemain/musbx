import 'dart:async';
import 'dart:io';

import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/music_player/analyzer/analyzer.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/process.dart';

class WaveformExtractionProcess extends Process<Waveform> {
  /// Perform waveform extraction on a [song].
  WaveformExtractionProcess(this.song);

  /// The song being processed.
  final Song song;

  /// Get the file were the waveform for [song] is saved.
  static Future<File> getWaveformFile(Song song) async =>
      File("${(await Analyzer.analyzerDirectory).path}/${song.id}.wave");

  @override
  Future<Waveform> process() async {
    final File inFile = song.source is YoutubeSource
        ? (song.source as YoutubeSource).cacheFile
        : (song.source as FileSource).file;
    if (!await inFile.exists()) throw "File doesn't exist $inFile";

    final File outFile = await getWaveformFile(song);
    if (await outFile.exists()) {
      // Use cached waveform
      return await JustWaveform.parse(outFile);
    }

    // Perform extraction
    final progressStream = JustWaveform.extract(
      audioInFile: inFile,
      waveOutFile: outFile,
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );

    await for (var event in progressStream) {
      progressNotifier.value = event.progress;
      if (event.waveform != null) return event.waveform!;
    }
    throw "Waveform extraction never completed";
  }
}
