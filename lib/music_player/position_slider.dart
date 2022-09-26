import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class PositionSlider extends StatefulWidget {
  /// Slider for seeking a position in the song played by [MusicPlayer].
  /// Also displays current position and duration of current song.
  const PositionSlider({super.key});

  @override
  State<StatefulWidget> createState() => PositionSliderState();
}

class PositionSliderState extends State<PositionSlider> {
  final MusicPlayer musicPlayer = MusicPlayer.instance;

  Duration _position = Duration.zero;

  /// The position used internally to avoid updating [MusicPlayer]'s
  /// position too often.
  Duration get position => _position;
  set position(Duration value) {
    _position = value;

    if (_position.isNegative) _position = Duration.zero; // Clamp lower
    // Clamp higher
    if (_position > (musicPlayer.durationNotifier.value ?? Duration.zero)) {
      _position = musicPlayer.durationNotifier.value ?? Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();

    // When a new song is loaded, rebuild
    musicPlayer.durationNotifier.addListener(() {
      setState(() {
        position = Duration.zero;
      });
    });

    // When position changes, update it locally
    musicPlayer.positionNotifier.addListener(() {
      setState(() {
        position = musicPlayer.positionNotifier.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.songTitleNotifier,
      builder: (context, songTitle, child) {
        return Row(
          children: [
            _buildDurationText(position),
            Expanded(
              child: Slider(
                min: 0,
                max: musicPlayer.durationNotifier.value?.inSeconds
                        .roundToDouble() ??
                    1,
                value: position.inSeconds.roundToDouble(),
                onChanged: (songTitle == null)
                    ? null
                    : (double value) {
                        setState(() {
                          position = Duration(seconds: value.round());
                        });
                      },
                onChangeEnd: (double value) {
                  musicPlayer.seek(position);
                },
              ),
            ),
            _buildDurationText(musicPlayer.durationNotifier.value),
          ],
        );
      },
    );
  }

  Widget _buildDurationText(Duration? duration) {
    return Text(
      (duration == null)
          ? "-- : --"
          : RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                  .firstMatch("$duration")
                  ?.group(1) ??
              "$duration",
      style: Theme.of(context).textTheme.caption,
    );
  }
}
