import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/drone/drone_octave.dart';
import 'package:musbx/drone/drone_wheel.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:provider/provider.dart';

/// Page for playing drone tones, letting the user pick a root note and the
/// intervals sounding above it.
class DronePage extends StatefulWidget {
  const DronePage({super.key});

  @override
  State<StatefulWidget> createState() => DronePageState();
}

class DronePageState extends State<DronePage> {
  @override
  Widget build(BuildContext context) {
    Drone.initialize(sharedPreferences: context.read());

    return const Scaffold(
      appBar: DefaultAppBar(),
      body: Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            Expanded(child: DroneWheel()),
            SizedBox(height: 16),
            DroneOctave(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
