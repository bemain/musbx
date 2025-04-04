import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/widgets.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [MusicPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SongPlayer? player = Songs.player;

    if (player == null) {
      // TODO: Create loading
      return const SizedBox();
    }

    return SizedBox(
      height: 64.0,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              player.seek(Duration.zero);
            },
            icon: const ExpandedIcon(Symbols.skip_previous_rounded),
          ),

          ContinuousButton(
            onContinuousPress: () {
              player.seek(player.position - const Duration(seconds: 1));
            },
            child: IconButton(
              onPressed: () {
                player.seek(player.position - const Duration(seconds: 1));
              },
              icon: const ExpandedIcon(Symbols.fast_rewind_rounded),
            ),
          ),

          ValueListenableBuilder<bool>(
            valueListenable: player.isPlayingNotifier,
            builder: (_, isPlaying, __) {
              return AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // if (player.isLoading)
                    //   const Positioned.fill(
                    //     child: CircularProgressIndicator(),
                    //   ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: IconButton.filled(
                        onPressed: () {
                          if (isPlaying) {
                            player.pause();
                          } else {
                            player.resume();
                          }
                        },
                        icon: ExpandedIcon(
                          isPlaying
                              ? Symbols.stop_rounded
                              : Symbols.play_arrow_rounded,
                          fill: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          ContinuousButton(
            onContinuousPress: () {
              player.seek(player.position + const Duration(seconds: 1));
            },
            child: IconButton(
              onPressed: () {
                player.seek(player.position + const Duration(seconds: 1));
              },
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
    );
  }
}
