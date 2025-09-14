import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/model/accidental.dart';

class TuningSelector extends StatelessWidget {
  /// Widget for selecting a frequency to use as the tuning of A4.
  TuningSelector({
    super.key,
    this.initialFrequency = 440,
    this.minFrequency = 415,
    this.maxFrequency = 456,
  }) : controller = TextEditingController(text: "$initialFrequency");

  final TextEditingController controller;

  static const int baseFrequency = 440;

  /// The initial pre-selected frequency, in Hz.
  final int initialFrequency;

  /// The minimum frequency that can be entered, in Hz.
  final int minFrequency;

  /// The maximum frequency that can be entered, in Hz.
  final int maxFrequency;

  /// The current frequency entered.
  int get frequency =>
      (int.tryParse(controller.text) ?? initialFrequency).clamp(
        minFrequency,
        maxFrequency,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Select tuning"),
          ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return IconButton(
                onPressed: frequency == baseFrequency
                    ? null
                    : () {
                        controller.text = "$baseFrequency";
                      },
                icon: Icon(Symbols.refresh),
                iconSize: 20,
              );
            },
          ),
        ],
      ),
      content: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: frequency > minFrequency
                      ? () {
                          controller.text = (frequency - 1).toString();
                        }
                      : null,
                  icon: Icon(Symbols.remove),
                ),
                Expanded(
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
                      // Clamp frequency
                      controller.text = "$frequency";
                    },
                  ),
                ),
                IconButton(
                  onPressed: frequency < maxFrequency
                      ? () {
                          controller.text = (frequency + 1).toString();
                        }
                      : null,
                  icon: Icon(Symbols.add),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(frequency.toDouble());
          },
          child: Text("Apply"),
        ),
      ],
    );
  }
}

class AccidentalSelector extends StatefulWidget {
  /// Widget for selecting an accidental.
  const AccidentalSelector({
    super.key,
    this.initialAccidental = Accidental.flat,
  });

  /// The initial pre-selected accidental.
  final Accidental initialAccidental;

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
  late Accidental? accidental = widget.initialAccidental;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select accidental"),
      content: RadioGroup<Accidental>(
        groupValue: accidental,
        onChanged: (value) {
          setState(() {
            accidental = value;
          });
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
                  onTap: () {
                    setState(() {
                      this.accidental = accidental;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(accidental);
          },
          child: Text("Apply"),
        ),
      ],
    );
  }
}
