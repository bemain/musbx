import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/position_slider.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class SlowdownerScreen extends StatefulWidget {
  const SlowdownerScreen({super.key});

  @override
  State<StatefulWidget> createState() => SlowdownerScreenState();
}

class SlowdownerScreenState extends State<SlowdownerScreen> {
  @override
  void initState() {
    super.initState();

    Slowdowner.audioPlayer.setAsset("assets/youve_got.mp3");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PositionSlider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Slowdowner.audioPlayer.seek(Slowdowner.audioPlayer.position -
                    const Duration(seconds: 1));
              },
              onLongPress: () {
                setState(() {
                  Slowdowner.audioPlayer.seek(Duration.zero);
                });
              },
              child: const Icon(Icons.fast_rewind_rounded, size: 40),
            ),
            buildPlayButton(),
            TextButton(
              onPressed: () {
                Slowdowner.audioPlayer.seek(Slowdowner.audioPlayer.position +
                    const Duration(seconds: 1));
              },
              child: const Icon(Icons.fast_forward_rounded, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPlayButton() {
    return StreamBuilder<bool>(
      stream: Slowdowner.audioPlayer.playingStream,
      initialData: false,
      builder: (context, snapshot) {
        bool isPlaying = snapshot.data!;
        return TextButton(
          onPressed: (() {
            if (isPlaying) {
              Slowdowner.audioPlayer.pause();
            } else {
              Slowdowner.audioPlayer.play();
            }
          }),
          child: Icon(
            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 75,
          ),
        );
      },
    );
  }
}
