import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/note/note.dart';
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
  late final int bufferSize;

  /// The sample rate of the recording.
  late final double sampleRate;

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
        audioStream.map(pitchDetector.getPitch);

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
    const int defaultSampleRate = 16000;
    const int defaultBufferSize = 640;

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
        waitForFirstDataOnAndroid: false,
        sampleRate: defaultSampleRate,
        bufferSize: defaultBufferSize,
      );
    }

    audioStreamController = StreamController<List<double>>.broadcast(
      onListen: startRecording,
      onCancel: _audioCapture.stop,
    );

    sampleRate = _audioCapture.actualSampleRate ?? defaultSampleRate.toDouble();
    bufferSize = defaultBufferSize;

    return audioStreamController.stream.map((List<double> audioSample) =>
        audioSample.map((value) => (value / 2 + 0.5) * 255).toList());
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
