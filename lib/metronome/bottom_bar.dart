import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets.dart';

class MetronomeBottomBar extends StatefulWidget {
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
                  _buildBpmButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildBpmButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContinuousButton(
          onPressed: () {
            if (Metronome.bpm < Metronome.maxBpm) Metronome.bpm++;
          },
          child: const Icon(
            Icons.arrow_drop_up,
            size: 35,
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: _buildBpmText()),
        ContinuousButton(
          onPressed: () {
            if (Metronome.bpm > Metronome.minBpm) Metronome.bpm--;
          },
          child: const Icon(
            Icons.arrow_drop_down,
            size: 35,
          ),
        )
      ],
    );
  }

  Widget _buildBpmText() {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Text(
          "$bpm",
          style: const TextStyle(fontSize: 20),
        );
      },
    );
  }
}
