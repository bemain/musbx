import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/utils/loading.dart';
import 'package:musbx/widgets/widgets.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling a [SongPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SongPlayer? player = Songs.player;

    final Color? disabledColor = player == null
        ? Theme.of(context).colorScheme.onSurface
        : null;

    return SizedBox(
      height: 64.0,
      child: ShimmerLoading(
        isLoading: player == null,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: player == null
                  ? null
                  : () {
                      player.seek(Duration.zero);
                    },
              disabledColor: disabledColor,
              icon: const ExpandedIcon(Symbols.skip_previous_rounded),
            ),

            ContinuousButton(
              onContinuousPress: player == null
                  ? null
                  : () {
                      player.seek(
                        player.position - const Duration(seconds: 1),
                      );
                    },
              child: IconButton(
                onPressed: player == null
                    ? null
                    : () {
                        player.seek(
                          player.position - const Duration(seconds: 1),
                        );
                      },
                disabledColor: disabledColor,
                icon: const ExpandedIcon(Symbols.fast_rewind_rounded),
              ),
            ),

            ValueListenableBuilder<bool>(
              valueListenable:
                  player?.isPlayingNotifier ?? ValueNotifier(false),
              builder: (_, isPlaying, _) {
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton.filled(
                      onPressed: player == null
                          ? null
                          : () {
                              if (isPlaying) {
                                player.pause();
                              } else {
                                player.resume();
                              }
                            },
                      disabledColor: disabledColor,
                      icon: ExpandedIcon(
                        isPlaying
                            ? Symbols.stop_rounded
                            : Symbols.play_arrow_rounded,
                        fill: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            ContinuousButton(
              onContinuousPress: player == null
                  ? null
                  : () {
                      player.seek(
                        player.position + const Duration(seconds: 1),
                      );
                    },
              child: IconButton(
                onPressed: player == null
                    ? null
                    : () {
                        player.seek(
                          player.position + const Duration(seconds: 1),
                        );
                      },
                disabledColor: disabledColor,
                icon: const ExpandedIcon(Symbols.fast_forward_rounded),
              ),
            ),

            // Placeholder, only there to take space so the play button is centered
            const IconButton(
              onPressed: null,
              icon: Icon(null),
            ),
          ],
        ),
      ),
    );
  }
}
