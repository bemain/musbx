import 'package:flutter/material.dart';
import 'package:musbx/permission_builder.dart';
import 'package:musbx/page/card_list.dart';
import 'package:musbx/page/default_app_bar.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
import 'package:musbx/tuner/tuning_graph.dart';
import 'package:permission_handler/permission_handler.dart';

class TunerPage extends StatefulWidget {
  /// Page that detects the pitch from the microphone and displays it.
  ///
  /// Includes:
  ///  - Gauge showing what note is being played and how out of tune it is.
  ///  - Graph showing how the tuning has changed over time.
  const TunerPage({super.key});

  @override
  State<StatefulWidget> createState() => TunerPageState();
}

class TunerPageState extends State<TunerPage> {
  final Tuner tuner = Tuner.instance;

  @override
  Widget build(BuildContext context) {
    if (!tuner.initialized) {
      return PermissionBuilder(
          permission: Permission.microphone,
          permissionName: "microphone",
          permissionText:
              "To use the tuner, give the app permission to access the microphone.",
          permissionDeniedIcon: const Icon(Icons.mic_off_rounded, size: 128),
          permissionGrantedIcon: const Icon(Icons.mic_rounded, size: 128),
          onPermissionGranted: () async {
            tuner.initialize();
            setState(() {});
          });
    }
    return StreamBuilder(
      stream: tuner.noteStream,
      builder: (context, snapshot) => Scaffold(
        appBar: const DefaultAppBar(),
        body: CardList(
          children: [
            TunerGauge(
              note: (tuner.noteHistory.isNotEmpty)
                  ? tuner.noteHistory.last
                  : null,
            ),
            TuningGraph(noteHistory: tuner.noteHistory),
          ],
        ),
      ),
    );
  }
}
