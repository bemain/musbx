import 'package:flutter/material.dart';
import 'package:musbx/metronome/bpm_buttons.dart';
import 'package:musbx/metronome/bpm_tapper.dart';
import 'package:musbx/metronome/metronome.dart';

class MetronomeBottomBar extends StatefulWidget {
  /// BottomBar offering controls for [Metronome], including:
  /// - Play / pause button
  /// - Buttons for adjusting bpm
  /// - Slider for adjusting bpm
  /// - Button for setting bpm by tapping.
  const MetronomeBottomBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MetronomeBottomBarState();
}

class MetronomeBottomBarState extends State<MetronomeBottomBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 100,
        child: Row(
          children: <Widget>[
            _buildPlayButton(),
            Expanded(
              child: Column(
                children: [
                  _buildBpmSlider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
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
    );
  }

  /// Play / pause button to start or stop the [Metronome].
  Widget _buildPlayButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.isRunningNotifier,
      builder: (context, bool isRunning, child) {
        return TextButton(
          onPressed: () {
            if (isRunning) {
              Metronome.stop();
            } else {
              Metronome.start();
            }
          },
          child: Icon(
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 75,
          ),
        );
      },
    );
  }

  /// Simple Slider for adjusting bpm.
  Widget _buildBpmSlider() {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Slider(
          min: Metronome.minBpm.toDouble(),
          max: Metronome.maxBpm.toDouble(),
          value: Metronome.bpm.toDouble(),
          onChanged: (double value) {
            Metronome.bpm = value.toInt();
          },
        );
      },
    );
  }
}
