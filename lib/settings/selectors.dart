import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/widgets/alert_sheet.dart';

class TuningSelector extends StatelessWidget {
  /// Widget for selecting a frequency to use as the tuning of A4.
  const TuningSelector({
    super.key,
    this.minFrequency = 415,
    this.maxFrequency = 456,
  });

  static const int baseFrequency = 440;

  /// The minimum frequency that can be entered, in Hz.
  final int minFrequency;

  /// The maximum frequency that can be entered, in Hz.
  final int maxFrequency;

  void _setTuning(num frequency) {
    Tuner.instance.tuning = Pitch(PitchClass.a(), 4, frequency.toDouble());
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
      valueListenable: Tuner.instance.tuningNotifier,
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
            padding: EdgeInsetsGeometry.symmetric(vertical: 32),
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
    super.key,
  });

  /// Generate a short description for the given [accidental].
  static String accidentalDescription(Accidental accidental) {
    return switch (accidental) {
      Accidental.natural => "Adaptive",
      Accidental.sharp => "Sharps",
      Accidental.flat => "Flats",
    };
  }

  void _setAccidental(Accidental accidental) {
    Tuner.instance.preferredAccidental = accidental;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Tuner.instance.preferredAccidentalNotifier,
      builder: (context, accidental, child) {
        return AlertSheet(
          title: Text("Select accidental"),
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
