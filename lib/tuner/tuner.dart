import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  ///
  /// Defaults to 440 Hz.
  ///
  /// See [Note.a4frequency].
  double get a4frequency => a4frequencyNotifier.value;
  set a4frequency(double value) => a4frequencyNotifier.value = value;
  final ValueNotifier<double> a4frequencyNotifier = ValueNotifier(440);

  /// The temperament that notes are tuned to.
  ///
  /// Defaults to [EqualTemperament].
  ///
  /// See [Note.temperament].
  Temperament get temperament => temperamentNotifier.value;
  set temperament(Temperament value) => temperamentNotifier.value = value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const EqualTemperament());

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
      final int bitDepth = await MicStream.bitDepth;
      bufferSize = await MicStream.bufferSize ~/ (bitDepth / 8);

      return switch (bitDepth) {
        8 => samples.buffer.asInt8List().map((e) => e.toDouble()).toList(),
        16 => [
            0,
            for (var offset = 1; offset < samples.length; offset += 2)
              (samples.buffer.asByteData().getUint16(offset) & 0xFF) - 128.0
          ],
        _ => throw "Unsupported `bitDepth`: $bitDepth",
      };
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

  Note getClosestNote(double frequency) {
    return Note.fromFrequency(
      frequency,
      a4frequency: a4frequency,
      temperament: temperament,
    );
  }

  /// Calculate how many cents off [frequency] is from its closest [Note].
  double getPitchOffset(double frequency) =>
      1200 * log(frequency / getClosestNote(frequency).frequency) / log(2);
}
