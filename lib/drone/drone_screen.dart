import 'package:flutter/material.dart';
import 'package:musbx/drone/drone_controls.dart';
import 'package:musbx/card_list.dart';

class DroneScreen extends StatelessWidget {
  const DroneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardList(children: [
      DroneControls(),
    ]);
  }
}
