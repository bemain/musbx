import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/editable_screen.dart';
import 'package:musbx/metronome/beat_sound_viewer.dart';
import 'package:musbx/metronome/bpm_buttons.dart';
import 'package:musbx/metronome/bpm_slider.dart';
import 'package:musbx/metronome/bpm_tapper.dart';
import 'package:musbx/metronome/play_button.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EditableScreen(
      title: "Metronome",
      widgets: [
        Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              BpmButtons(
                iconSize: 50,
                fontSize: 45,
              ),
              BpmTapper()
            ],
          ),
          const BpmSlider(),
        ]),
        Column(children: const [
          Center(
            child: PlayButton(
              size: 150,
            ),
          ),
          BeatSoundViewer(),
        ]),
      ],
    );
  }
}
