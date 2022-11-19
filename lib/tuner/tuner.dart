import 'dart:async';
import 'dart:math';

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
    final Stream<List<int>>? audioStream = await MicStream.microphone();
    if (audioStream == null) {
      throw "TUNER: Unable to capture audio from microphone";
    }
    sampleRate = await MicStream.sampleRate!;
    bufferSize = await MicStream.bufferSize!;

    final PitchDetector pitchDetector = PitchDetector(sampleRate, bufferSize);
    final Stream<PitchDetectorResult> pitchStream = audioStream.map((audio) =>
        pitchDetector
            .getPitch(audio.map((int val) => val.toDouble()).toList()));

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

    initialized = true;
  }

  /// Calculate the average of the last [averageNotesN] frequencies and add a
  /// [Note] with that frequency to [noteHistory].
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
