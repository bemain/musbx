import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        minTileHeight: 56,
      ),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: SettingsList(
        children: [
          SectionTitle(text: "Tuner"),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.tuningNotifier,
            builder: (context, tuning, child) => ListTile(
              leading: Icon(CustomIcons.tuning_fork),
              title: Text("Tuning"),
              subtitle: Text(
                "${tuning.frequency.toStringAsFixed(0)} Hz",
              ),
              onTap: () async {
                final double? frequency = await showDialog<double>(
                  context: context,
                  builder: (context) => TuningSelector(
                    initialFrequency: tuning.frequency.toInt(),
                  ),
                );
                if (frequency == null) return;

                Tuner.instance.tuning = Pitch(PitchClass.a(), 4, frequency);
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.preferredAccidentalNotifier,
            builder: (context, accidental, child) => ListTile(
              leading: Icon(CustomIcons.accidentals),
              title: Text("Preferred accidentals"),
              subtitle: Text(
                AccidentalSelector.accidentalDescription(accidental),
              ),
              onTap: () async {
                final Accidental? value = await showDialog<Accidental>(
                  context: context,
                  builder: (context) => AccidentalSelector(
                    initialAccidental: accidental,
                  ),
                );
                if (value == null) return;

                Tuner.instance.preferredAccidental = value;
              },
            ),
          ),

          SectionTitle(text: "General"),
          ListTile(
            leading: Icon(Symbols.policy),
            title: Text("Privacy policy"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io/musbx/privacy"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.contract),
            title: Text("Licenses"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.licenses);
            },
          ),
          if (!Purchases.hasPremium)
            ListTile(
              leading: Icon(Symbols.workspace_premium),
              title: Text("Upgrade to Premium"),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const FreeAccessRestrictedDialog(),
                );
              },
            ),

          SectionTitle(text: "Contact me"),
          ListTile(
            leading: Icon(Symbols.mail),
            title: Text("Mail"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("mailto:bemain.dev@gmail.com"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.captive_portal),
            title: Text("Website"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io"));
            },
          ),
          ListTile(
            leading: Icon(SimpleIcons.github),
            title: Text("GitHub"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://github.com/bemain"));
            },
          ),

          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              text: "Version ${LaunchHandler.info.version}\n",
              style: TextTheme.of(context).bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(0x50),
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Symbols.copyright,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(0x50),
                  ),
                ),
                TextSpan(text: " Benjamin Agardh ${DateTime.now().year}"),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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

  /// The initial frequency, in Hz.
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

  /// The pre-selected accidental.
  final Accidental initialAccidental;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
