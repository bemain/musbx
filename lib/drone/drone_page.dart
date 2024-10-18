import 'package:flutter/material.dart';
import 'package:musbx/drone/drone_octave.dart';
import 'package:musbx/drone/drone_wheel.dart';
import 'package:musbx/page/default_app_bar.dart';

class DronePage extends StatefulWidget {
  const DronePage({super.key});

  @override
  State<StatefulWidget> createState() => DronePageState();
}

class DronePageState extends State<DronePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: DefaultAppBar(
        helpText:
            "Press a note to play it. \nRotate the wheel to change the key.",
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            Expanded(child: DroneWheel()),
            SizedBox(height: 16),
            DroneOctave(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
