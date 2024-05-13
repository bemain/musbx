import 'package:flutter/material.dart';
import 'package:musbx/metronome/count_display.dart';
import 'package:musbx/metronome/bpm_buttons.dart';
import 'package:musbx/metronome/bpm_slider.dart';
import 'package:musbx/metronome/bpm_tapper.dart';
import 'package:musbx/metronome/notification_indicator.dart';
import 'package:musbx/metronome/play_button.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/subdivisions.dart';
import 'package:musbx/metronome/higher.dart';
import 'package:musbx/metronome/volume_indicator.dart';
import 'package:musbx/page/default_app_bar.dart';
import 'package:musbx/page/widget_card.dart';

class MetronomePage extends StatelessWidget {
  /// Page for controlling [Metronome], including:
  /// - Play / pause button
  /// - Buttons for adjusting bpm
  /// - Slider for adjusting bpm
  /// - Button for setting bpm by tapping.
  /// - Buttons for setting what sound is played each beat.
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Column(
        children: [
          const WidgetCard(
            child: Column(
              children: [
                Higher(),
                SizedBox(height: 8.0),
                Subdivisions(),
              ],
            ),
          ),
          Expanded(
            child: WidgetCard(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: CountDisplay(),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: const PlayButton(),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VolumeIndicator(),
                        NotificationIndicator(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const WidgetCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BpmButtons(),
                    BpmTapper(),
                  ],
                ),
                BpmSlider(),
              ],
            ),
          ),
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
