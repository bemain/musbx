import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/services/audio_capture_service.dart';
import 'package:musbx/domain/use_case/pitch_detector.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/tuner/view_model/tuner_reading.dart';

/// Singleton for detecting what pitch is being played.
/// TODO: Remove this class
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// How many cents off a frequency can be to be considered in tune.
  static const double inTuneThreshold = 10;

  /// The number of previous data entries buffered.
  static const int bufferLength = 32;

  late final AudioCaptureService _audioCapture;

  late final PitchDetector _pitchDetector;

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  bool isInitialized = false;

  /// Initialize the [Tuner] and prepare playback.
  Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    _audioCapture = await AudioCaptureService.create();
    _pitchDetector = PitchDetector(sampleRate: _audioCapture.sampleRate);
  }

  /// Whether permission to access the microphone has been given.
  ///
  /// The `permission_handler` package has no implementation for Linux or
  /// macOS, so requesting permission there would never complete. On macOS
  /// access is instead granted by the `com.apple.security.device.audio-input`
  /// entitlement, which the system prompts for on first use.
  bool hasPermission = Platform.isLinux || Platform.isMacOS;

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

  /// The recent data recorded from the [dataStream]. [bufferLength] data entries are kept.
  ///
  /// Note that this won't receive any data until streaming is started.
  /// For a [Stream] that automatically starts streaming when listened to,
  /// use [dataStream].
  final List<TunerReading> dataBuffer = [];

  /// The realtime data recorded from the microphone.
  Stream<TunerReading> get dataStream => _audioCapture.dataStream.map((frame) {
    final freq = _pitchDetector.add(frame.data);
    final pitch = freq == null ? null : getClosestPitch(freq);

    final reading = TunerReading(
      frame: frame,
      pitch: pitch,
    );

    if (pitch != null) this.pitch = pitch;

    // Add to buffer
    dataBuffer.add(reading);
    if (dataBuffer.length > bufferLength) {
      dataBuffer.removeRange(0, dataBuffer.length - bufferLength);
    }

    return reading;
  });

  /// The most recent pitch detected, averaged and filtered.
  Pitch? pitch;

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
