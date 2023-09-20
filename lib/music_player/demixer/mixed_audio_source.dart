import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:just_audio/just_audio.dart';

class MixedAudioSource extends StreamAudioSource {
  /// An [AudioSource] that mixes multiple .wav files.
  ///
  /// All [files] must have the same duration
  MixedAudioSource(this.files) : super(tag: 'MixedAudioSource');

  final List<File> files;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print("[DEMIXER] Request ($start, $end)");
    int sourceLength = await files.first.length();

    Iterable<Stream<List<int>>> streams =
        files.map((file) => file.openRead(start, end));

    Stream<List<int>> mixed = StreamZip<List<int>>(streams).map(mixByteLists);

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: (end ?? sourceLength) - (start ?? 0),
      offset: start ?? 0,
      stream: mixed,
      contentType: 'audio/wav',
    );
  }
}

/// Shifts int [x] of bit width [bits] up by half the total range, then wraps
/// any overflowing values around to maintain the bit width. This is used to
/// convert between signed and unsigned PCM.
int fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);

List<int> mixByteLists(List<List<int>> byteLists) {
  // Assumes all headers are equal
  // TODO: Remove "clicking" noise caused be the headers not being equal
  List<int> header = byteLists.first.sublist(0, 44);
  List<List<int>> contents =
      byteLists.map((byteList) => byteList.sublist(44)).toList();

  // TODO: Check header for audio format (16, 32 bit...)
  // Assumes 16 bits per sample

  /// Convert byte lists from 8 bit to 16 bit.
  List<Uint16List> uint16lists = [
    for (final content in contents)
      Uint8List.fromList(content).buffer.asUint16List()
  ];

  /// Shift all values to make them signed (between `[-32768, 32767]` instead of `[0, 65536]`).
  List<List<int>> shiftedLists = [
    for (final uint16list in uint16lists)
      [for (var i = 0; i < uint16list.length; i++) fold(uint16list[i], 16)]
  ];

  // TODO: Consider volume of each wav

  /// Mix all byte lists into one.
  List<int> mixed = [
    for (int i = 0; i < shiftedLists.first.length; i++)
      shiftedLists.fold(0.0, (sum, shiftedList) => sum + shiftedList[i]) ~/ 4
  ];

  /// Shift all values back to between `[0, 65536]`.
  List<int> unshifted = [
    for (var i = 0; i < mixed.length; i++) fold(mixed[i], 16)
  ];

  /// Convert back to 8 bit.
  Uint8List uint8list = Uint16List.fromList(unshifted).buffer.asUint8List();

  return header + uint8list;
}
