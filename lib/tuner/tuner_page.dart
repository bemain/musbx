import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
import 'package:musbx/tuner/tuning_graph.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/permission_builder.dart';
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
    if (!tuner.hasPermission) {
      return PermissionBuilder(
        permission: Permission.microphone,
        permissionName: "microphone",
        permissionText:
            "To use the tuner, give the app permission to access the microphone.",
        permissionDeniedIcon: const Icon(Symbols.mic_off_rounded, size: 128),
        permissionGrantedIcon: const Icon(Symbols.mic_rounded, size: 128),
        onPermissionGranted: () async {
          setState(() {
            tuner.hasPermission = true;
          });
        },
      );
    }

    if (!tuner.isInitialized) {
      tuner.initialize().then((_) {
        setState(() {});
      });
      return const SizedBox(); // TODO: Show shimmer loading
    }

    return StreamBuilder(
      stream: tuner.frequencyStream,
      builder: (context, snapshot) => ValueListenableBuilder(
        valueListenable: tuner.tuningNotifier,
        builder: (context, tuning, child) => ValueListenableBuilder(
          valueListenable: tuner.temperamentNotifier,
          builder: (context, temperament, child) {
            return Scaffold(
              appBar: const DefaultAppBar(),
              body: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TunerGauge(
                        frequency: (tuner.frequencyHistory.isNotEmpty)
                            ? tuner.frequencyHistory.last
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(),
                    TuningGraph(frequencyHistory: tuner.frequencyHistory),
                    const Divider(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
