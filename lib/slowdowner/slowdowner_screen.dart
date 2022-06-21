import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/button_panel.dart';
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
      children: const [
        PositionSlider(),
        ButtonPanel(),
      ],
    );
  }
}
