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
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: 2,
          child: TextButton(
            onPressed: musicPlayer.nullIfNoSongElse(() {
              musicPlayer.seek(Duration.zero);
            }),
            child: expandedIcon(Icons.skip_previous_rounded),
          ),
        ),
        Flexible(
          flex: 2,
          child: ContinuousTextButton(
            onPressed: musicPlayer.nullIfNoSongElse(() {
              musicPlayer
                  .seek(musicPlayer.position - const Duration(seconds: 1));
            }),
            child: expandedIcon(Icons.fast_rewind_rounded),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: 3,
          child: ValueListenableBuilder<bool>(
            valueListenable: musicPlayer.isPlayingNotifier,
            builder: (_, isPlaying, __) => ValueListenableBuilder<bool>(
              valueListenable: musicPlayer.isBufferingNotifier,
              builder: (context, isBuffering, _) {
                return TextButton(
                  onPressed: musicPlayer.nullIfNoSongElse(() {
                    if (isPlaying) {
                      musicPlayer.pause();
                    } else {
                      musicPlayer.play();
                    }
                  }),
                  child: (musicPlayer.isLoading || isBuffering)
                      ? LayoutBuilder(
                          builder: (context, constraint) => SizedBox.square(
                            dimension: constraint.biggest.width,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : expandedIcon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                        ),
                );
              },
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: ContinuousTextButton(
            onPressed: musicPlayer.nullIfNoSongElse(() {
              musicPlayer
                  .seek(musicPlayer.position + const Duration(seconds: 1));
            }),
            child: expandedIcon(Icons.fast_forward_rounded),
          ),
        ),
        // Placeholder, only there to take space so the play button is centered
        Flexible(
          flex: 2,
          child: TextButton(onPressed: null, child: expandedIcon(null)),
        ),
      ],
    );
  }

  /// Makes [icon] fill the available space.
  Widget expandedIcon(IconData? icon) {
    return LayoutBuilder(
      builder: (context, constraint) => Icon(
        icon,
        size: constraint.biggest.width,
      ),
    );
  }
}
