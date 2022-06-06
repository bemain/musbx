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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ValueListenableBuilder<bool>(
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
                child: isRunning
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.play_arrow),
              );
            },
          ),
          SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ContinuousButton(
                  onPressed: () {
                    if (Metronome.bpm < Metronome.maxBpm) Metronome.bpm++;
                  },
                  child: const Icon(Icons.arrow_drop_up),
                ),
                ValueListenableBuilder(
                  valueListenable: Metronome.bpmNotifier,
                  builder: (BuildContext context, int bpm, Widget? child) =>
                      Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text("$bpm"),
                  ),
                ),
                ContinuousButton(
                  onPressed: () {
                    if (Metronome.bpm > Metronome.minBpm) Metronome.bpm--;
                  },
                  child: const Icon(Icons.arrow_drop_down),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
