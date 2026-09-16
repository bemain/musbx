import 'dart:io';

import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

/// Turns a song's [AudioReference] into audio the engine can play.
///
/// Whatever the reference points at — a URL, a file, raw bytes — the audio ends
/// up as one file in the cache, so a song is only ever fetched once.
class AudioRepository {
  AudioRepository({
    required SongCache songCache,
    required AudioEngineService audioPlayer,
  }) : _songCache = songCache;

  final SongCache _songCache;

  /// Fetch [song]'s audio unless it is already cached, and load it into the
  /// audio engine.
  Future<Result<File>> resolve(Song song) async {
    try {
      CacheFile cacheFile = _songCache.audio(song);

      await cacheFile.ensure(
        (scratch) async {
          switch (song.audio) {
            case UrlAudio(:final url):
              final MusbxApiClient client = await MusbxApi.getClient();
              final FileHandle handle = await client.uploadYtdlp(
                url,
                fileType: "mp3",
              );

              await client.download(handle, scratch);

            case FileAudio(:final file):
              if (!await file.exists()) {
                throw FileSystemException("File doesn't exist", file.path);
              }
              await file.copy(scratch.path);

            case BytesAudio(:final bytes):
              if (bytes == null) {
                throw Exception(
                  "[AUDIO] No bytes provided when constructing the BytesAudio, and the audio was not found in cache",
                );
              }
              await scratch.writeAsBytes(bytes);
          }
        },
      );

      return Result.ok(File(cacheFile.path));
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
