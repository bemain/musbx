import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class PitchSpeedCard extends StatelessWidget {
  PitchSpeedCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: Align(
          alignment: Alignment.topRight,
          child: buildResetButton(),
        ),
      ),
      ValueListenableBuilder(
        valueListenable: musicPlayer.songTitleNotifier,
        builder: (context, songTitle, _) => Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Pitch",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            buildPitchSlider(),
            Text(
              "Speed",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            buildSpeedSlider(),
          ],
        ),
      ),
    ]);
  }

  Widget buildPitchSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.pitchSemitonesNotifier,
      builder: (context, pitch, _) => Row(children: [
        SizedBox(
          width: 20,
          child: Text(
            "-9",
            style: Theme.of(context).textTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
        Expanded(
          child: Slider(
            value: pitch,
            min: -9,
            max: 9,
            divisions: 18,
            label: ((pitch > 0) ? "+" : "") + pitch.toStringAsFixed(0),
            onChanged: musicPlayer.nullIfNoSongElse(
              musicPlayer.setPitchSemitones,
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            "+9",
            style: Theme.of(context).textTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ]),
    );
  }

  Widget buildSpeedSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.speedNotifier,
      builder: (context, speed, _) => Row(children: [
        SizedBox(
          width: 20,
          child: Text(
            "0.1",
            style: Theme.of(context).textTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
        Expanded(
          child: Slider(
            value: speed,
            min: 0.1,
            max: 1.9,
            divisions: 18,
            label: speed.toStringAsFixed(1),
            onChanged: musicPlayer.nullIfNoSongElse(
              musicPlayer.setSpeed,
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: Text(
            "1.9",
            style: Theme.of(context).textTheme.caption,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ]),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.speedNotifier,
      builder: (_, speed, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.pitchSemitonesNotifier,
        builder: (context, pitch, _) => IconButton(
          iconSize: 20,
          onPressed: (speed.toStringAsFixed(2) == "1.00" && pitch == 0)
              ? null
              : () {
                  musicPlayer.setSpeed(1.0);
                  musicPlayer.setPitchSemitones(0);
                },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}
