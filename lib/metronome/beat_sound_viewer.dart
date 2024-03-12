import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musbx/metronome/beat_sound.dart';
import 'package:musbx/metronome/metronome.dart';

class BeatSoundViewer extends StatefulWidget {
  /// Widget for displaying and editing the sounds played by the [Metronome] on
  /// each of the beats.
  ///
  /// Displays the beats as circles, using the color of the beat's [BeatSound].
  /// Clicking a circle changes the sound played on that beat.
  ///
  /// Pressing long on a circle removes that beats. Also offers a plus button
  /// for adding new beats.
  ///
  /// The beat that was most recently played ([Metronome.count]) is highlighted.
  const BeatSoundViewer({super.key});

  @override
  State<StatefulWidget> createState() => BeatSoundViewerState();
}

class BeatSoundViewerState extends State<BeatSoundViewer> {
  final Metronome metronome = Metronome.instance;

  @override
  void initState() {
    super.initState();

    // Listen for changes to:
    // - sounds: change number of circles
    // - count: change which circle is highlighted.
    metronome.beats.addListener(_listenForUpdates);
    metronome.countNotifier.addListener(_listenForUpdates);
  }

  @override
  void dispose() {
    metronome.beats.removeListener(_listenForUpdates);
    metronome.countNotifier.removeListener(_listenForUpdates);
    super.dispose();
  }

  void _listenForUpdates() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ..._buildBeatButtons(),
        if (metronome.higher < 8)
          Ink(
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.vibrate();
                metronome.beats.add(BeatSound.primary);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add_circle_outline_rounded),
              ),
            ),
          )
      ],
    );
  }

  List<Widget> _buildBeatButtons() {
    return metronome.beats
        .asMap()
        .map((int index, BeatSound sound) => MapEntry(
              index,
              Ink(
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // Change beat sound
                    var sound = metronome.beats[index];
                    metronome.beats[index] = BeatSound
                        .values[(sound.index + 1) % BeatSound.values.length];
                  },
                  onLongPress: () {
                    if (metronome.beats.length >= 2) {
                      metronome.beats.removeAt(index);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      (metronome.count == index)
                          ? Icons.circle
                          : Icons.circle_outlined, // Highlight current beat
                      color: beatSoundColor(context, sound),
                    ),
                  ),
                ),
              ),
            ))
        .values
        .toList();
  }
}
