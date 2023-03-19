import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/tuner/note.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Singleton for detecting what pitch is being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// The number of notes to take average of.
  static const int averageNotesN = 15;

  /// How many cents off a Note can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// Sample rate of the recording.
  late final double sampleRate;

  /// The amount of recorded data per sample, in bytes.
  late final int bufferSize;

  /// Whether the Tuner has been initialized or not.
  /// If true, [noteStream] has been created.
  bool initialized = false;

  /// The previous frequencies detected, unfiltered.
  final List<double> _frequencyHistory = [];

  /// The previous notes detected, averaged and filtered.
  final List<Note> noteHistory = [];

  /// The current note detected, or null if no pitch could be detected.
  late final Stream<Note?> noteStream;

  /// Initialize the Tuner.
  /// Creates the [noteStream] for detecting pitch from the microphone.
  ///
  /// Assumes permission to access the microphone has already been given.
  Future<void> initialize() async {
    final Stream<Uint8List>? audioStream = await MicStream.microphone(
      sampleRate: 16000,
      audioFormat: Platform.isIOS
          ? AudioFormat.ENCODING_PCM_16BIT
          : AudioFormat.ENCODING_PCM_8BIT,
    );
    if (audioStream == null) {
      throw "TUNER: Unable to capture audio from microphone";
    }
    int bitDepth = await MicStream.bitDepth!;
    sampleRate = await MicStream.sampleRate!;
    bufferSize = await MicStream.bufferSize!;

    print("Sample rate: $sampleRate");
    print("Buffer size: $bufferSize");
    print("bitDepth: $bitDepth");

    final Stream<PitchDetectorResult> pitchStream = audioStream.map((audio) {
      List<double> formattedAudio =
          (bitDepth == 16 ? audio.buffer.asUint16List(0, bufferSize) : audio)
              .map((int val) => val.toDouble())
              .toList();

      // print("audio: ${audio.length}");
      // print("formattedAudio: ${formattedAudio.length}");

      final PitchDetector pitchDetector = PitchDetector(sampleRate, bufferSize);

      return pitchDetector.getPitch(formattedAudio);
    });

    noteStream = pitchStream.map((result) {
      if (result.pitched) {
        _frequencyHistory.add(result.pitch);
        Note? avgNote = _getAverageNote();
        if (avgNote != null) {
          noteHistory.add(avgNote);
          return avgNote;
        }
      }
      return null;
    });

    pitchStream.listen((event) {
      if (event.pitch != -1) print(event.pitch);
    });

    initialized = true;
  }

  /// Calculate the average of the last [averageNotesN] frequencies.
  Note? _getAverageNote() {
    List<double> previousFrequencies = _frequencyHistory
        // Only the [averageNotesN] last entries
        .sublist(max(0, _frequencyHistory.length - averageNotesN))
        // Only frequencies close to the current
        .where((frequency) => (frequency - _frequencyHistory.last).abs() < 10)
        .toList();

    if (previousFrequencies.length <= averageNotesN / 3) return null;

    return Note.fromFrequency(previousFrequencies.reduce((a, b) => a + b) /
        previousFrequencies.length);
  }
}
