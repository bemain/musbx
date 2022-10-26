import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/tuner/note.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Singleton for getting the pitch being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// The pitch detected from the microphone.
  late final Stream<PitchDetectorResult> pitchStream;

  /// Future for creating [pitchStream].
  late final Future initAudioFuture = initAudio();

  /// The most previous note detected.
  final ValueNotifier<Note?> currentNoteNotifier = ValueNotifier(null);
  Note? get currentNote => currentNoteNotifier.value;

  /// The number of notes to take average of.
  static const int averageNotesN = 10;

  final List<double> _frequencyHistory = [];

  /// The previous notes detected.
  final List<Note> noteHistory = [Note.a4()];

  /// Create the stream for getting pitch from microphone.
  Future<void> initAudio() async {
    final Stream<List<int>>? audioStream =
        await MicStream.microphone(sampleRate: 44100);
    assert(
      audioStream != null,
      "TUNER: Unable to capture audio from microphone",
    );

    final PitchDetector pitchDetector =
        PitchDetector(44100, await MicStream.bufferSize ?? 1792);

    pitchStream = audioStream!.map((audio) => pitchDetector
        .getPitch(audio.map((int val) => val.toDouble()).toList()));

    pitchStream.listen((result) {
      if (result.pitched) {
        _frequencyHistory.add(result.pitch);
        _addAverageNote();
      } else {
        currentNoteNotifier.value = null;
      }
    });
  }

  /// Calculate the average of the last [averageNotesN] frequencies and add a
  /// [Note] with that frequency to [noteHistory].
  void _addAverageNote() {
    List<double> previousFrequencies = _frequencyHistory
        // Only the [averageNotesN] last entries
        .sublist(max(0, _frequencyHistory.length - averageNotesN))
        // Only frequencies close to the current
        .where((frequency) => (frequency - _frequencyHistory.last).abs() < 10)
        .toList();

    // Add note
    Note avgNote = Note.fromFrequency(
        previousFrequencies.reduce((a, b) => a + b) /
            previousFrequencies.length);
    noteHistory.add(avgNote);
    currentNoteNotifier.value = avgNote;
  }
}
