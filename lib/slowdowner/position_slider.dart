import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

/// Slider for seeking a position on [Slowdowner.audioPlayer].
/// Also displays current position and duration of current song.
class PositionSlider extends StatefulWidget {
  const PositionSlider({super.key});

  @override
  State<StatefulWidget> createState() => PositionSliderState();
}

class PositionSliderState extends State<PositionSlider> {
  final Slowdowner slowdowner = Slowdowner.instance;

  Duration get position => _position;
  set position(Duration value) {
    _position = value;

    if (_position.isNegative) _position = Duration.zero; // Clamp lower
    // Clamp higher
    if (_position > (slowdowner.duration ?? const Duration(seconds: 1))) {
      _position = slowdowner.duration ?? const Duration(seconds: 1);
    }
  }

  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // When a new song is loaded, rebuild
    slowdowner.durationStream.listen((duration) {
      setState(() {
        if (duration != null && position > duration) {
          position = duration;
        }
      });
    });

    // When position changes, update it locally
    slowdowner.positionStream.listen((position) {
      setState(() {
        this.position = position;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _buildDurationText(position),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: slowdowner.duration?.inSeconds.roundToDouble() ?? 1,
            value: position.inSeconds.roundToDouble(),
            onChanged: (double value) {
              setState(() {
                position = Duration(seconds: value.round());
              });
            },
            onChangeEnd: (double value) {
              slowdowner.seek(position);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _buildDurationText(slowdowner.duration ?? Duration.zero),
        )
      ],
    );
  }

  Widget _buildDurationText(Duration duration) {
    return Text(
      RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
              .firstMatch("$duration")
              ?.group(1) ??
          "$duration",
      style: Theme.of(context).textTheme.caption,
    );
  }
}
