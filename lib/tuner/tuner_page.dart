import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/domain/models/frequency_detection.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/tuner/pitch_graph.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
import 'package:musbx/tuner/tuner_reading.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:musbx/widgets/permission_builder.dart';
import 'package:provider/provider.dart';

/// Page that detects the pitch from the microphone and displays it.
///
/// Includes:
///  - Gauge showing what note is being played and how out of tune it is.
///  - Graph showing how the tuning has changed over time.
class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<StatefulWidget> createState() => TunerPageState();
}

class TunerPageState extends State<TunerPage> {
  late final TunerRepository tuner = context.read();
  late final SettingsRepository settings = context.read();

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

    return StreamBuilder(
      stream: tuner.dataStream,
      builder: (context, snapshot) => ValueListenableBuilder(
        valueListenable: settings.tuner.tuningNotifier,
        builder: (context, tuning, child) => ValueListenableBuilder(
          valueListenable: settings.tuner.temperamentNotifier,
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
                            reading: tuner.latestReading == null
                                ? null
                                : _tunerReading(tuner.latestReading!),
                            showPitchText: false,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          PitchGraph(
                            data: [
                              for (final detection in tuner.dataBuffer)
                                _tunerReading(detection),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
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

  TunerReading _tunerReading(FrequencyDetection detection) =>
      TunerReading.fromFrequency(
        detection.frequency,
        frame: detection.frame,
        tuning: settings.tuner.tuning,
        temperament: settings.tuner.temperament,
        preferredAccidental: settings.tuner.preferredAccidental,
      );

  Widget _buildPitchLabel(BuildContext context) {
    final TextStyle? style = GoogleFonts.andikaTextTheme(
      Theme.of(context).textTheme,
    ).displayMedium;

    if (tuner.latestReading?.frequency == null) {
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
      _tunerReading(tuner.latestReading!).pitch!.abbreviation,
      style: style,
    );
  }
}
