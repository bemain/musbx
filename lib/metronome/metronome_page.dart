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
import 'package:musbx/page/flat_card.dart';

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
    const EdgeInsets cardPadding =
        EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 8);

    return const Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: DefaultAppBar(),
      body: Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            Higher(),
            SizedBox(height: 8),
            Subdivisions(),
            SizedBox(height: 8),
            Expanded(
              child: FlatCard(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PlayButton(),
                    Padding(
                      padding: cardPadding,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: CountDisplay(),
                      ),
                    ),
                    Padding(
                      padding: cardPadding,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VolumeIndicator(),
                            NotificationIndicator(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
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
    );
  }
}
