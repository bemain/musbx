import 'package:flutter/material.dart';
import 'package:musbx/metronome/count_display.dart';
import 'package:musbx/metronome/bpm_buttons.dart';
import 'package:musbx/metronome/bpm_slider.dart';
import 'package:musbx/metronome/bpm_tapper.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/play_button.dart';

class MetronomeBottomBar extends StatefulWidget {
  /// BottomBar offering controls for [Metronome], including:
  /// - Play / pause button
  /// - Buttons for adjusting bpm
  /// - Slider for adjusting bpm
  /// - Button for setting bpm by tapping.
  /// - Buttons for setting what sound is played each beat.
  const MetronomeBottomBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MetronomeBottomBarState();
}

class MetronomeBottomBarState extends State<MetronomeBottomBar> {
  @override
  Widget build(BuildContext context) {
    return const BottomAppBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: Row(
              children: <Widget>[
                PlayButton(),
                Expanded(
                  child: Column(
                    children: [
                      BpmSlider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          BpmButtons(),
                          BpmTapper(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CountDisplay(),
          )
        ],
      ),
    );
  }
}
