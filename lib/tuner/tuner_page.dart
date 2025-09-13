import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/tuner/fft_graph.dart';
import 'package:musbx/tuner/pitch_graph.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
import 'package:musbx/utils/loading.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/flat_card.dart';
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
      stream: tuner.dataStream,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          _buildPitchLabel(context),
                          const SizedBox(height: 32),
                          TunerGauge(
                            pitch: tuner.pitch,
                            showPitchText: false,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          PitchGraph(data: tuner.dataBuffer),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    FftGraph(
                      data: tuner.dataBuffer,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPitchLabel(BuildContext context) {
    final TextStyle? style = GoogleFonts.andikaTextTheme(
      Theme.of(context).textTheme,
    ).displayMedium;

    if (tuner.pitch == null) {
      return Center(
        child: SizedBox(
          height: 52,
          child: TextPlaceholder(
            style: style,
            width: 48.0,
          ),
        ),
      );
    }
    return Text(
      tuner.pitch!.abbreviation,
      style: style,
    );
  }
}
