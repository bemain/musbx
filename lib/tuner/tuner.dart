import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/tuner/yin.dart';

/// Singleton for detecting what pitch is being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// The number of notes to take average of.
  static const int averageFrequenciesN = 3;

  /// How many cents off a frequency can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The sample rate of the recording.
  static const int sampleRate = 22050;

  /// The format used for recording.
  static const PCMFormat format = PCMFormat.f32le;

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  static bool isInitialized = false;

  /// Initialize the [Tuner] and prepare playback.
  static Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    await Recorder.instance.init(
      format: format,
      sampleRate: sampleRate,
      channels: RecorderChannels.mono,
    );
    Recorder.instance.start();
  }

  late int bufferSize;

  /// Whether permission to access the microphone has been given.
  bool hasPermission = false;

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  ///
  /// Defaults to [Pitch.a440].
  Pitch get tuning => tuningNotifier.value;
  set tuning(Pitch value) => tuningNotifier.value = value;
  final ValueNotifier<Pitch> tuningNotifier = ValueNotifier(
    const Pitch.a440(),
  );

  /// The temperament that notes are tuned to.
  ///
  /// Defaults to [EqualTemperament].
  Temperament get temperament => temperamentNotifier.value;
  set temperament(Temperament value) => temperamentNotifier.value = value;
  final ValueNotifier<Temperament> temperamentNotifier = ValueNotifier(
    const EqualTemperament(),
  );

  /// The previous frequencies detected, unfiltered.
  final List<double> _rawFrequencyHistory = [];

  /// The previous frequencies detected, averaged and filtered.
  final List<double> frequencyHistory = [];

  void _startStreaming() => Recorder.instance.startStreamingData();
  void _stopStreaming() {
    print("[DEBUG] Stop streaming");
    Recorder.instance.stopStreamingData();
  }

  late final StreamController<double> _controller = StreamController(
    onListen: _startStreaming,
    onPause: _stopStreaming,
    onResume: _startStreaming,
    onCancel: _stopStreaming,
  )..addStream(_frequencyStream);

  Stream<double> get frequencyStream => _controller.stream;

  /// The current frequency detected, or null if no frequency could be detected.
  ///
  /// Throws if permission to access the microphone has not been given.
  late final Stream<double> _frequencyStream = Recorder
      .instance
      .uint8ListStream
      .map((data) {
        final result = Yin(
          sampleRate.toDouble(),
          // We need to use a small buffer size so the operation completes before the next data arrives
          // TODO: Maybe use a different method
          min(2048, data.length),
        ).getPitch(data.toF32List(from: format));

        if (result == null) return null;

        _rawFrequencyHistory.add(result.frequency);
        double? avgFrequency = _getAverageFrequency();
        if (avgFrequency != null) {
          frequencyHistory.add(avgFrequency);
          return avgFrequency;
        }
        return null;
      })
      .where((frequency) => frequency != null)
      .map((frequency) => frequency!);

  /// Calculate the average of the last [averageFrequenciesN] frequencies.
  double? _getAverageFrequency() {
    List<double> previousFrequencies = _rawFrequencyHistory
        // Only the [averageFrequenciesN] last entries
        .sublist(max(0, _rawFrequencyHistory.length - averageFrequenciesN))
        // Only frequencies close to the current
        .where(
          (frequency) => (frequency - _rawFrequencyHistory.last).abs() < 10,
        )
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
    final double targetFrequency =
        tuning.frequency *
        temperament.frequencyRatio(tuning.semitonesTo(closest));

    return 1200 * log(frequency / targetFrequency) / log(2);
  }
}

class TuningResult {
  TuningResult({required this.frequency, required this.confidence});

  final double frequency;
  final double confidence;
}
