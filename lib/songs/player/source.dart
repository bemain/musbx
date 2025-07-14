import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/widgets/widgets.dart';

/// An object that contains information about how to [load] a [Playable].
///
/// This is the first step in playing a song. The [Playable] obtained by calling
/// the [load] method can in turn be used to start playing a sound.
abstract class SongSource<P extends Playable> {
  /// Load the [Playable] that this source points to.
  FutureOr<P> load({required Directory cacheDirectory});

  /// Free the resources used by this source.
  FutureOr<void> dispose() {}

  /// Convert this to a json map.
  ///
  /// The map will contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map will contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file. \
  /// "demixed": `files` [Map<String, String>] The stem files.
  Map<String, dynamic> toJson();

  /// Try to create a [SongSource] from a json map.
  ///
  /// The map should contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map should contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file. \
  /// "demixed": `files` [Map<String, String>] The stem files.
  static SongSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("type")) return null;
    String? type = tryCast<String>(json["type"]);

    switch (type) {
      case "youtube":
        return YoutubeSource.fromJson(json);
      case "file":
        return FileSource.fromJson(json);
      case "demixed":
        return DemixedSource.fromJson(json);
    }
    return null;
  }
}

class YoutubeSource extends SongSource<SinglePlayable> {
  /// A source that pulls audio from YouTube.
  YoutubeSource(this.youtubeId);

  /// The id of the YouTube song to pull.
  final String youtubeId;

  /// The [SoLoud] [AudioSource] that is generated from this source.
  AudioSource? source;

  /// The file where audio data is cached.
  File? cacheFile;

  @override
  Future<SinglePlayable> load({required Directory cacheDirectory}) async {
    File cacheFile = File("${cacheDirectory.path}/audio.mp3");

    if (await cacheFile.exists()) {
      debugPrint("[YOUTUBE] Using cached audio for video with id '$youtubeId'");
    } else {
      cacheFile = await (await MusbxApi.findYoutubeHost()).downloadYoutubeSong(
        youtubeId,
        destination: cacheFile,
        fileType: "mp3",
      );
    }
    this.cacheFile = cacheFile;

    source ??= await SoLoud.instance.loadFile(cacheFile.path);

    return SinglePlayable(source!);
  }

  @override
  Future<void> dispose() async {
    if (source == null) return;

    await SoLoud.instance.disposeSource(source!);
    source = null;
  }

  /// Try to create a [YoutubeSource] from a [json] object.
  static YoutubeSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("youtubeId")) return null;
    String? id = tryCast<String>(json["youtubeId"]);
    if (id == null) return null;

    return YoutubeSource(id);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "youtube",
        "youtubeId": youtubeId,
      };
}

class FileSource extends SongSource<SinglePlayable> {
  /// A source that reads audio from a file.
  FileSource(this.file);

  /// The file to read.
  final File file;

  /// The [SoLoud] [AudioSource] that is generated from this source.
  AudioSource? source;

  /// The file where audio data is cached.
  File? cacheFile;

  @override
  Future<SinglePlayable> load({required Directory cacheDirectory}) async {
    File cacheFile = File("${cacheDirectory.path}/audio.mp3");

    if (!await cacheFile.exists()) {
      if (!await file.exists()) {
        throw FileSystemException("File doesn't exist", file.path);
      }

      await cacheFile.create(recursive: true);
      cacheFile = await file.copy(cacheFile.path);
    }
    this.cacheFile = cacheFile;

    source ??= await SoLoud.instance.loadFile(cacheFile.path);

    return SinglePlayable(source!);
  }

  @override
  Future<void> dispose() async {
    if (source == null) return;

    await SoLoud.instance.disposeSource(source!);
    source = null;
  }

  /// Try to create a [FileSource] from a [json] object.
  static FileSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("path")) return null;
    String? path = tryCast<String>(json["path"]);
    if (path == null) return null;

    return FileSource(File(path));
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "file",
        "path": file.path,
      };
}

class DemixedSource extends SongSource<MultiPlayable> {
  /// A source that demixes a [Song] and loads the stems as a `MultiPlayable`.
  DemixedSource(this.parent);

  final SongSource parent;

  /// The first source above this that is a [SinglePlayable].
  SongSource<SinglePlayable> get rootParent => parent is DemixedSource
      ? (parent as DemixedSource).rootParent
      : parent as SongSource<SinglePlayable>;

  Map<StemType, AudioSource>? sources;

  @override
  Future<MultiPlayable> load({required Directory cacheDirectory}) async {
    final DemixingProcess process = DemixingProcess(
      parent,
      cacheDirectory: cacheDirectory,
    );

    final Map<StemType, File> files = await process.future;

    await parent.load(cacheDirectory: cacheDirectory);

    sources ??= {
      for (final e in files.entries)
        e.key: await SoLoud.instance.loadFile(e.value.path),
    };
    return MultiPlayable(sources!);
  }

  @override
  Future<void> dispose() async {
    if (sources == null) return;

    await Future.wait([
      for (final source in sources!.values)
        SoLoud.instance.disposeSource(source),
    ]);
    sources = null;

    await parent.dispose();
  }

  /// Try to create a [DemixedSource] from a [json] object.
  static DemixedSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("parent")) return null;
    SongSource? parent = SongSource.fromJson(json["parent"]);
    if (parent == null) return null;

    return DemixedSource(parent);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "demixed",
        "parent": {
          ...parent.toJson(),
        }
      };
}
