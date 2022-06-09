import 'package:flutter/material.dart';
import 'package:musbx/metronome/beat_sounds.dart';
import 'package:musbx/metronome/metronome.dart';

class BeatSoundViewer extends StatefulWidget {
  /// Widget for displaying and editing the sounds played by the [Metronome] on
  /// each of the beats.
  ///
  /// Displays the beats as circles, using the color of the beat's [SoundType].
  /// Clicking a circle changes the sound played on that beat.
  ///
  /// The beat that was most recently played ([Metronome.count]) is highlighted.
  const BeatSoundViewer({super.key});

  @override
  State<StatefulWidget> createState() => BeatSoundViewerState();
}

class BeatSoundViewerState extends State<BeatSoundViewer> {
  @override
  void initState() {
    super.initState();

    // Listen for changes to:
    // - sounds: change number of circles
    // - count: change which circle is highlighted.
    Metronome.beatSounds.addListener(() => setState(() {}));
    Metronome.countNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: Metronome.beatSounds.sounds
            .asMap()
            .map((int index, SoundType sound) => MapEntry(
                  index,
                  IconButton(
                    onPressed: () {
                      // Change beat sound
                      var sound = Metronome.beatSounds[index];
                      Metronome.beatSounds[index] = SoundType
                          .values[(sound.index + 1) % SoundType.values.length];
                    },
                    icon: Icon(
                      Icons.circle,
                      color: sound.color,
                      shadows: (Metronome.count == index)
                          ? [const Shadow(blurRadius: 10)]
                          : [], // Highlight current beat
                    ),
                  ),
                ))
            .values
            .toList(),
      ),
    );
  }
}
