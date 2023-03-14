import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/drone/drone_controls.dart';
import 'package:musbx/screen/card_list.dart';
import 'package:musbx/screen/default_app_bar.dart';
import 'package:musbx/widgets.dart';

class DroneScreen extends StatefulWidget {
  const DroneScreen({super.key});

  @override
  State<StatefulWidget> createState() => DroneScreenState();
}

class DroneScreenState extends State<DroneScreen> {
  @override
  Widget build(BuildContext context) {
    if (!Drone.instance.initialized) {
      return FutureBuilder(
        future: Drone.instance.initialize(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorScreen(
              text: "Unable to initialize Drone\n${snapshot.error}",
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen(text: "Initializing Drone...");
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
          return const InfoScreen(
            icon: Icon(Icons.done),
            text: "Drone initialized",
          );
        },
      );
    }

    return const Scaffold(
      appBar: DefaultAppBar(),
      body: CardList(children: [
        DroneControls(),
      ]),
    );
  }
}
