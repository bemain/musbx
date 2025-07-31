import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/songs/analyzer/waveform_painter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/utils/loading.dart';

const int kSamplesPerPixel = 540;
const int kSampleRate = 48000;

class WaveformWidget extends StatelessWidget {
  WaveformWidget({super.key});

  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: player.analyzer.waveformNotifier,
      builder: (context, waveform, child) {
        return ValueListenableBuilder(
          valueListenable: player.analyzer.durationShownNotifier,
          builder: (context, durationShown, child) => ValueListenableBuilder(
            valueListenable: player.positionNotifier,
            builder: (context, position, child) {
              final Color color = Theme.of(context).colorScheme.primary;
              final PositionSliderStyle dummyStyle = PositionSliderStyle(
                activeLoopedTrackColor: color,
                inactiveLoopedTrackColor: color,
                disabledActiveLoopedTrackColor: color,
                disabledInactiveLoopedTrackColor: color,
                activeTrackColor: color,
                inactiveTrackColor: color,
                disabledActiveTrackColor: color,
                disabledInactiveTrackColor: color,
              );

              return ShimmerLoading(
                isLoading: waveform == null,
                child: CustomPaint(
                  painter: WaveformPainter(
                    waveform: waveform ?? _generateDummyWaveform(),
                    position: position,
                    duration: durationShown,
                    style: waveform != null
                        ? Theme.of(context).extension<PositionSliderStyle>()!
                        : dummyStyle,
                    markerColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  size: const Size(double.infinity, 64.0),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Generates a dummy waveform with pseudo-random data.
  /// This is used when the waveform is not yet available.
  ///
  /// It's length matches that of the current song.
  Waveform _generateDummyWaveform() {
    final int samplesPerPixel = kSamplesPerPixel;
    final int sampleRate = kSampleRate;

    final int length =
        (player.duration.inMicroseconds / (1e6 / sampleRate) / samplesPerPixel)
            .ceil();

    final data = <int>[];
    for (int i = 0; i < length; i++) {
      /// Pseudo-random value based on the index. Between 0 and 1.
      final seed = sin((i * 1.5 + pow(i, 2) * 0.1) / 100 - pi / 2) * 0.5 + 0.5;

      /// Scale to adjust for 16-bit audio.
      const min16bit = -32768;
      const max16bit = 32767;
      final value =
          ((seed * 0.6 + 0.1) * 32768).clamp(min16bit, max16bit).toInt();
      data.addAll([value, -value]); // One for each channel
    }

    return Waveform(
      version: 1,
      flags: 0,
      sampleRate: sampleRate,
      samplesPerPixel: samplesPerPixel,
      length: length,
      data: data,
    );
  }
}
