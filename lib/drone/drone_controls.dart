import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/tuner/note.dart';
import 'package:musbx/widgets.dart';

class DroneControls extends StatefulWidget {
  const DroneControls({super.key, this.radius = 150});

  final double radius;

  @override
  State<StatefulWidget> createState() => DroneControlsState();
}

class DroneControlsState extends State<DroneControls> {
  final Drone drone = Drone.instance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => SizedBox(
        height: constraints.maxWidth,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(12, (index) => buildButton(index)),
        ),
      ),
    );
  }

  Widget buildButton(int index) {
    final double angle = 2 * pi * index / 12;
    return StreamBuilder(
        initialData: false,
        stream: drone.players[index].playingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorScreen(text: "${snapshot.error}");
          if (!snapshot.hasData) {
            return const LoadingScreen(text: "Initializing drone");
          }

          final bool active = snapshot.data!;

          return Transform(
            transform: Matrix4.identity()
              ..translate(
                  widget.radius * cos(angle), widget.radius * sin(angle)),
            child: FloatingActionButton(
              elevation: active ? 0 : 6,
              backgroundColor:
                  active ? Theme.of(context).colorScheme.primary : null,
              onPressed: () {
                if (active) {
                  drone.players[index].pause();
                } else {
                  drone.players[index].play();
                }
              },
              child: Text(Note.noteNames[index]),
            ),
          );
        });
  }
}
