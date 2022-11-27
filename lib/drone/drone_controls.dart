import 'dart:math';

import 'package:flutter/material.dart';

class DroneControls extends StatefulWidget {
  const DroneControls({super.key, this.radius = 150});

  final double radius;

  @override
  State<StatefulWidget> createState() => DroneControlsState();
}

class DroneControlsState extends State<DroneControls> {
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

  Widget buildButton(int index, {bool active = false}) {
    final double angle = 2 * pi * index / 12;
    return Transform(
        transform: Matrix4.identity()
          ..translate(widget.radius * cos(angle), widget.radius * sin(angle)),
        child: FloatingActionButton(
          elevation: active ? 0 : 6,
          backgroundColor:
              active ? Theme.of(context).colorScheme.primary : null,
          onPressed: () {},
          child: const Icon(Icons.circle),
        ));
  }
}
