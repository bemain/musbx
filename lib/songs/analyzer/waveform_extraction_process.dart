import 'dart:async';
import 'dart:io' hide Process;

import 'package:just_waveform/just_waveform.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/song.dart';

class WaveformExtractionProcess extends Process<Waveform> {
  /// Perform waveform extraction on a [song].
  WaveformExtractionProcess(this.song);

  /// The song being processed.
  final Song song;

  /// Get the file were the waveform for [song] is saved.
  static File getWaveformFile(Song song) =>
      File("${song.cacheDirectory.path}/waveform.wave");

  @override
  Future<Waveform> execute() async {
    assert(
      Platform.isAndroid || Platform.isIOS,
      UnsupportedError(
        "Waveform extraction is not supported on the current platform",
      ),
    );

    final File outFile = getWaveformFile(song);
    if (await outFile.exists()) {
      // Use cached waveform
      return await JustWaveform.parse(outFile);
    }

    final AudioProvider source = song.audio;
    final File? inFile = source.cacheFile;
    if (inFile == null || !await inFile.exists()) {
      throw "File doesn't exist: $inFile";
    }

    breakIfCancelled();

    // Perform extraction
    final progressStream = JustWaveform.extract(
      audioInFile: inFile,
      waveOutFile: outFile,
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );

    await for (var event in progressStream) {
      breakIfCancelled();

      progressNotifier.value = event.progress;
      if (event.waveform != null) return event.waveform!;
    }
    throw "Waveform extraction never completed";
  }
}
