import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/tuner/note.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Singleton for detecting what pitch is being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();

  /// The number of notes to take average of.
  static const int averageNotesN = 15;

  /// How many cents off a Note can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The amount of recorded data per sample, in bytes.
  int bufferSize = 2048;

  /// The sample rate of the recording.
  double sampleRate = 44100;

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
    Stream<List<double>> audioStream = await (Platform.isIOS
        ? audioStreamUsingFlutterAudioCapture()
        : audioStreamUsingMicStream());

    final PitchDetector pitchDetector = PitchDetector(sampleRate, bufferSize);

    final Stream<PitchDetectorResult> pitchStream =
        audioStream.map((List<double> audio) {
      List<double> formattedAudio =
          audio.map((value) => (value / 2 + 0.5) * 255).toList();
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

    initialized = true;
  }

  /// Uses the package flutter_audio_capture to record audio to a stream.
  ///
  /// The returned list contains [double]s between 0 and 255.
  Future<Stream<List<double>>> audioStreamUsingFlutterAudioCapture() async {
    late final StreamController<List<double>> audioStreamController;

    void startRecording() async {
      await _audioCapture.start(
        (dynamic obj) {
          Float64List buffer = Float64List.fromList(obj.cast<double>());
          audioStreamController.add(buffer.toList());
        },
        (Object error, StackTrace stackTrace) {
          throw "TUNER: Unable to capture audio from microphone";
        },
        sampleRate: sampleRate.toInt(),
        bufferSize: bufferSize,
      );
    }

    audioStreamController = StreamController<List<double>>(
      onListen: startRecording,
      onPause: _audioCapture.stop,
      onResume: startRecording,
      onCancel: _audioCapture.stop,
    );

    sampleRate = _audioCapture.actualSampleRate ?? sampleRate;

    return audioStreamController.stream;
  }

  /// Uses the package mic_stream to record audio to a stream.
  ///
  /// The returned list contains [double]s between 0 and 255.
  Future<Stream<List<double>>> audioStreamUsingMicStream() async {
    final Stream<Uint8List>? audioStream = await MicStream.microphone();
    if (audioStream == null) {
      throw "TUNER: Unable to capture audio from microphone";
    }
    sampleRate = await MicStream.sampleRate!;
    bufferSize = await MicStream.bufferSize!;

    return audioStream.map((List<int> audioSample) =>
        audioSample.map((value) => value.toDouble()).toList());
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
