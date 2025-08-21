import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
        final bool isMuted = metronome.player.volume == 0.0;

        return IconButton(
          onPressed: () async {
            await metronome.player.setVolume(isMuted ? 1.0 : 0.0);
            setState(() {});
          },
          isSelected: isMuted,
          icon: const Icon(Symbols.volume_up),
          selectedIcon: const Icon(Symbols.vibration),
        );
      },
    );
  }
}
