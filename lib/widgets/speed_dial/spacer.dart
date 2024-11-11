import 'package:flutter/material.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';

class SpeedDialSpacer extends SpeedDialChild {
  /// A child of [SpeedDial] that adds empty space between children.
  SpeedDialSpacer({this.height = 8});

  /// The height of the empty space.
  final double height;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    return SizedBox(
      height: height,
    );
  }
}
