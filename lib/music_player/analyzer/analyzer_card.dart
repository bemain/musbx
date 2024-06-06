import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/chords_display.dart';
import 'package:musbx/music_player/analyzer/waveform_widget.dart';
import 'package:musbx/music_player/music_player.dart';

class AnalyzerCard extends StatelessWidget {
  AnalyzerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ChordsDisplay(),
          Expanded(child: WaveformWidget()),
        ],
      ),
    );
  }
}
