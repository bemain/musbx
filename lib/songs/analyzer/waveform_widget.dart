import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/songs/analyzer/waveform_card.dart';
import 'package:musbx/songs/analyzer/waveform_painter.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/result_builder.dart';

const int kSamplesPerPixel = 540;
const int kSampleRate = 48000;

class WaveformWidget extends StatefulWidget {
  const WaveformWidget({super.key, required this.durationShown});

  final Duration durationShown;

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  final PlaybackRepository playback = PlaybackRepository.instance;

  Future<Result<Waveform>>? _future;

  void _updateFuture() {
    if (playback.song == null) return;
    _future = AnalysisRepository.instance.waveform(playback.song!);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return ShimmerLoading(
      child: CustomPaint(
        painter: WaveformPainter(
          waveform: _generateDummyWaveform(
            playback.duration ?? WaveformCard.defaultDurationShown,
          ),
          position: playback.position,
          duration: widget.durationShown,
          style: PositionSliderStyle(
            activeTrackColor: color,
            inactiveTrackColor: color,
            disabledActiveTrackColor: color,
            disabledInactiveTrackColor: color,
            nonLoopedTrackColor: color,
            disabledNonLoopedTrackColor: color,
          ),
          markerColor: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
        ),
        size: const Size(double.infinity, 64.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (playback.song == null) return _buildPlaceholder(context);
    if (_future == null) _updateFuture();

    return ResultBuilder(
      future: _future!,
      loading: _buildPlaceholder,
      failure: (c, e) => _buildPlaceholder(c),
      ok: (context, waveform) {
        return ValueListenableBuilder(
          valueListenable: playback.positionNotifier,
          builder: (context, position, child) {
            return CustomPaint(
              painter: WaveformPainter(
                waveform: waveform,
                position: position,
                duration: widget.durationShown,
                style: Theme.of(context).extension<PositionSliderStyle>()!,
                markerColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
              ),
              size: const Size(double.infinity, 64.0),
            );
          },
        );
      },
    );
  }

  /// Generates a dummy waveform with pseudo-random data.
  /// This is used when the waveform is not yet available.
  ///
  /// It's length matches that of the current song.
  Waveform _generateDummyWaveform(Duration duration) {
    final int samplesPerPixel = kSamplesPerPixel;
    final int sampleRate = kSampleRate;

    final int length =
        (duration.inMicroseconds / (1e6 / sampleRate) / samplesPerPixel)
            .ceil();

    final data = <int>[];
    for (int i = 0; i < length; i++) {
      /// Pseudo-random value based on the index. Between 0 and 1.
      final seed = sin((i * 1.5 + pow(i, 2) * 0.1) / 100 - pi / 2) * 0.5 + 0.5;

      /// Scale to adjust for 16-bit audio.
      const min16bit = -32768;
      const max16bit = 32767;
      final value = ((seed * 0.6 + 0.1) * 32768)
          .clamp(min16bit, max16bit)
          .toInt();
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
