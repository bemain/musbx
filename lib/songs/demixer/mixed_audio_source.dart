import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/mixed_byte_stream.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/demixer/stem.dart';
import 'package:musbx/songs/player/music_player.dart';

class StemFileData {
  /// Helper class for matching data from a stem file to the type of the stem.
  StemFileData({required this.stemType, required this.fileData});

  /// The type of the stem that [fileData] comes from.
  final StemType stemType;

  /// Byte data from the file.
  final List<int> fileData;
}

class MixedAudioSource extends StreamAudioSource {
  /// An [AudioSource] that mixes multiple .wav files.
  ///
  /// All [files] must have the same duration.
  MixedAudioSource(this.files) : super(tag: 'MixedAudioSource');

  /// The files to mix.
  final Map<StemType, File> files;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print("[DEBUG] Request [$start - $end]");
    int sourceLength = await files.values.first.length();

    // TODO: Handle disable stems

    Stream<List<int>> mixed = MixedByteStream(
            files.entries.map((entry) => entry.value.openRead(start, end)))
        .map((List<List<int>> data) => mixWavFiles([
              for (int i = 0; i < data.length; i++)
                StemFileData(
                  stemType: files.entries.elementAt(i).key,
                  fileData: data[i],
                )
            ]));

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: (end ?? sourceLength) - (start ?? 0),
      offset: start ?? 0,
      stream: mixed,
      contentType: 'audio/wav',
    );
  }

  /// Mix multiple `wav` files together by taking the average value of each byte.
  ///
  /// 16 bits per sample and the files having identical headers is assumed.
  /// TODO: Check header for audio format (16, 32 bit...)
  List<int> mixWavFiles(List<StemFileData> dataLists) {
    Demixer demixer = MusicPlayer.instance.demixer;

    // By some reason, on iOS, the two first bytes are requested when the audio source is loaded.
    if (dataLists.first.fileData.length < 44) return dataLists.first.fileData;

    // Try to detect wav header
    // This method isn't fool proof (might by accident be these bytes at the start of the audio sample...) but it works for now
    bool headerPresent = dataLists.every((stemFileData) =>
        listEquals(
          stemFileData.fileData.sublist(0, 4), [82, 73, 70, 70], // RIFF
        ) &&
        listEquals(stemFileData.fileData.sublist(8, 16),
            [87, 65, 86, 69, 102, 109, 116, 32] // WAVEfmt
            ));

    List<List<double>> listsToMix = [];
    for (StemFileData stemFileData in dataLists) {
      Stem stem = demixer.stems
          .firstWhere((stem) => stem.type == stemFileData.stemType);

      List<int> data = headerPresent
          ? stemFileData.fileData.sublist(44) // Remove header
          : stemFileData.fileData;

      // Convert byte lists from 8 bit to 16 bit
      Uint16List uint16list = Uint8List.fromList(data).buffer.asUint16List();

      List<double> processedList = [
        for (var i = 0; i < uint16list.length; i++)
          // Shift all values to between `[-32768, 32767]`
          (fold(uint16list[i], 16) - 32768) * stem.volume // Apply volume
      ];
      listsToMix.add(processedList);
    }

    // Mix all byte lists into one
    List<int> mixed = [
      for (int i = 0; i < listsToMix.first.length; i++)
        (listsToMix.fold(0.0, (sum, list) => sum + list[i]) *
                4 / // Not sure why we multiply by 4 here...
                demixer.stems.length)
            .round()
    ];

    // Shift all values back to between `[0, 65536]`
    List<int> unshifted = [
      for (var i = 0; i < mixed.length; i++) (fold(mixed[i], 16) + 32768)
    ];

    // Convert back to 8 bit
    Uint8List uint8list = Uint16List.fromList(unshifted).buffer.asUint8List();

    if (headerPresent) {
      // Return header and then data
      return dataLists.first.fileData.sublist(0, 44) + uint8list;
    }

    return uint8list;
  }
}

/// Shifts int [x] of bit width [bits] up by half the total range, then wraps
/// any overflowing values around to maintain the bit width. This is used to
/// convert between signed and unsigned PCM.
int fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);
