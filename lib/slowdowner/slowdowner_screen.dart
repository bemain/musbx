import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/button_panel.dart';
import 'package:musbx/slowdowner/stream_slider.dart';
import 'package:musbx/slowdowner/position_slider.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class SlowdownerScreen extends StatefulWidget {
  const SlowdownerScreen({super.key});

  @override
  State<StatefulWidget> createState() => SlowdownerScreenState();
}

class SlowdownerScreenState extends State<SlowdownerScreen> {
  @override
  void initState() {
    super.initState();

    Slowdowner.audioPlayer.setAsset("assets/youve_got.mp3");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Pitch",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        buildPitchSlider(),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Speed",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        buildSpeedSlider(),
        const Divider(),
        const PositionSlider(),
        const ButtonPanel(),
      ],
    );
  }

  Widget buildPitchSlider() {
    return StreamSlider(
      stream: Slowdowner.audioPlayer.pitchStream,
      onChangeEnd: (double value) {
        Slowdowner.audioPlayer.setPitch(value);
      },
      onClear: () {
        Slowdowner.audioPlayer.setPitch(1.0);
      },
      min: 0.1,
      max: 2,
      startValue: 1.0,
      divisions: 19,
      labelFractionDigits: 1,
    );
  }

  Widget buildSpeedSlider() {
    return StreamSlider(
      stream: Slowdowner.audioPlayer.speedStream,
      onChangeEnd: (double value) {
        Slowdowner.audioPlayer.setSpeed(value);
      },
      onClear: () {
        Slowdowner.audioPlayer.setSpeed(1.0);
      },
      min: 0.1,
      max: 2,
      startValue: 1.0,
      divisions: 19,
      labelFractionDigits: 1,
    );
  }
}
