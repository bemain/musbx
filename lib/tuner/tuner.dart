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

  /// The size of chunks when buffering wave data.
  static const int waveBufferChunkSize = 16;

  /// The number of chunks of wave data buffered.
  ///
  /// Note that `waveBufferChunks * waveBufferChunkSize` must be greater than `256`.
  static const int waveBufferChunks = 16;

  /// Minimum bin index for FFT data.
  static const int fftMinBinIndex = 0;

  /// Maximum bin index for FFT data.
  static const int fftMaxBinIndex = 255;

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

  Future<void> dispose() async {
    await _waveController.close();
    await _fftController.close();
  }

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
  /// use [frequencyStream].
  late final Stream<double> _frequencyStream = Recorder
      .instance
      .uint8ListStream
      .map(_processData)
      .where((frequency) => frequency != null)
      .map((frequency) => frequency!);

  /// The current frequency detected, or null if no frequency could be detected.
  ///
  /// Throws if permission to access the microphone has not been given.
  Stream<double> get frequencyStream => (StreamController<double>(
    onListen: _startStreaming,
    onPause: _stopStreaming,
    onResume: _startStreaming,
    onCancel: _stopStreaming,
  )..addStream(_frequencyStream)).stream;

  /// Process audio data. Updates wave data and performs pitch detection.
  ///
  /// Returns the detected frequency if any.
  double? _processData(AudioDataContainer data) {
    _processWaveData(Recorder.instance.getWave());
    _processFFTData(Recorder.instance.getFft());

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
  }

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

  /// Get the pitch closest to the given [frequency].
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

  /// The buffered wave data. The raw data is split into chunks and averaged
  /// before it is stored here.
  ///
  /// Note that this is only updated when [frequencyStream] has a listener.
  final Float32List waveBuffer = Float32List(
    waveBufferChunks * waveBufferChunkSize,
  );

  final StreamController<Float32List> _waveController =
      StreamController.broadcast();

  /// The unbuffered wave data.
  ///
  /// Note that to receive any data, you also must listen to [frequencyStream].
  Stream<Float32List> get waveStream => _waveController.stream;

  /// Processes wave [data] and updates the buffer.
  ///
  /// This function updates the [waveBuffer] by taking the
  /// wave data and processing it in chunks. The existing data in the buffer
  /// is shifted to the left by the number of processed chunks. Each chunk
  /// is averaged, and the result is stored at the end of the buffer.
  void _processWaveData(Float32List data) {
    _waveController.add(data);

    final processedLength = data.length ~/ waveBufferChunkSize;

    // Shift existing data to the left
    for (var i = 0; i < waveBuffer.length - processedLength; i++) {
      waveBuffer[i] = waveBuffer[i + processedLength];
    }

    // Process data in chunks and store at the end
    for (var i = 0; i < processedLength; i++) {
      double sum = 0.0;
      final int startIdx = i * waveBufferChunkSize;

      // Calculate average for this chunk
      var j = 0;
      for (
        j = 0;
        j < waveBufferChunkSize && (startIdx + j) < data.length;
        j++
      ) {
        sum += data[startIdx + j];
      }

      // Store at the end of the array
      final id = waveBuffer.length - processedLength + i;
      if (id >= 0 && id < waveBuffer.length) {
        waveBuffer[id] = sum / j;
      }
    }
  }

  /// The buffered FFT data.
  ///
  /// Note that this is only updated when [frequencyStream] has a listener.
  final Float32List fftBuffer = Float32List(512);

  final StreamController<Float32List> _fftController =
      StreamController.broadcast();

  /// The unbuffered FFT data.
  ///
  /// Note that to receive any data, you also must listen to [frequencyStream].
  Stream<Float32List> get fftStream => _fftController.stream;

  void _processFFTData(Float32List data) {
    _fftController.add(data);

    final barCount = fftMaxBinIndex - fftMinBinIndex;
    final range = fftMaxBinIndex - fftMinBinIndex + 1;
    final chunkSize = range / barCount;

    for (var i = 0; i < barCount; i++) {
      var sum = 0.0;
      var count = 0;

      // Calculate chunk boundaries
      final startIdx = (i * chunkSize + fftMinBinIndex).floor();
      final endIdx = ((i + 1) * chunkSize + fftMinBinIndex).ceil();

      // Ensure we don't exceed maxIndex
      final effectiveEndIdx = endIdx.clamp(0, fftMaxBinIndex + 1);

      for (var j = startIdx; j < effectiveEndIdx; j++) {
        sum += data[j];
        count++;
      }

      // Store the average for this chunk
      fftBuffer[i] = count > 0 ? sum / count : 0.0;
    }
  }
}

class TuningResult {
  TuningResult({required this.frequency, required this.confidence});

  final double frequency;
  final double confidence;
}

/// Try to detect a pitch from audio data.
TuningResult? tune(Float32List buffer, {required int sampleRate}) {
  final int lower = sampleRate ~/ 2093; // 2093 C7
  final int upper = sampleRate ~/ 32.7032; // 32.7032 Hz C1
  final int samples = buffer.length - upper;
  int bestOffset = -1;
  double bestCorrelation = 0.0;
  double rms = 0.0;

  if (buffer.length < (samples + upper - lower)) {
    return null; // Not enough data
  }

  for (int i = 0; i < samples; i++) {
    final double val = buffer[i];
    rms += val * val;
  }
  rms = sqrt(rms / samples);

  for (int offset = lower; offset < upper; offset++) {
    double correlation = 0.0;

    for (int i = 0; i < samples; i++) {
      correlation += (buffer[i] - buffer[i + offset]).abs();
    }
    correlation = 1 - (correlation / samples);
    //weight slightly against lower freq to avoid octave erros
    correlation = correlation * .9 + (upper - offset) / (upper - lower) / 185;
    if (correlation > bestCorrelation) {
      bestCorrelation = correlation;
      bestOffset = offset;
    }
  }

  if (rms > .009 && bestCorrelation > 0.5) {
    return TuningResult(
      frequency: sampleRate / bestOffset,
      confidence: bestCorrelation * rms * 10000,
    );
  }
  return null;
}
