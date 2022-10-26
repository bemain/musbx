import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/card_list.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
import 'package:musbx/tuner/tuning_graph.dart';
import 'package:musbx/widgets.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<StatefulWidget> createState() => TunerScreenState();
}

class TunerScreenState extends State<TunerScreen> {
  final Tuner tuner = Tuner.instance;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: tuner.initAudioFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorScreen(
            text: "Unable to initialize audio: \n${snapshot.error}",
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(text: "Initializing audio...");
        }

        return ValueListenableBuilder(
          valueListenable: tuner.currentNoteNotifier,
          builder: (context, currentNote, child) {
            return CardList(
              children: [
                TunerGauge(note: tuner.noteHistory.last),
                TuningGraph(),
              ],
            );
          },
        );
      },
    );
  }
}
