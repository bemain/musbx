import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/model/temperament.dart';
import 'package:musbx/widgets/custom_icons.dart';

class TuningSelector extends StatelessWidget {
  /// Widget for selecting a frequency to use as the tuning of A4.
  const TuningSelector({
    super.key,
    required this.tuningNotifier,
    this.minFrequency = 415,
    this.maxFrequency = 456,
  });

  static const int baseFrequency = 440;

  final ValueNotifier<Pitch> tuningNotifier;

  /// The minimum frequency that can be entered, in Hz.
  final int minFrequency;

  /// The maximum frequency that can be entered, in Hz.
  final int maxFrequency;

  void _setTuning(num frequency) {
    tuningNotifier.value = Pitch(PitchClass.a(), 4, frequency.toDouble());
  }

  int _parseFrequency(String text) {
    return (int.tryParse(text) ?? baseFrequency).clamp(
      minFrequency,
      maxFrequency,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tuningNotifier,
      builder: (context, tuning, child) {
        final TextEditingController controller = TextEditingController(
          text: tuning.frequency.toInt().toString(),
        );

        return AlertSheet(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select tuning"),
              IconButton(
                onPressed: tuning.frequency == baseFrequency
                    ? null
                    : () {
                        _setTuning(baseFrequency);
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: tuning.frequency > minFrequency
                      ? () {
                          _setTuning(tuning.frequency - 1);
                        }
                      : null,
                  icon: Icon(Symbols.remove),
                ),
                SizedBox(
                  width: 128,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "A4 frequency",
                      suffixText: "Hz",
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          // Extract numbers
                          String newText = newValue.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          // Limit length
                          newText = newText.substring(
                            0,
                            min(3, newText.length),
                          );

                          return newValue.copyWith(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: min(
                                newValue.selection.start,
                                newText.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    onSubmitted: (value) {
                      _setTuning(_parseFrequency(value));
                    },
                  ),
                ),
                IconButton(
                  onPressed: tuning.frequency < maxFrequency
                      ? () {
                          _setTuning(tuning.frequency + 1);
                        }
                      : null,
                  icon: Icon(Symbols.add),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                _setTuning(_parseFrequency(controller.text));
                Navigator.of(context).pop();
              },
              child: Text("Done"),
            ),
          ],
        );
      },
    );
  }
}

class AccidentalSelector extends StatelessWidget {
  /// Widget for selecting an accidental.
  const AccidentalSelector({
    required this.accidentalNotifier,
    super.key,
  });

  final ValueNotifier<Accidental> accidentalNotifier;

  /// Generate a short description for the given [accidental].
  static String accidentalDescription(Accidental accidental) {
    return switch (accidental) {
      Accidental.natural => "Adaptive",
      Accidental.sharp => "Sharps",
      Accidental.flat => "Flats",
    };
  }

  void _setAccidental(Accidental accidental) {
    accidentalNotifier.value = accidental;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: accidentalNotifier,
      builder: (context, accidental, child) {
        return AlertSheet(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select accidental"),
              IconButton(
                onPressed: accidental == Accidental.natural
                    ? null
                    : () {
                        _setAccidental(Accidental.natural);
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              ),
            ],
          ),
          content: RadioGroup<Accidental>(
            groupValue: accidental,
            onChanged: (value) {
              if (value != null) _setAccidental(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (Accidental accidental in Accidental.values)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsetsDirectional.only(end: 24.0),
                      leading: Radio(value: accidental),
                      title: Text(
                        AccidentalSelector.accidentalDescription(accidental),
                      ),
                      subtitle: Text(switch (accidental) {
                        Accidental.natural =>
                          "Uses sharps or flats depending on which key has fewest accidentals.",
                        Accidental.sharp => "Only uses sharps (♯).",
                        Accidental.flat => "Only uses flats (♭).",
                      }),
                      onTap: () {
                        _setAccidental(accidental);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Done"),
            ),
          ],
        );
      },
    );
  }
}

class TemperamentSelector extends StatelessWidget {
  /// Widget for selecting an accidental.
  const TemperamentSelector({
    required this.temperamentNotifier,
    super.key,
  });

  final ValueNotifier<Temperament> temperamentNotifier;

  /// Generate a short description for the given [temperament].
  static String temperamentDescription(Temperament temperament) {
    return switch (temperament) {
      EqualTemperament() => "Equal",
      PythagoreanTuning() => "Pythagorean",
      _ => "Unknown",
    };
  }

