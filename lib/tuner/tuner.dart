import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/model/note.dart';
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
  late int bufferSize;

  /// The sample rate of the recording.
  late double sampleRate;

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
  void initialize() {
    if (initialized) return;
    print("[DEBUG] Initialize");

    Stream<List<double>> audioStream = audioStreamUsingFlutterAudioCapture();

    final Stream<PitchDetectorResult> pitchStream = audioStream.asyncMap(
      (List<double> samples) => PitchDetector(
        audioSampleRate: sampleRate,
        bufferSize: bufferSize,
      ).getPitchFromFloatBuffer(samples),
    );

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
    }).asBroadcastStream();

    initialized = true;
  }

  final StreamController controller = StreamController<List<double>>();

  static const int defaultSampleRate = 16000;
  static const int defaultBufferSize = 640;

  /// Uses the package flutter_audio_capture to record audio to a stream.
  ///
  /// The returned list contains [double]s between 0 and 255.
  Stream<List<double>> audioStreamUsingFlutterAudioCapture() {
    late final StreamController<List<double>> audioStreamController;

    audioStreamController = StreamController<List<double>>.broadcast(
      onListen: () async {
        await _audioCapture.init();
        await _audioCapture.start(
          (Float32List obj) {
            Float64List buffer = Float64List.fromList(obj.cast<double>());
            audioStreamController.add(buffer.toList());
          },
          (Object error, StackTrace stackTrace) {
            throw "TUNER: Unable to capture audio from microphone";
          },
          waitForFirstDataOnAndroid: false,
          waitForFirstDataOnIOS: false,
          sampleRate: defaultSampleRate,
          bufferSize: defaultBufferSize,
        );
      },
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
  Stream<List<double>> audioStreamUsingMicStream() {
    final Stream<Uint8List> audioStream = MicStream.microphone(
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_8BIT,
    );

    return audioStream.asyncMap((Uint8List samples) async {
      print("[DEBUG] Samples");
      sampleRate = (await MicStream.sampleRate).toDouble();
      bufferSize = await MicStream.bufferSize;

      final int bitDepth = await MicStream.bitDepth;

      return switch (bitDepth) {
        8 => samples.buffer.asInt8List(),
        16 => samples.buffer.asInt16List(),
        _ => throw "Unsupported `bitDepth`: $bitDepth",
      }
          .map((e) => e.toDouble())
          .toList();
    });
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
