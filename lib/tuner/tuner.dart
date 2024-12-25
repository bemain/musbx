import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/temperament.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

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

  /// Whether permission to access the microphone has been given.
  bool hasPermission = false;

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  ///
  /// Defaults to [Pitch.a440].
  Pitch get tuning => tuningNotifier.value;
  set tuning(Pitch value) => tuningNotifier.value = value;
  final ValueNotifier<Pitch> tuningNotifier = ValueNotifier(const Pitch.a440());

  /// The temperament that notes are tuned to.
  ///
  /// Defaults to [EqualTemperament].
  ///
  /// See [Temperament].
  Temperament get temperament => temperamentNotifier.value;
  set temperament(Temperament value) => temperamentNotifier.value = value;
  final ValueNotifier<Temperament> temperamentNotifier =
      ValueNotifier(const EqualTemperament());

  /// The previous frequencies detected, unfiltered.
  final List<double> _rawFrequencyHistory = [];

  /// The previous frequencies detected, averaged and filtered.
  final List<double> frequencyHistory = [];

  /// The current frequency detected, or null if no frequency could be detected.
  ///
  /// Throws if permission to access the microphone has not been given.
  Stream<double?> get frequencyStream {
    return audioStream.asyncMap((samples) async {
      final result = await PitchDetector(
        audioSampleRate: sampleRate,
        bufferSize: bufferSize,
      ).getPitchFromFloatBuffer(samples);

      if (!result.pitched) return null;

      _rawFrequencyHistory.add(result.pitch);
      double? avgFrequency = _getAverageFrequency();
      if (avgFrequency != null) {
        frequencyHistory.add(avgFrequency);
        return avgFrequency;
      }
      return null;
    }).where((frequency) => frequency != null);
  }

  /// Uses the package mic_stream to record audio to a stream.
  ///
  /// The returned list contains [double]s between -128 and 127.
  Stream<List<double>> get audioStream {
    final Stream<Uint8List> audioStream = MicStream.microphone(
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: Platform.isIOS
          ? AudioFormat.ENCODING_PCM_16BIT
          : AudioFormat.ENCODING_PCM_8BIT,
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

  Pitch getClosestPitch(double frequency) {
    return Pitch.closest(
      frequency,
      tuning: tuning,
      temperament: temperament,
      preferredAccidental: Accidental.natural,
    );
  }

  /// Calculate how many cents off [frequency] is from its closest [Pitch].
  double getPitchOffset(double frequency) {
    final Pitch closest = getClosestPitch(frequency);

    /// The frequency this note "should" have
    final double targetFrequency = tuning.frequency *
        temperament.frequencyRatio(tuning.semitonesTo(closest));

    return 1200 * log(frequency / targetFrequency) / log(2);
  }
}
