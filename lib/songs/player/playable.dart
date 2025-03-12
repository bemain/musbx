import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/musbx_api/youtube_api.dart';
import 'package:musbx/widgets/widgets.dart';

/// An object that contains information about how to [load] a [Playable].
///
/// This is the first step in playing a song. The [Playable] obtained by calling
/// the [load] method can in turn be used to start playing a sound.
abstract class SongSourceNew {
  /// Load the [Playable] that this source points to.
  FutureOr<Playable> load();

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

  /// Try to create a [SongSourceNew] from a json map.
  ///
  /// The map should contain at least the following key:
  /// - `type` [String] The type of the source.
  ///
  /// Depending on the type, the map should contain some additional keys. \
  /// "youtube": `youtubeId` [String] The id of the Youtube song. \
  /// "file": `path` [String] The path to the file. \
  /// "demixed": `files` [Map<String, String>] The stem files.
  static SongSourceNew? fromJson(Map<String, dynamic> json) {
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

/// An object that can be played by [SongPlayer].
///
/// It wraps around [SoLoud]'s [AudioSource] and exposes a [play] method that
/// the [SongPlayer] calls when it wants to start playing the song.
///
/// Note that this class is not instantiable directly but should be obtained
/// through a [SongSourceNew], which containes instructions on how a Playable is created.
/// When you are done playing this sound you should [dispose] it to free up resources.
abstract class Playable {
  /// Play this sound using [SoLoud] and return the handle to the sound.
  FutureOr<SoundHandle> play({bool paused = true, bool looping = true});

  /// The length of the audio that this plays.
  ///
  /// Before accessing this, make sure [play] has been called.
  Duration get duration;

  /// Free the resources used by this object.
  FutureOr<void> dispose();
}

class YoutubeSource extends SongSourceNew {
  /// A source that pulls audio from YouTube.
  YoutubeSource(this.youtubeId);

  /// The id of the YouTube song to pull.
  final String youtubeId;

  @override
  Future<Playable> load() async {
    File? file = await _getAudioFromCache();
    file ??= await (await MusbxApi.findYoutubeHost()).downloadYoutubeSong(
      youtubeId,
    );

    return FileAudio._(file);
  }

  Future<File?> _getAudioFromCache() async {
    for (final String extension in allowedExtensions) {
      final File file =
          await YoutubeApiHost.getYoutubeFile(youtubeId, extension);
      if (await file.exists()) {
        debugPrint(
            "[YOUTUBE] Using cached audio for video with id '$youtubeId'");
        return file;
      }
    }
    return null;
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

class FileSource extends SongSourceNew {
  /// A source that reads audio from a file.
  FileSource(this.file);

  /// The file to read.
  final File file;

  @override
  Future<Playable> load() async {
    if (!await file.exists()) {
      throw FileSystemException("File doesn't exist", file.path);
    }

    return FileAudio._(file);
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

class DemixedSource extends SongSourceNew {
  /// A source that reads multiple [files], to be played simultaneously.
  DemixedSource(this.files);

  /// The files to read.
  final Map<StemType, File> files;

  @override
  Future<DemixedAudio> load() async {
    return DemixedAudio._(files);
  }

  /// Try to create a [DemixedSource] from a [json] object.
  static DemixedSource? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("files")) return null;
    Map? files = tryCast<Map>(json["files"]);
    if (files == null) return null;

    Map<StemType, File> stems = {};
    for (final e in files.entries) {
      String? type = tryCast<String>(e.key);
      String? path = tryCast<String>(e.value);
      if (type == null || path == null) continue;

      stems[StemType.values.firstWhere((element) => element.name == type)] =
          File(path);
    }

    return DemixedSource(stems);
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": "demixed",
        "files": {
          for (final e in files.entries) e.key.name: e.value.path,
        },
      };
}

class FileAudio extends Playable {
  /// A [Playable] that plays a single file.
  FileAudio._(this.file);

  /// The file played by this Playable.
  final File file;

  /// The source of the sound that is played.
  AudioSource? source;

  @override
  Duration get duration => SoLoud.instance.getLength(source!);

  @override
  FutureOr<SoundHandle> play({bool paused = true, bool looping = true}) async {
    source ??= await SoLoud.instance.loadFile(file.path);

    return await SoLoud.instance.play(
      source!,
      paused: paused,
      looping: looping,
    );
  }

  @override
  FutureOr<void> dispose() async {
    if (source != null) await SoLoud.instance.disposeSource(source!);
    source = null;
  }
}

class DemixedAudio extends Playable {
  /// A [Playable] that provides a voice group with a number of [files].
  ///
  /// This allows the files to play simultaneously while the volume can be controlled individually.
  DemixedAudio._(this.files);

  /// The files that this Playable plays simultaneously.
  final Map<StemType, File> files;

  /// The sources of the individual sounds that are played simultaneously.
  Map<StemType, AudioSource>? sources;

  /// The handles of the individual sounds that are played simultaneously.
  Map<StemType, SoundHandle>? handles;

  @override
  Duration get duration => SoLoud.instance.getLength(sources!.values.first);

  @override
  Future<SoundHandle> play({bool paused = true, bool looping = true}) async {
    sources ??= {
      for (final e in files.entries)
        e.key: await SoLoud.instance.loadFile(e.value.path),
    };
    handles ??= {
      for (final e in sources!.entries)
        e.key: await SoLoud.instance.play(
          e.value,
          paused: paused,
          looping: looping,
        ),
    };

    final SoundHandle groupHandle = SoLoud.instance.createVoiceGroup();
    SoLoud.instance.addVoicesToGroup(
      groupHandle,
      handles!.values.toList(),
    );
    return groupHandle;
  }

  @override
  Future<void> dispose() async {
    if (sources == null) return;

    await Future.wait([
      for (final source in sources!.values)
        SoLoud.instance.disposeSource(source),
    ]);
    sources = null;
    handles = null;
    // TODO: Do we need to destroy the voice handle specifically or is the SongPlayer's call to stop() enough?
  }
}
