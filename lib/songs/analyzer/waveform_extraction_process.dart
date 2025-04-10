import 'dart:async';
import 'dart:io';

import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/utils/process.dart';

class WaveformExtractionProcess extends Process<Waveform> {
  /// Perform waveform extraction on a [song].
  WaveformExtractionProcess(this.song);

  /// The song being processed.
  final SongNew song;

  /// Get the file were the waveform for [song] is saved.
  static Future<File> getWaveformFile(SongNew song) async =>
      File("${(await song.cacheDirectory).path}/waveform.wave");

  /// Get the file where the audio for [source] is cached.
  File? _cacheFile(SongSourceNew source) {
    if (source case DemixedSource()) {
      print("[DEBUG] Demixed source with parent ${source.parent}");
    }
    return switch (source) {
      FileSource() => source.cacheFile,
      YoutubeSource() => source.cacheFile,
      DemixedSource() => _cacheFile(source.parent),
      _ => null,
    };
  }

  @override
  Future<Waveform> process() async {
    final File outFile = await getWaveformFile(song);
    if (await outFile.exists()) {
      // Use cached waveform
      return await JustWaveform.parse(outFile);
    }

    final SongSourceNew source = song.source;
    final File? inFile = _cacheFile(source);
    if (inFile == null || !await inFile.exists()) {
      throw "File doesn't exist: $inFile";
    }

    breakIfCancelled();

    // Perform extraction
    final progressStream = JustWaveform.extract(
      audioInFile: inFile,
      waveOutFile: outFile,
      zoom: const WaveformZoom.pixelsPerSecond(
          100), // TODO: Try changing this value
    );

    await for (var event in progressStream) {
      breakIfCancelled();

      progressNotifier.value = event.progress;
      if (event.waveform != null) return event.waveform!;
    }
    throw "Waveform extraction never completed";
  }
}
