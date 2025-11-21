import 'dart:io';

import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';

class DemixingProcesses {
  DemixingProcesses._();

  /// The processes that are currently running.
  static final Map<Song, DemixingProcess> processes = {};

  /// Start a new process that demixes [song], if one isn't already running or completed.
  static DemixingProcess start(Song song) {
    DemixingProcess? process = get(song);
    if (process?.isCancelled == true) {
      process = null;
    }

    process ??=
        DemixingProcess(
          song.source,
          cacheDirectory: Directory("${song.cacheDirectory.path}/source/"),
        )..addListener(() {
          if (song.source is! DemixedSource && process?.hasResult == true) {
            /// Override the history entry for the song with a demixed variant.
            Songs.history.add(
              song.withSource<MultiPlayable>(
                DemixedSource(song.source),
              ),
            );
          }
        });

    processes[song] = process;
    return process;
  }

  /// Start a demixing process for each song in [songs], if they aren't already running.
  static List<DemixingProcess> startAll(Iterable<Song> songs) {
    return songs.map(start).toList();
  }

  /// Get the process that is demixing a [song], if any.
  static DemixingProcess? get(Song song) {
    return processes[song];
  }

  /// Cancel the process that is demixing a [song], if any.
  static void cancel(Song song) {
    final process = processes.remove(song);
    process?.cancel();
  }
}