  void _setTemperament(Temperament temperament) {
    temperamentNotifier.value = temperament;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: temperamentNotifier,
      builder: (context, temperament, child) {
        return AlertSheet(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select temperament"),
              IconButton(
                onPressed: temperament is EqualTemperament
                    ? null
                    : () {
                        _setTemperament(Temperament.temperaments.first);
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              ),
            ],
          ),
          content: RadioGroup<Temperament>(
            groupValue: temperament,
            onChanged: (value) {
              if (value != null) _setTemperament(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (Temperament temperament in Temperament.temperaments)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsetsDirectional.only(end: 24.0),
                      leading: Radio(value: temperament),
                      title: Text(
                        switch (temperament) {
                          EqualTemperament() => "Equal temperament",
                          PythagoreanTuning() => "Pythagorean tuning",
                          _ => "Unknown",
                        },
                      ),
                      subtitle: Text(switch (temperament) {
                        EqualTemperament() =>
                          "Equispaced steps, like a piano.",
                        PythagoreanTuning() => "Based on pure perfect fifths.",
                        _ => "",
                      }),
                      onTap: () {
                        _setTemperament(temperament);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Done"),
            ),
          ],
        );
      },
    );
  }
}

class WaveformShapeSelector extends StatelessWidget {
  /// Widget for selecting a wave shape.
  const WaveformShapeSelector({
    required this.waveformNotifier,
    super.key,
  });

  static const Set<WaveForm> availableWaveforms = {
    WaveForm.sin,
    WaveForm.fSaw,
    WaveForm.fSquare,
    WaveForm.triangle,
  };

  final ValueNotifier<WaveForm> waveformNotifier;

  /// Generate a short description for the given [waveform] shape.
  static String waveformDescription(WaveForm waveform) {
    return switch (waveform) {
      WaveForm.sin => "Sine",
      WaveForm.fSaw => "Sawtooth",
      WaveForm.fSquare => "Square",
      WaveForm.triangle => "Triangle",
      _ => "",
    };
  }

  static IconData? waveformIcon(WaveForm waveform) {
    return switch (waveform) {
      WaveForm.sin => CustomIcons.waveform_sine,
      WaveForm.fSaw => CustomIcons.waveform_sawtooth,
      WaveForm.fSquare => CustomIcons.waveform_square,
      WaveForm.triangle => CustomIcons.waveform_triangle,
      _ => null,
    };
  }

  void _setWaveform(WaveForm waveform) {
    waveformNotifier.value = waveform;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: waveformNotifier,
      builder: (context, waveform, child) {
        return AlertSheet(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select shape"),
              IconButton(
                onPressed: waveform == WaveForm.sin
                    ? null
                    : () {
                        _setWaveform(WaveForm.sin);
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              ),
            ],
          ),
          content: RadioGroup<WaveForm>(
            groupValue: waveform,
            onChanged: (value) {
              if (value != null) _setWaveform(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (WaveForm waveform in availableWaveforms)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsetsDirectional.only(end: 24.0),
                      leading: Radio(value: waveform),
                      title: Text(
                        WaveformShapeSelector.waveformDescription(waveform),
                      ),
                      trailing: Icon(
                        WaveformShapeSelector.waveformIcon(waveform),
                      ),
                      onTap: () {
                        _setWaveform(waveform);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Done"),
            ),
          ],
        );
      },
    );
  }
}

class ThemeSelector extends StatelessWidget {
  /// Widget for selecting an accidental.
  const ThemeSelector({
    required this.themeNotifier,
    super.key,
  });

  final ValueNotifier<ThemeMode> themeNotifier;

  /// Generate a short description for the given [themeMode].
  static String themeDescription(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.system => "System default",
      ThemeMode.light => "Light",
      ThemeMode.dark => "Dark",
    };
  }

  void _setTheme(ThemeMode theme) {
    themeNotifier.value = theme;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return AlertSheet(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select theme"),
              IconButton(
                onPressed: themeMode == ThemeMode.system
                    ? null
                    : () {
                        _setTheme(ThemeMode.system);
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              ),
            ],
          ),
          content: RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) _setTheme(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (ThemeMode themeMode in ThemeMode.values)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsetsDirectional.only(end: 24.0),
                      leading: Radio(value: themeMode),
                      title: Text(
                        ThemeSelector.themeDescription(themeMode),
                      ),
                      subtitle: Text(switch (themeMode) {
                        ThemeMode.system => "Adapts to your device settings.",
                        ThemeMode.light => "Always use the light mode.",
                        ThemeMode.dark => "Always use the dark mode.",
                      }),
                      onTap: () {
                        _setTheme(themeMode);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Done"),
            ),
          ],
        );
      },
    );
  }
}
