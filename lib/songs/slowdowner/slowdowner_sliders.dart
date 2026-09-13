import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:provider/provider.dart';

Widget _buildCircularPlaceholder(BuildContext context, {double radius = 64}) {
  return ShimmerLoading(
    child: Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      child: SizedBox(
        height: max(radius * 1.25 + 52, radius * 2),
        width: radius * 2,
      ),
    ),
  );
}

/// A button returning the pitch and speed to their defaults. Disabled while they
/// already are.
class PitchSpeedResetButton extends StatelessWidget {
  const PitchSpeedResetButton({super.key});

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    if (playback.song == null) {
      return IconButton(
        onPressed: null,
        iconSize: 20,
        icon: const Icon(Symbols.refresh),
      );
    }

    return IconButton(
      onPressed:
          (playback.speed.toStringAsFixed(2) == "1.00" &&
              playback.pitch.abs().toStringAsFixed(1) == "0.0")
          ? null
          : () {
              playback.speed = 1.0;
              playback.pitch = 0;
            },
      iconSize: 20,
      icon: const Icon(Symbols.refresh),
    );
  }
}

/// A circular slider for transposing the song, in semitones.
class PitchSlider extends StatelessWidget {
  const PitchSlider({super.key, this.radius = 64});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    if (playback.song == null) {
      return _buildCircularPlaceholder(context, radius: radius);
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CircularSlider(
          value: playback.pitch,
          min: -12,
          max: 12,
          divisionValues: List.generate(25, (i) => i - 12.0),
          outerRadius: radius,
          onChanged: (value) {
            playback.pitch = (value * 10).roundToDouble() / 10;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CustomIcons.accidentals),
              SizedBox(height: 4),
              Text(
                "pitch",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: radius * 1.25),
            SizedBox(
              width: 64,
              child: NumberField<double>(
                value: double.parse(playback.pitch.toStringAsFixed(1)),
                min: -12.0,
                max: 12.0,
                style: Theme.of(context).textTheme.headlineMedium,
                prefixWithSign: true,
                onSubmitted: (value) {
                  playback.pitch = value;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A circular slider for changing the tempo of the song, as a fraction of its
/// original.
class SpeedSlider extends StatelessWidget {
  const SpeedSlider({super.key, this.radius = 64});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    if (playback.song == null) {
      return _buildCircularPlaceholder(context, radius: radius);
    }
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CircularSlider(
          value: sqrt(playback.speed - 7 / 16) - 0.25,
          min: 0,
          max: 1,
          divisionValues: List.generate(
            21,
            (i) => (i <= 10) ? 0.5 + i / 20 : 0.5 - 10 / 20 + i / 10,
          ).map((speedValue) => sqrt(speedValue - 7 / 16) - 0.25).toList(),
          outerRadius: radius,
          onChanged: (value) {
            playback.speed = pow(value, 2) + value / 2 + 0.5;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.avg_pace),
              SizedBox(height: 4),
              Text(
                "speed",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: radius * 1.3),
            SizedBox(
              width: 64,
              child: NumberField<double>(
                value: double.parse(playback.speed.toStringAsFixed(2)),
                min: 0.5,
                max: 2.0,
                prefixWithSign: false,
                style: Theme.of(context).textTheme.headlineMedium,
                inputFormatters: [
                  // Don't allow negative numbers
                  FilteringTextInputFormatter.deny(RegExp(r"-")),
                ],
                onSubmitted: (value) {
                  playback.speed = value;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
