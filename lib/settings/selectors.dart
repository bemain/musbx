import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';
import 'package:musbx/domain/models/music/temperament.dart';
import 'package:musbx/widgets/custom_icons.dart';

/// Widget for selecting a frequency to use as the tuning of A4.
class TuningSelector extends StatefulWidget {
  const TuningSelector({
    super.key,
    required this.initialValue,
    this.minFrequency = 415,
    this.maxFrequency = 456,
    this.onSelection,
  });

  /// The concert pitch offered as the default.
  static const int baseFrequency = 440;

  final Pitch initialValue;

  /// The minimum frequency that can be entered, in Hz.
  final int minFrequency;

  /// The maximum frequency that can be entered, in Hz.
  final int maxFrequency;

  final void Function(Pitch tuning)? onSelection;

  @override
  State<TuningSelector> createState() => _TuningSelectorState();
}

class _TuningSelectorState extends State<TuningSelector> {
  late Pitch tuning = widget.initialValue;

  void _setTuning(num frequency) {
    final value = Pitch(PitchClass.a(), 4, frequency.toDouble());
    setState(() {
      tuning = value;
    });
    controller.text = value.frequency.toInt().toString();
    widget.onSelection?.call(value);
  }

  int _parseFrequency(String text) {
    return (int.tryParse(text) ?? TuningSelector.baseFrequency).clamp(
      widget.minFrequency,
      widget.maxFrequency,
    );
  }

  late final TextEditingController controller = TextEditingController(
    text: tuning.frequency.toInt().toString(),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertSheet(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Select tuning"),
          IconButton(
            onPressed: tuning.frequency == TuningSelector.baseFrequency
                ? null
                : () {
                    _setTuning(TuningSelector.baseFrequency);
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
              onPressed: tuning.frequency > widget.minFrequency
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
              onPressed: tuning.frequency < widget.maxFrequency
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
  }
}

/// Widget for selecting an accidental.
class AccidentalSelector extends StatefulWidget {
  const AccidentalSelector({
    super.key,
    required this.initialValue,
    this.onSelection,
  });

  final Accidental initialValue;

  final void Function(Accidental accidental)? onSelection;

  /// Generate a short description for the given [accidental].
  static String accidentalDescription(Accidental accidental) {
    return switch (accidental) {
      Accidental.natural => "Adaptive",
      Accidental.sharp => "Sharps",
      Accidental.flat => "Flats",
    };
  }

  @override
  State<AccidentalSelector> createState() => _AccidentalSelectorState();
}

class _AccidentalSelectorState extends State<AccidentalSelector> {
  late Accidental accidental = widget.initialValue;

  void _setAccidental(Accidental value) {
    setState(() {
      accidental = value;
    });
    widget.onSelection?.call(value);
  }

  @override
  Widget build(BuildContext context) {
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
                      "Uses sharps or flats depending on which key has fewer accidentals.",
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
  }
}

/// Widget for selecting an accidental.
class TemperamentSelector extends StatefulWidget {
  const TemperamentSelector({
    super.key,
    required this.initialValue,
    this.onSelection,
  });

  final Temperament initialValue;

  final void Function(Temperament temperament)? onSelection;

  /// Generate a short description for the given [temperament].
  static String temperamentDescription(Temperament temperament) {
    return switch (temperament) {
      EqualTemperament() => "Equal",
      PythagoreanTuning() => "Pythagorean",
      _ => "Unknown",
    };
  }

  @override
  State<TemperamentSelector> createState() => _TemperamentSelectorState();
}

class _TemperamentSelectorState extends State<TemperamentSelector> {
  late Temperament temperament = widget.initialValue;

  void _setTemperament(Temperament value) {
    setState(() {
      temperament = value;
    });
    widget.onSelection?.call(value);
  }

  @override
  Widget build(BuildContext context) {
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
                    EqualTemperament() => "Equispaced steps, like a piano.",
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
  }
}

/// Widget for selecting a wave shape.
class WaveformShapeSelector extends StatefulWidget {
  const WaveformShapeSelector({
    super.key,
    required this.initialValue,
    this.onSelection,
  });

  static const Set<WaveForm> availableWaveforms = {
    WaveForm.sin,
    WaveForm.fSaw,
    WaveForm.fSquare,
    WaveForm.triangle,
  };

  final WaveForm initialValue;

  final void Function(WaveForm waveform)? onSelection;

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

  @override
  State<WaveformShapeSelector> createState() => _WaveformShapeSelectorState();
}

class _WaveformShapeSelectorState extends State<WaveformShapeSelector> {
  late WaveForm waveform = widget.initialValue;

  void _setWaveform(WaveForm value) {
    setState(() {
      waveform = value;
    });
    widget.onSelection?.call(value);
  }

  @override
  Widget build(BuildContext context) {
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
            for (WaveForm waveform in WaveformShapeSelector.availableWaveforms)
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
  }
}

/// Widget for selecting an accidental.
class ThemeSelector extends StatefulWidget {
  const ThemeSelector({
    super.key,
    required this.initialValue,
    this.onSelection,
  });

  final ThemeMode initialValue;

  final void Function(ThemeMode themeMode)? onSelection;

  /// Generate a short description for the given [themeMode].
  static String themeDescription(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.system => "System default",
      ThemeMode.light => "Light",
      ThemeMode.dark => "Dark",
    };
  }

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  late ThemeMode themeMode = widget.initialValue;

  void _setTheme(ThemeMode value) {
    setState(() {
      themeMode = value;
    });
    widget.onSelection?.call(value);
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
