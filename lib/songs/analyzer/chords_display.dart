import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/songs/analyzer/chord_symbol.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/result_builder.dart';
import 'package:provider/provider.dart';

class ChordsDisplay extends StatefulWidget {
  const ChordsDisplay({super.key, required this.durationShown});

  final Duration durationShown;

  @override
  State<ChordsDisplay> createState() => _ChordsDisplayState();
}

class _ChordsDisplayState extends State<ChordsDisplay> {
  PlaybackRepository get playback => context.read();

  Future<Result<Map<Duration, Chord?>>>? _future;
  void _updateFuture() {
    if (playback.song == null) return;
    _future = context.read<AnalysisRepository>().chords(playback.song!);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: TextPlaceholder(
        fontSize: 20.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playback,
      builder: (context, child) {
        if (playback.song == null) return _buildPlaceholder(context);

        if (_future == null) _updateFuture();

        return SizedBox(
          height: 24.0,
          child: LayoutBuilder(
            builder: (context, constraints) => ResultBuilder(
              future: _future!,
              loading: _buildPlaceholder,
              failure: (c, e) => _buildPlaceholder(c),
              ok: (context, chords) {
                return ValueListenableBuilder(
                  valueListenable: playback.positionNotifier,
                  builder: (context, position, child) {
                    Duration minDuration =
                        position - widget.durationShown * 0.5;
                    Duration maxDuration =
                        position + widget.durationShown * 0.5;
                    List<MapEntry<Duration, Chord?>> shownChords = chords
                        .entries
                        .where(
                          (e) => e.key > minDuration && e.key < maxDuration,
                        )
                        .toList();

                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ...shownChords.map((e) {
                          final Chord? chord = e.value;
                          return Positioned(
                            left:
                                ((e.key - position).inMilliseconds /
                                        (widget.durationShown.inMilliseconds) +
                                    0.5) *
                                constraints.maxWidth,
                            child: chord == null
                                ? const SizedBox()
                                : ChordSymbol(
                                    chord: chord,
                                    color: e.key <= position
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
