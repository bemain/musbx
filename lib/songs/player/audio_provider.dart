import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/utils/utils.dart';

/// An object that contains information about how to obtain an [AudioSource].
///
/// This is the first step in playing a song. The [AudioSource] obtained by calling
/// the [resolve] method can in turn be used to start playing a sound.
abstract class AudioProvider {
  /// Obtain the [AudioSource] that this provides.
  FutureOr<AudioSource> resolve({required Song song});

  /// Free the resources used by this provider.
  FutureOr<void> dispose() async {
    if (source != null) await SoLoud.instance.disposeSource(source!);
    source = null;
  }

  /// The file where audio data is cached.
  File? cacheFile;

  /// The [SoLoud] [AudioSource] that this provides.
  /// Will be `null` until this has been [resolve]d.
  AudioSource? source;

  /// Convert this to a json map.
  ///
  /// The map will contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map will contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file. \
  /// "demixed": `files` [Map<String, String>] The stem files.
  Json toJson();

  /// Try to create a [AudioProvider] from a json map.
  ///
  /// The map should contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map should contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file. \
  /// "demixed": `files` [Map<String, String>] The stem files.
  static AudioProvider? fromJson(Json json) {
    if (!json.containsKey("type")) return null;
    String? type = tryCast<String>(json['type']);

    switch (type) {
      case "ytdlp":
        return YtdlpAudio.fromJson(json);
      case "file":
        return FileAudio.fromJson(json);
    }
    return null;
  }
}

class YtdlpAudio extends AudioProvider {
  YtdlpAudio(this.url);

  final Uri url;

  @override
  Future<AudioSource> resolve({required Song song}) async {
    File cacheFile = File("${song.audioDirectory.path}/audio.mp3");

    if (!await cacheFile.exists()) {
      final MusbxApiClient client = await MusbxApi.getClient();
      final FileHandle handle = await client.uploadYtdlp(
        url,
        fileType: "mp3",
      );

      cacheFile = await client.download(handle, cacheFile);
    }
    this.cacheFile = cacheFile;

    source ??= await SoLoud.instance.loadFile(cacheFile.path);

    return source!;
  }

  /// Try to create a [YtdlpAudio] from a [json] object.
  static YtdlpAudio? fromJson(Json json) {
    if (!json.containsKey("url")) return null;
    String? url = tryCast<String>(json['url']);
    if (url == null) return null;

    return YtdlpAudio(Uri.parse(url));
  }

  @override
  Json toJson() => {
    "type": "ytdlp",
    "url": url.toString(),
  };
}

class BytesAudio extends AudioProvider {
  /// A source that constructs audio from raw bytes.
  BytesAudio(this.bytes);

  /// The bytes to construct the audio from.
  ///
  /// If this is `null`, the audio is expected to already be loaded into the [cacheFile]
  final Uint8List? bytes;

  @override
  Future<AudioSource> resolve({required Song song}) async {
    File cacheFile = File("${song.cacheDirectory.path}/audio.mp3");

    if (!await cacheFile.exists()) {
      if (bytes == null) {
        throw Exception(
          "[AUDIO] No bytes provided when constructing the BytesAudio, and the audio was not found in cache",
        );
      }

      await cacheFile.create(recursive: true);
      cacheFile = await cacheFile.writeAsBytes(bytes!);
    }
    this.cacheFile = cacheFile;

    source ??= await SoLoud.instance.loadFile(cacheFile.path);

    return source!;
  }

  /// Try to create a [FileAudio] from a [json] object.
  static BytesAudio? fromJson(Json json) => BytesAudio(null);

  @override
  Json toJson() => {
    "type": "bytes",
  };
}

class FileAudio extends AudioProvider {
  /// A source that reads audio from a file.
  FileAudio(this.file);

  /// The file to read.
  final File file;

  @override
  Future<AudioSource> resolve({required Song song}) async {
    final extension = file.path.split(".").last;
    File cacheFile = File("${song.cacheDirectory.path}/audio.$extension");

    if (!await cacheFile.exists()) {
      if (!await file.exists()) {
        throw FileSystemException("File doesn't exist", file.path);
      }

      await cacheFile.create(recursive: true);
      cacheFile = await file.copy(cacheFile.path);
    }
    this.cacheFile = cacheFile;

    source ??= await SoLoud.instance.loadFile(cacheFile.path);

    return source!;
  }

  /// Try to create a [FileAudio] from a [json] object.
  static FileAudio? fromJson(Json json) {
    if (!json.containsKey("path")) return null;
    String? path = tryCast<String>(json['path']);
    if (path == null) return null;

    return FileAudio(File(path));
  }

  @override
  Json toJson() => {
    "type": "file",
    "path": file.path,
  };
}
