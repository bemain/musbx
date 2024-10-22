import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer.dart';
import 'package:musbx/music_player/musbx_api/demixer_api.dart';
import 'package:musbx/music_player/demixer/stem.dart';
import 'package:musbx/music_player/music_player.dart';

class StemFileData {
  /// Helper class for matching data from a stem file to the type of the stem.
  StemFileData({required this.stemType, required this.fileData});

  /// The type of the stem that [fileData] comes from.
  final StemType stemType;

  /// Byte data from the file.
  final List<int> fileData;
}

class StemReader<T> {
  StemReader(this.stemType, Stream<List<T>> stream)
      : reader = ChunkedStreamReader(stream);

  final StemType stemType;
  final ChunkedStreamReader<T> reader;
}

class _ChunkSplitterSink implements EventSink<List<int>> {
  final EventSink<List<int>> _sink;

  /// The carry-over from the previous chunk.
  List<int> _carry = [];

  final int chunkSize;

  _ChunkSplitterSink(this._sink, this.chunkSize);

  @override
  void add(List<int> data) {
    if (data.isEmpty) close();

    // Add the carry from the previous iteration
    data = _useCarry(data);

    // Extract full chunks
    while (data.length >= chunkSize) {
      _sink.add(data.sublist(0, chunkSize));
      data.removeRange(0, chunkSize);
    }

    // Save the remaining data in carry
    _carry.addAll(data);
  }

  @override
  void close() {
    if (_carry.isNotEmpty) {
      _sink.add(_useCarry(<int>[]));
    }

    _sink.close();
  }

  /// Consumes and combines existing carry-over with continuation string.
  ///
  /// The [continuation] is only empty if called from [close].
  List<int> _useCarry(List<int> continuation) {
    final carry = _carry;
    _carry = [];
    return [...carry, ...continuation];
  }

  @override
  void addError(Object o, [StackTrace? stackTrace]) {
    _sink.addError(o, stackTrace);
  }
}

class MixedAudioSource extends StreamAudioSource {
  /// An [AudioSource] that mixes multiple .wav files.
  ///
  /// All [files] must have the same duration.
  MixedAudioSource(this.files) : super(tag: 'MixedAudioSource');

  /// The files to mix.
  final Map<StemType, File> files;

  /// The number of bytes per chunk.
  final int chunkSize = 4096;

  /// The duration of each chunk
  late final Duration chunkDuration = Duration(
    microseconds: (1e6 * chunkSize / (44100 * 4)).toInt(),
  );

  final int chunksBuffered = 10;

  late final StreamTransformer<List<int>, List<int>> chunkSplitter =
      StreamTransformer.fromBind(
    (stream) => Stream<List<int>>.eventTransformed(
      stream,
      (EventSink<List<int>> sink) => _ChunkSplitterSink(sink, chunkSize),
    ),
  );

  // TODO: Maybe dispose this somehow?
  late final Stream<Duration> positionStream = MusicPlayer.instance.player
      .createPositionStream(
        minPeriod: chunkDuration,
        maxPeriod: chunkDuration,
      )
      .asBroadcastStream();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    int sourceLength = await files.values.first.length();
    print("[DEBUG] Request $start - $end, sourceLength $sourceLength");

    int currentByteOffset = start ?? 0;

    StreamZip<StemFileData> readStreams = StreamZip<StemFileData>(files.entries
        // Open files for reading
        .map((entry) => entry.value
            .openRead(start, end)
            .transform(chunkSplitter)
            .map((data) => StemFileData(stemType: entry.key, fileData: data)))
        .toList());
    Stream<List<int>> mixed = readStreams
        // Block samples until they are actually needed, to prevent the stems from being mixed in advance
        .asyncMap((data) async {
      /// The position of the current song that the [data] snapshot shows up at.
      final Duration snapshotPosition = Duration(
        microseconds: (1e6 * (currentByteOffset - 44) / (44100 * 4))
            .toInt(), // Why do we multiply sample rate by 4?
      );

      currentByteOffset += data.first.fileData.length;
      print(
          "[DEBUG] Sample at $snapshotPosition with length ${data.first.fileData.length}, current position is ${MusicPlayer.instance.position}");

      if (snapshotPosition - MusicPlayer.instance.position <=
          chunkDuration * chunksBuffered) {
        print(
            "[DEBUG] Instantly handing out ${data.first.fileData.length} bytes of data at $snapshotPosition");
        return data;
      }

      // Don't return until this sample is needed.
      await for (final Duration position in positionStream) {
        if (snapshotPosition - position <= chunkDuration * chunksBuffered) {
          print(
              "[DEBUG] Handing out ${data.length} bytes of data at $snapshotPosition");
          return data;
        }
      }
      return <StemFileData>[];
    })
        // Mix
        .map(mixWavFiles);

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
          stemFileData.fileData.sublist(0, 4),
          [82, 73, 70, 70], // RIFF
        ) &&
        listEquals(
          stemFileData.fileData.sublist(8, 16),
          [87, 65, 86, 69, 102, 109, 116, 32], // WAVEfmt
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
          (fold(uint16list[i], 16) - 32768) *
              (stem.enabled ? stem.volume : 0) // Apply volume
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
