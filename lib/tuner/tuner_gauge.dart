import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/model/note.dart';
import 'package:musbx/tuner/tuner.dart';

class TunerGauge extends StatelessWidget {
  /// Gauge for showing how out of tune [frequency] is.
  ///
  /// Includes labels displaying the name of the note closest to [frequency]
  /// and how many cents out of tune it is.
  ///
  /// If [frequency] is `null`, instead displays a "listening" label.
  const TunerGauge({super.key, required this.frequency});

  /// The frequency to display.
  final double? frequency;

  @override
  Widget build(BuildContext context) {
    return (frequency == null)
        ? buildListeningGauge(context)
        : buildGaugeAndText(context);
  }

  /// Build gauge with "listening" text.
  Widget buildListeningGauge(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.5),
            child: Text(
              "Listening...",
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
        ),
        buildGauge(context),
      ],
    );
  }

  /// Build gage showing [frequency]'s name and tuning.
  Widget buildGaugeAndText(BuildContext context) {
    if (frequency == null) return const SizedBox();
    final Note note = Note.fromFrequency(
      frequency!,
      temperament: Tuner.instance.temperament,
    );
    final double pitchOffset = Tuner.instance.calculatePitchOffset(frequency!);

    ColorScheme scheme = Theme.of(context).colorScheme;

    // If note is in tune, make needle green
    List<Color> needleColors = (pitchOffset < Tuner.inTuneThreshold)
        ? [
            Colors.lightGreen.harmonizeWith(scheme.primary),
            Colors.green.harmonizeWith(scheme.primary),
          ]
        : (scheme.brightness == Brightness.light)
            ? [
                scheme.onSurfaceVariant,
                scheme.onSurface,
              ]
            : [
                scheme.primary,
                scheme.inversePrimary,
              ];

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: const Alignment(-0.55, 0.7),
            child: Text(
              note.abbreviation,
              style: GoogleFonts.andikaTextTheme(Theme.of(context).textTheme)
                  .displayMedium,
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0.6, 0.7),
            child: Text(
              (pitchOffset.toInt().isNegative)
                  ? "${pitchOffset.toInt()}¢"
                  : "+${pitchOffset.toInt()}¢",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ),
        buildGauge(context, [
          RadialNeedlePointer(
            value: pitchOffset,
            thicknessStart: 20,
            thicknessEnd: 0,
            length: 0.8,
            knobColor: (scheme.brightness == Brightness.light)
                ? scheme.onSurface
                : scheme.onPrimary,
            knobRadiusAbsolute: 10,
            gradient: LinearGradient(
              colors: needleColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.5, 0.5],
            ),
          ),
        ]),
      ],
    );
  }

  /// Build a radial gauge with the "in-tune"-section highlighted green,
  /// and optionally with some [pointers].
  Widget buildGauge(
    BuildContext context, [
    List<RadialGaugePointer>? pointers,
  ]) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.53,
        child: RadialGauge(
          axes: [
            RadialGaugeAxis(
              minValue: -1,
              maxValue: 1,
              minAngle: -18,
              maxAngle: 18,
              radius: 0,
              width: 0.8,
              color: Colors.green
                  .harmonizeWith(Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
            ),
            RadialGaugeAxis(
              minValue: -50,
              maxValue: 50,
              minAngle: -90,
              maxAngle: 90,
              ticks: [
                RadialTicks(
                  interval: 10,
                  alignment: RadialTickAxisAlignment.inside,
                  length: 0.1,
                  color: Theme.of(context).colorScheme.primary,
                  children: [
                    RadialTicks(
                      ticksInBetween: 4,
                      length: 0.05,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  ],
                ),
                RadialTicks(
                  values: [for (double i = -9; i <= 9; i++) i]..remove(0),
                  length: 0.05,
                  color: Colors.green
                      .harmonizeWith(Theme.of(context).colorScheme.primary),
                )
              ],
              pointers: pointers,
            ),
          ],
        ),
      ),
    );
  }
}
