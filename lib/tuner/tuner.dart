import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/tuner/yin.dart';
import 'package:musbx/utils/persistent_value.dart';

class RecordingData {
  /// Data recorded from the microphone at a given [time].
  RecordingData({
    required this.wave,
    required this.fft,
    this.frequency,
  });

  /// When that this data was recorded.
  final DateTime time = DateTime.now();

  /// Waveform data.
  final Float32List wave;

  /// FFT Data.
  final Float32List fft;

  /// The pitch detected, if any.
  final double? frequency;
}

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

  /// The number of previous data entries buffered.
  static const int bufferLength = 32;

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  bool isInitialized = false;

  /// Initialize the [Tuner] and prepare playback.
  Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    await Recorder.instance.init(
      format: format,
      sampleRate: sampleRate,
      channels: RecorderChannels.mono,
    );
  }

  /// Whether permission to access the microphone has been given.
  bool hasPermission = Platform.isLinux;

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  ///
  /// Defaults to [Pitch.a440].
  Pitch get tuning => tuningNotifier.value;
  set tuning(Pitch value) => tuningNotifier.value = value;
  final ValueNotifier<Pitch> tuningNotifier =
      TransformedPersistentValue<Pitch, String>(
        "tuner/tuning",
        initialValue: const Pitch(PitchClass.a(), 4, 440),
        from: Pitch.parse,
        to: (pitch) => pitch.toString(),
      );

  /// The temperament that notes are tuned to.
  ///
  /// Defaults to [EqualTemperament].
  Temperament get temperament => temperamentNotifier.value;
  set temperament(Temperament value) => temperamentNotifier.value = value;
  final ValueNotifier<Temperament> temperamentNotifier = ValueNotifier(
    const EqualTemperament(),
  );

  /// The accidental to prefer when displaying notes.
  Accidental get preferredAccidental => preferredAccidentalNotifier.value;
  set preferredAccidental(Accidental value) =>
      preferredAccidentalNotifier.value = value;
  final ValueNotifier<Accidental> preferredAccidentalNotifier =
      TransformedPersistentValue<Accidental, String>(
        "tuner/accidental",
        initialValue: Accidental.natural,
        to: (accidental) => accidental.name,
        from: (string) => Accidental.values.firstWhere(
          (accidental) => accidental.name == string,
        ),
      );

  void _startStreaming() {
    Recorder.instance.start();
    Recorder.instance.startStreamingData();
  }

  void _stopStreaming() {
    Recorder.instance.stopStreamingData();
    Recorder.instance.stop();
  }

  /// The stream used internally to receive data.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  late final Stream<RecordingData> _dataStream = Recorder
      .instance
      .uint8ListStream
      .map(_processData);

  /// The realtime data recorded from the microphone.
  Stream<RecordingData> get dataStream => (StreamController<RecordingData>(
    onListen: _startStreaming,
    onPause: _stopStreaming,
    onResume: _startStreaming,
    onCancel: _stopStreaming,
  )..addStream(_dataStream)).stream;

  /// The recent data recorded from the [dataStream]. [bufferLength] data entries are kept.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  final List<RecordingData> dataBuffer = [];

  /// The "raw" (not averaged) pitches buffered.
  Iterable<Pitch> get pitchHistory => dataBuffer
      .map((data) => data.frequency)
      .nonNulls
      .map((frequency) => getClosestPitch(frequency));

  /// The most recent pitch detected, averaged and filtered.
  Pitch? pitch;

  /// The current pitch detected, averaged from the recent history.
  ///
  /// Note that this only yields when a pitch is actually detected. For a stream
  /// that yields periodically, regardless of a pitch is detected or not, use
  /// [dataStream].
  Stream<Pitch> get pitchStream => dataStream
      .where((data) => data.frequency != null)
      .map((data) => _getAverageFrequency())
      .where((freq) => freq != null)
      .map((freq) => getClosestPitch(freq!));

  /// Process audio data. Updates buffers and performs pitch detection.
  RecordingData _processData(AudioDataContainer data) {
    final Float32List wave = Float32List.fromList(Recorder.instance.getWave());
    final Float32List fft = Float32List.fromList(Recorder.instance.getFft());
    final double? frequency = _detectFrequency(data.toF32List(from: format));

    final RecordingData out = RecordingData(
      wave: wave,
      fft: fft,
      frequency: frequency,
    );

    dataBuffer.add(out);
    if (dataBuffer.length > bufferLength) {
      dataBuffer.removeRange(0, dataBuffer.length - bufferLength);
    }

    final double? avgFreq = _getAverageFrequency();
    if (avgFreq != null) pitch = getClosestPitch(avgFreq);

    return out;
  }

  /// Use pitch detection to try and detect a pitch in the given [data].
  double? _detectFrequency(Float32List data) {
    return Yin(
      sampleRate.toDouble(),
      // We need to use a small buffer size so the operation completes before the next data arrives
      // TODO: Maybe use a different method
      min(1024, data.length),
    ).getPitch(data)?.frequency;
  }

  /// Calculate the average of the last [averageFrequenciesN] frequencies.
  double? _getAverageFrequency() {
    Iterable<double> frequenciesToAverage = pitchHistory
        .map((pitch) => pitch.frequency)
        // Only the [averageFrequenciesN] last entries
        .skip(max(0, pitchHistory.length - averageFrequenciesN))
        // Only frequencies close to the current
        .where(
          (frequency) => (frequency - pitchHistory.last.frequency).abs() < 10,
        );

    if (frequenciesToAverage.length < averageFrequenciesN) return null;

    return frequenciesToAverage.reduce((a, b) => a + b) /
        frequenciesToAverage.length;
  }

  /// Get the pitch closest to the given [frequency].
  Pitch getClosestPitch(double frequency) {
    return Pitch.closest(
      frequency,
      tuning: tuning,
      temperament: temperament,
      preferredAccidental: preferredAccidental,
    );
  }

  /// Calculate how many cents off a [pitch]'s frequency is from what it "should" be.
  double getPitchOffset(Pitch pitch) {
    /// The frequency this note "should" have
    final double targetFrequency =
        tuning.frequency *
        temperament.frequencyRatio(tuning.semitonesTo(pitch));

    return 1200 * log(pitch.frequency / targetFrequency) / log(2);
  }
}
