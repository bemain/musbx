import 'package:flutter/material.dart';
import 'package:musbx/metronome/count_display.dart';
import 'package:musbx/metronome/bpm_buttons.dart';
import 'package:musbx/metronome/bpm_slider.dart';
import 'package:musbx/metronome/bpm_tapper.dart';
import 'package:musbx/metronome/play_button.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/subdivisions.dart';
import 'package:musbx/metronome/higher.dart';
import 'package:musbx/screen/default_app_bar.dart';

class MetronomeScreen extends StatelessWidget {
  /// Screen for controlling [Metronome], including:
  /// - Play / pause button
  /// - Buttons for adjusting bpm
  /// - Slider for adjusting bpm
  /// - Button for setting bpm by tapping.
  /// - Buttons for setting what sound is played each beat.
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: DefaultAppBar(
        helpText:
            """Set bpm using slider or hit the drum. Make fine adjustments using the arrows.
Change the sound of beats by tapping them. Long press to remove and plus to add.""",
      ),
      body: Column(
        children: [
          Higher(),
          SizedBox(height: 8.0),
          Subdivisions(),
          Expanded(
            child: Center(
              child: PlayButton(size: 150),
            ),
          ),
          CountDisplay(),
          SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BpmButtons(),
              BpmTapper(),
            ],
          ),
          BpmSlider(),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
