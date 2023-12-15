import 'package:flutter/material.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';

class SpeedDialSpacer extends SpeedDialChild {
  SpeedDialSpacer({this.height = 8});

  final double height;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    return SizedBox(
      height: height,
    );
  }
}
