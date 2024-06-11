import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class VolumeIndicator extends StatefulWidget {
  const VolumeIndicator({super.key});

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator> {
  final Metronome metronome = Metronome.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: metronome.player.volumeStream,
      builder: (context, snapshot) {
        final isMuted = metronome.player.volume == 0.0;

        return IconButton(
          onPressed: () async {
            metronome.player.setVolume(isMuted ? 1.0 : 0.0);
            setState(() {});
          },
          color: Theme.of(context).colorScheme.onBackground,
          isSelected: isMuted,
          icon: const Icon(Icons.volume_up),
          selectedIcon: const Icon(Icons.vibration),
        );
      },
    );
  }
}
