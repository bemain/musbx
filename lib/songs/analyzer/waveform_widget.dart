import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/waveform_painter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';

class WaveformWidget extends StatelessWidget {
  WaveformWidget({super.key});

  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: player.analyzer.waveformNotifier,
      builder: (context, waveform, child) {
        if (waveform == null) {
          // TODO: Show dummy waveform.
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("Analyzing..."),
            ],
          );
        }

        return ValueListenableBuilder(
          valueListenable: player.analyzer.durationShownNotifier,
          builder: (context, durationShown, child) => ValueListenableBuilder(
            valueListenable: player.positionNotifier,
            builder: (context, position, child) {
              return CustomPaint(
                painter: WaveformPainter(
                  waveform: waveform,
                  position: player.position,
                  duration: durationShown,
                  style: Theme.of(context).extension<PositionSliderStyle>()!,
                  markerColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                size: const Size(double.infinity, 64.0),
              );
            },
          ),
        );
      },
    );
  }
}
