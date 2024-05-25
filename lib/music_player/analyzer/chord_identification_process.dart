import 'package:musbx/music_player/musbx_api/chords_api.dart';
import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/process.dart';

class ChordIdentificationProcess extends Process<Map<Duration, String>> {
  /// Perform chord identification on a [song].
  ChordIdentificationProcess(this.song);

  /// The song being analyzed.
  final Song song;

  @override
  Future<Map<Duration, String>> process() async {
    final ChordsApiHost host = await MusbxApi.findChordsHost();

    // TODO: Maybe throw when cancelled, to avoid returning dummy data.
    if (isCancelled) return {};

    Map chords;
    if (song.source is FileSource) {
      chords = await host.analyzeFile(
        (song.source as FileSource).file,
      );
    } else {
      chords = await host.analyzeYoutubeSong(
        (song.source as YoutubeSource).youtubeId,
      );
    }

    if (isCancelled) return {};

    return chords.map((key, value) => MapEntry(
          Duration(milliseconds: (double.parse(key) * 1000).toInt()),
          value,
        ));
  }
}
