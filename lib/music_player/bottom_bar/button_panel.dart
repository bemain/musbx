import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [MusicPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  ButtonPanel({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            flex: 1,
            child: TextButton(
              onPressed: musicPlayer.nullIfNoSongElse(() {
                musicPlayer.seek(Duration.zero);
              }),
              child: const ExpandedIcon(Icons.skip_previous_rounded),
            ),
          ),
          Flexible(
            flex: 1,
            child: ContinuousButton(
              onContinuousPress: musicPlayer.nullIfNoSongElse(() {
                musicPlayer
                    .seek(musicPlayer.position - const Duration(seconds: 1));
              }),
              child: TextButton(
                onPressed: musicPlayer.nullIfNoSongElse(() {
                  musicPlayer
                      .seek(musicPlayer.position - const Duration(seconds: 1));
                }),
                child: const ExpandedIcon(Icons.fast_rewind_rounded),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: ValueListenableBuilder<bool>(
              valueListenable: musicPlayer.isPlayingNotifier,
              builder: (_, isPlaying, __) => ValueListenableBuilder<bool>(
                valueListenable: musicPlayer.isBufferingNotifier,
                builder: (context, isBuffering, _) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (musicPlayer.isLoading || isBuffering)
                          const Positioned.fill(
                            child: CircularProgressIndicator(),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: IconButton.filled(
                            onPressed: musicPlayer.nullIfNoSongElse(() {
                              if (isPlaying) {
                                musicPlayer.pause();
                              } else {
                                musicPlayer.play();
                              }
                            }),
                            icon: ExpandedIcon(
                              isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: ContinuousButton(
              onContinuousPress: musicPlayer.nullIfNoSongElse(() {
                musicPlayer
                    .seek(musicPlayer.position + const Duration(seconds: 1));
              }),
              child: TextButton(
                onPressed: musicPlayer.nullIfNoSongElse(() {
                  musicPlayer
                      .seek(musicPlayer.position + const Duration(seconds: 1));
                }),
                child: const ExpandedIcon(Icons.fast_forward_rounded),
              ),
            ),
          ),
          // Placeholder, only there to take space so the play button is centered
          Flexible(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }
}
