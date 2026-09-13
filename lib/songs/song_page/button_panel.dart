import 'package:flutter/material.dart';
import 'package:flutter_m3shapes/flutter_m3shapes.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:provider/provider.dart';

/// Panel including play/pause, forward and rewind buttons for controlling
/// playback.
///
/// If no song is loaded, all buttons are disabled.
class ButtonPanel extends StatefulWidget {
  const ButtonPanel({super.key});

  @override
  State<ButtonPanel> createState() => _ButtonPanelState();
}

class _ButtonPanelState extends State<ButtonPanel> {
  PlaybackRepository get playback => context.read();

  Widget _buildButton({
    required void Function()? onPressed,
    required Widget icon,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: IconButton(
        onPressed: playback.song == null || onPressed == null
            ? null
            : () => onPressed(),
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? disabledColor = playback.song == null
        ? Theme.of(context).colorScheme.onSurface
        : null;

    return SizedBox(
      height: 64.0,
      child: ShimmerLoading(
        isLoading: playback.song == null,
        child: ButtonTheme(
          disabledColor: disabledColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildButton(
                onPressed: () {
                  playback.seek(Duration.zero);
                },
                icon: const Icon(Symbols.skip_previous),
              ),

              ContinuousButton(
                interval: Duration(milliseconds: 10),
                onContinuousPress: playback.song == null
                    ? null
                    : () {
                        playback.seek(
                          playback.position -
                              const Duration(milliseconds: 100),
                        );
                      },
                child: _buildButton(
                  onPressed: () {
                    playback.seek(
                      playback.position - const Duration(seconds: 5),
                    );
                  },
                  icon: const Icon(Symbols.replay_5),
                ),
              ),

              ValueListenableBuilder<bool>(
                valueListenable: playback.isPlayingNotifier,
                builder: (_, isPlaying, _) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: M3Container.c6SidedCookie(
                        child: Material(
                          color: playback.song == null
                              ? Theme.of(context).colorScheme.surfaceContainer
                              : Theme.of(context).colorScheme.primary,
                          child: InkWell(
                            onTap: playback.song == null
                                ? null
                                : () {
                                    if (isPlaying) {
                                      playback.pause();
                                    } else {
                                      playback.resume();
                                    }
                                  },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Icon(
                                isPlaying ? Symbols.stop : Symbols.play_arrow,
                                fill: 1,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              ContinuousButton(
                interval: Duration(milliseconds: 10),
                onContinuousPress: playback.song == null
                    ? null
                    : () {
                        playback.seek(
                          playback.position +
                              const Duration(milliseconds: 100),
                        );
                      },
                child: _buildButton(
                  onPressed: () {
                    playback.seek(
                      playback.position + const Duration(seconds: 10),
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
