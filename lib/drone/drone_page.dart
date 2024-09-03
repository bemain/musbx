import 'package:flutter/material.dart';
import 'package:musbx/drone/drone_controls.dart';
import 'package:musbx/page/card_list.dart';
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
      appBar: DefaultAppBar(),
      body: CardList(children: [
        DroneControls(),
      ]),
    );
  }
}
