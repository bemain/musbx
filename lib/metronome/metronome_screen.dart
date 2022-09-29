import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/editable_screen.dart';
import 'package:musbx/metronome/beat_sound_viewer.dart';
import 'package:musbx/metronome/bpm_slider.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/play_button.dart';
import 'package:musbx/widgets.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EditableScreen(
      title: "Metronome",
      widgets: [
        Column(children: const [
          Center(
            child: PlayButton(
              size: 150,
            ),
          ),
          BeatSoundViewer(),
        ]),
        Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ContinuousButton(
                onPressed: () {
                  Metronome.bpm--;
                },
                child: const Icon(
                  Icons.arrow_drop_up_rounded,
                  size: 50,
                ),
              ),
              _buildBpmText(context),
              ContinuousButton(
                onPressed: () {
                  Metronome.bpm++;
                },
                child: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 50,
                ),
              ),
            ],
          ),
          const BpmSlider(),
        ]),
      ],
    );
  }

  Widget _buildBpmText(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Text(
          "$bpm",
          style: const TextStyle(fontSize: 45),
        );
      },
    );
  }
}
