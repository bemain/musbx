import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/model/note.dart';
import 'package:musbx/model/temperament.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Singleton for detecting what pitch is being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// The number of notes to take average of.
  static const int averageFrequenciesN = 15;

  /// How many cents off a frequency can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The amount of recorded data per sample, in bytes.
  late int bufferSize;

  /// The sample rate of the recording.
  late double sampleRate;

  /// Whether the Tuner has been initialized or not.
  /// If true, [frequencyStream] has been created.
  bool initialized = false;

  Temperament temperament = const EqualTemperament();

  /// The previous frequencies detected, unfiltered.
  final List<double> _rawFrequencyHistory = [];

  /// The previous frequencies detected, averaged and filtered.
  final List<double> frequencyHistory = [];

  /// The current note detected, or null if no pitch could be detected.
  late final Stream<double?> frequencyStream;

  /// Initialize the Tuner.
  /// Creates the [frequencyStream] for detecting pitch from the microphone.
  ///
  /// Assumes permission to access the microphone has already been given.
  void initialize() {
    if (initialized) return;

    final Stream<PitchDetectorResult> pitchStream = getAudioStream().asyncMap(
      (List<double> samples) => PitchDetector(
        audioSampleRate: sampleRate,
        bufferSize: bufferSize,
      ).getPitchFromFloatBuffer(samples),
    );

    frequencyStream = pitchStream.map((result) {
      if (!result.pitched) return null;

      _rawFrequencyHistory.add(result.pitch);
      double? avgFrequency = _getAverageFrequency();
      if (avgFrequency != null) {
        frequencyHistory.add(avgFrequency);
        return avgFrequency;
      }
      return null;
    }).asBroadcastStream();

    initialized = true;
  }

  /// Uses the package mic_stream to record audio to a stream.
  ///
  /// The returned list contains [double]s between 0 and 255.
  Stream<List<double>> getAudioStream() {
    final Stream<Uint8List> audioStream = MicStream.microphone(
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_8BIT,
    );

    return audioStream.asyncMap((Uint8List samples) async {
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

  /// Calculate the average of the last [averageFrequenciesN] frequencies.
  double? _getAverageFrequency() {
    List<double> previousFrequencies = _rawFrequencyHistory
        // Only the [averageFrequenciesN] last entries
        .sublist(max(0, _rawFrequencyHistory.length - averageFrequenciesN))
        // Only frequencies close to the current
        .where(
            (frequency) => (frequency - _rawFrequencyHistory.last).abs() < 10)
        .toList();

    if (previousFrequencies.length <= averageFrequenciesN / 3) return null;

    return previousFrequencies.reduce((a, b) => a + b) /
        previousFrequencies.length;
  }

  /// Calculate how many cents off [frequency] is from its closest [Note].
  double calculatePitchOffset(double frequency) {
    return 1200 *
        log(frequency /
            Note.fromFrequency(
              frequency,
              temperament: temperament,
            ).frequency) /
        log(2);
  }
}
