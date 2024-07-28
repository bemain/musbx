import 'package:flutter/material.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';

@immutable
class Note {
  /// Representation of a musical note, with a specific name and [octave].
  const Note(
    this.pitchClass,
    this.octave, {
    this.a4frequency = 440,
    this.temperament = const EqualTemperament(),
  });

  /// The name of the note.
  final PitchClass pitchClass;

  /// The octave of the note, in [scientific pitch notation](https://en.wikipedia.org/wiki/Scientific_pitch_notation).
  final int octave;

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  ///
  /// Defaults to 440 Hz.
  final double a4frequency;

  /// The frequency of C0, which the scientific pitch notation begins at.
  double get _c0frequency => a4frequency * temperament.frequencyRatio(-57);

  /// The temperament that this note is tuned to.
  ///
  /// Defaults to [EqualTemperament].
  final Temperament temperament;

  /// Get the note closest to a specific [frequency].
  factory Note.fromFrequency(
    double frequency, {
    double a4frequency = 440,
    Temperament temperament = const EqualTemperament(),
  }) {
    assert(frequency > 0, "Frequency must be greater than 0");

    final double c0frequency = a4frequency * temperament.frequencyRatio(-57);
    final int scaleStep = temperament.scaleStep(frequency / c0frequency);
    final int octave = (scaleStep / 12).floor();

    return Note(
      PitchClass.values[(scaleStep - 12 * octave) % 12],
      octave,
      a4frequency: a4frequency,
      temperament: temperament,
    );
  }

  /// The frequency of this note, in Hz.
  double get frequency =>
      _c0frequency * temperament.frequencyRatio(octave * 12 + pitchClass.index);

  String get abbreviation => "${pitchClass.abbreviation}$octave";

  @override
  String toString() {
    return "Note(${pitchClass.abbreviation}, $octave)";
  }
}
