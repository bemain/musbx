import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musbx/music_player/card_header.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/slowdowner/circular_slider/circular_slider.dart';

class SlowdownerCard extends StatelessWidget {
  /// Card with sliders for changing the pitch and speed of [MusicPlayer].
  ///
  /// Each slider is labeled with max and min value.
  /// Also features a button for resetting pitch and speed to the default values.
  SlowdownerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.enabledNotifier,
      builder: (context, enabled, _) => Column(
        children: [
          ValueListenableBuilder(
            valueListenable: musicPlayer.slowdowner.speedNotifier,
            builder: (_, speed, __) => ValueListenableBuilder(
              valueListenable: musicPlayer.slowdowner.pitchSemitonesNotifier,
              builder: (context, pitch, _) => CardHeader(
                title: "Slowdowner",
                enabled: enabled,
                onEnabledChanged: (value) =>
                    musicPlayer.slowdowner.enabled = value,
                onResetPressed: (speed.toStringAsFixed(2) == "1.00" &&
                        pitch.abs().toStringAsFixed(1) == "0.0")
                    ? null
                    : () {
                        musicPlayer.slowdowner.setSpeed(1.0);
                        musicPlayer.slowdowner.setPitchSemitones(0);
                      },
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, BoxConstraints constraints) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Don't show pitch slider on iOS since setPitch() method is not implemented.
                if (!Platform.isIOS) buildPitchSlider(constraints.maxWidth / 4),
                buildSpeedSlider(constraints.maxWidth / 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the MusicPlayer was playing before the user began changing the pitch or speed.
  static bool wasPlayingBeforeChange = false;

  Widget buildPitchSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.pitchSemitonesNotifier,
      builder: (context, pitch, _) => Stack(children: [
        CircularSlider(
          value: pitch,
          min: -12,
          max: 12,
          divisionValues: List.generate(25, (i) => i - 12.0),
          outerRadius: radius,
          onChanged: musicPlayer.nullIfNoSongElse(
            (!musicPlayer.slowdowner.enabled)
                ? null
                : (double value) {
                    musicPlayer.slowdowner
                        .setPitchSemitones((value * 10).roundToDouble() / 10);
                  },
          ),
          onChangeStart: () {
            wasPlayingBeforeChange = musicPlayer.isPlaying;
            musicPlayer.pause();
          },
          onChangeEnd: () {
            if (wasPlayingBeforeChange) musicPlayer.play();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: NumberField(
                  value: double.parse(pitch.toStringAsFixed(1)),
                  min: -12.0,
                  max: 12.0,
                  style: Theme.of(context).textTheme.displaySmall,
                  prefixWithSign: true,
                  onSubmitted: musicPlayer.nullIfNoSongElse((value) {
                    musicPlayer.slowdowner.setPitchSemitones(value);
                  }),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: Text(
              "Pitch",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildSpeedSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.speedNotifier,
      builder: (context, speed, _) => Stack(children: [
        CircularSlider(
          value: sqrt(speed - 7 / 16) - 0.25,
          min: 0,
          max: 1,
          divisionValues: List.generate(
                  21, (i) => (i <= 10) ? 0.5 + i / 20 : 0.5 - 10 / 20 + i / 10)
              .map((speedValue) => sqrt(speedValue - 7 / 16) - 0.25)
              .toList(),
          outerRadius: radius,
          onChanged: musicPlayer.nullIfNoSongElse(
            (!musicPlayer.slowdowner.enabled)
                ? null
                : (double value) {
                    musicPlayer.slowdowner
                        .setSpeed(pow(value, 2) + value / 2 + 0.5);
                  },
          ),
          onChangeStart: () {
            wasPlayingBeforeChange = musicPlayer.isPlaying;
            musicPlayer.pause();
          },
          onChangeEnd: () {
            if (wasPlayingBeforeChange) musicPlayer.play();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: NumberField(
                  value: double.parse(speed.toStringAsFixed(2)),
                  min: 0.5,
                  max: 2.0,
                  prefixWithSign: false,
                  style: Theme.of(context).textTheme.displaySmall,
                  inputFormatters: [
                    // Don't allow negative numbers
                    FilteringTextInputFormatter.deny(RegExp(r"-"))
                  ],
                  onSubmitted: musicPlayer.nullIfNoSongElse((value) {
                    musicPlayer.slowdowner.setSpeed(value);
                  }),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: Text(
              "Speed",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.speedNotifier,
      builder: (_, speed, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.slowdowner.pitchSemitonesNotifier,
        builder: (context, pitch, _) => IconButton(
          iconSize: 20,
          onPressed: (speed.toStringAsFixed(2) == "1.00" &&
                  pitch.abs().toStringAsFixed(1) == "0.0")
              ? null
              : () {
                  musicPlayer.slowdowner.setSpeed(1.0);
                  musicPlayer.slowdowner.setPitchSemitones(0);
                },
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class NumberField extends StatelessWidget {
  NumberField({
    super.key,
    this.value,
    this.min,
    this.max,
    required this.onSubmitted,
    this.prefixWithSign = true,
    this.style,
    this.inputFormatters,
  });

  final double? value;
  final double? min;
  final double? max;

  /// If `true`, automatically prefixes the value with the correct sign.
  ///
  /// When the user starts editing the value, the prefix is removed so that the sign can be edited.
  final bool prefixWithSign;
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;

  final void Function(double value)? onSubmitted;

  late final TextEditingController controller = TextEditingController(
    text: prefixWithSign ? value?.abs().toString() : value?.toString(),
  );

  /// Optional text prefix to place on the line before the input.
  late final ValueNotifier<String?> prefixText =
      ValueNotifier(!prefixWithSign || value == null
          ? null
          : value! >= 0
              ? "+"
              : "-");

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prefixText,
      builder: (context, child) => TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixText: prefixText.value,
          border: const UnderlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
        ),
        style: style,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(
              r"^(-|-?\d+(?:\.\d*)?)$")), // Allow positive and negative decimal numbers, as well as just a minus sign
          ...?inputFormatters,
        ],
        maxLines: 1,
        enabled: onSubmitted != null,
        onChanged: (value) {
          /// Remove prefix and instead add the minus sign to the text, so that it can be edited.
          if (prefixText.value == "-" && !value.startsWith("-")) {
            controller.text = "-${controller.text}";
          }
          prefixText.value = null;
        },
        onSubmitted: (value) {
          double? parsed = double.tryParse(value);
          if (parsed == null) {
            // Reset to the actual value
            if (this.value != null) controller.text = this.value.toString();
            return;
          }

          double clamped = parsed.clamp(
            min ?? double.negativeInfinity,
            max ?? double.infinity,
          );
          controller.text = clamped.toString();
          onSubmitted?.call(clamped);
        },
      ),
    );
  }
}
