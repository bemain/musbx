import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling a [SongPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  const ButtonPanel({super.key});

  Widget _buildButton({
    required void Function(SongPlayer player)? onPressed,
    required Widget icon,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: IconButton(
        onPressed: Songs.player == null || onPressed == null
            ? null
            : () => onPressed(Songs.player!),
        icon: icon,
      ),
    );
  }

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
        child: ButtonTheme(
          disabledColor: disabledColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildButton(
                onPressed: (player) {
                  player.seek(Duration.zero);
                },
                icon: const Icon(Symbols.skip_previous),
              ),

              ContinuousButton(
                interval: Duration(milliseconds: 10),
                onContinuousPress: player == null
                    ? null
                    : () {
                        player.seek(
                          player.position - const Duration(milliseconds: 100),
                        );
                      },
                child: _buildButton(
                  onPressed: (player) {
                    player.seek(
                      player.position - const Duration(seconds: 5),
                    );
                  },
                  icon: const Icon(Symbols.replay_5),
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
                        icon: Icon(
                          isPlaying ? Symbols.stop : Symbols.play_arrow,
                          fill: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),

              ContinuousButton(
                interval: Duration(milliseconds: 10),
                onContinuousPress: player == null
                    ? null
                    : () {
                        player.seek(
                          player.position + const Duration(milliseconds: 100),
                        );
                      },
                child: _buildButton(
                  onPressed: (player) {
                    player.seek(
                      player.position + const Duration(seconds: 10),
                    );
                  },
                  icon: const Icon(Symbols.forward_10),
                ),
              ),

              // Placeholder, only there to take space so the play button is centered
              _buildButton(
                onPressed: null,
                icon: Icon(null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
