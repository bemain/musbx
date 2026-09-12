import 'dart:async';
import 'dart:io' hide Process;

import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/process.dart';

// TODO: Make this just a Future<Result<...>>
class WaveformExtractionProcess extends Process<Waveform> {
  /// Perform waveform extraction on a [song].
  WaveformExtractionProcess(this.song);

  /// The song being processed.
  final Song song;

  /// Get the file were the waveform for [song] is saved.
  static CacheFile getWaveformFile(Song song) =>
      SongCache.instance.waveform(song);

  @override
  Future<Waveform> execute() async {
    assert(
      Platform.isAndroid || Platform.isIOS,
      UnsupportedError(
        "Waveform extraction is not supported on the current platform",
      ),
    );

    final CacheFile outFile = getWaveformFile(song);
    if (await outFile.exists()) {
      // Use cached waveform
      return await JustWaveform.parse(File(outFile.path));
    }

    final CacheFile inFile = SongCache.instance.audio(song);
    if (!await inFile.exists()) {
      throw FileSystemException("File doesn't exist", inFile.path);
    }

    breakIfCancelled();

    // Perform extraction
    final progressStream = JustWaveform.extract(
      audioInFile: File(inFile.path),
      waveOutFile: File(outFile.path),
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );

    await for (var event in progressStream) {
      breakIfCancelled();

      progressNotifier.value = event.progress;
      if (event.waveform != null) return event.waveform!;
    }
    throw Exception("Waveform extraction never completed");
  }
}
