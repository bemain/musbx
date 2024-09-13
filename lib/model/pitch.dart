import 'package:flutter/material.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';

@immutable
class Pitch {
  /// Representation of a musical tone with a specific frequency.
  const Pitch(
    this.pitchClass,
    this.octave,
    this.frequency,
  );

  const Pitch.a440()
      : pitchClass = const PitchClass.a(),
        octave = 4,
        frequency = 440;

  /// The name of the pitch.
  final PitchClass pitchClass;

  /// The octave of the pitch, in [scientific pitch notation](https://en.wikipedia.org/wiki/Scientific_pitch_notation).
  final int octave;

  /// The frequency of the pitch.
  final double frequency;

  /// Get the pitch closest to a specific [frequency].
  factory Pitch.closest(
    double frequency, {
    Pitch tuning = const Pitch.a440(),
    Temperament temperament = const EqualTemperament(),
  }) {
    assert(frequency > 0, "Frequency must be greater than 0");

    final int semitones = temperament.scaleStep(frequency / tuning.frequency);
    Pitch transposed = tuning.transposed(semitones);

    return Pitch(
      transposed.pitchClass,
      transposed.octave,
      frequency,
    );
  }

  String get abbreviation => "${pitchClass.abbreviation}$octave";

  /// The number of semitones between this and [other].
  int semitonesTo(Pitch other) =>
      (other.octave * 12 + other.pitchClass.semitonesFromC) -
      (octave * 12 + pitchClass.semitonesFromC);

  /// Transpose this pitch a number of semitones.
  Pitch transposed(
    int semitones, {
    Temperament temperament = const EqualTemperament(),
  }) {
    return Pitch(
      pitchClass.transposed(semitones),
      octave + ((pitchClass.chroma.semitonesFromC + semitones) / 12).floor(),
      frequency * temperament.frequencyRatio(semitones),
    );
  }

  @override
  String toString() {
    return "Pitch(${pitchClass.abbreviation}, $octave, ${frequency}Hz)";
  }

  @override
  bool operator ==(Object other) =>
      other is Pitch &&
      pitchClass == other.pitchClass &&
      octave == other.octave &&
      frequency == other.frequency;

  @override
  int get hashCode => Object.hash(pitchClass, octave, frequency);
}
