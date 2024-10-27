import 'package:animated_segmented_tab_control/animated_segmented_tab_control.dart';
import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/analyzer_card.dart';
import 'package:musbx/songs/song_page/button_panel.dart';
import 'package:musbx/songs/song_page/position_slider.dart';
import 'package:musbx/songs/demixer/demixer_card.dart';
import 'package:musbx/songs/equalizer/equalizer_sheet.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/slowdowner/slowdowner_sheet.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/utils/purchases.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  static const String helpText =
      """Press the plus-button and load a song from your device or by searching.

- Mute or isolate specific instruments using the Demixer.
- Loop a section of the song using the range slider. Use the arrows to set the start or end of the section to the current position.
- Adjust pitch and speed using the circular sliders. Greater accuracy can be obtained by dragging away from the center.""";

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            musicPlayer.stateNotifier.value = MusicPlayerState.idle;
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showModalBottomSheet(
                context,
                SlowdownerSheet(),
              );
            },
            icon: const Icon(Icons.height), // TODO: Make a better icon
          ),
          IconButton(
            onPressed: () {
              _showModalBottomSheet(
                context,
                EqualizerSheet(),
              );
            },
            icon: const Icon(Icons.equalizer),
          ),
          if (!Purchases.hasPremium)
            IconButton(
              onPressed: () {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => const FreeAccessRestrictedDialog(),
                );
              },
              icon: const Icon(Icons.workspace_premium),
            ),
          const InfoButton(child: Text(helpText)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Column(
                    children: [
                      ListTile(
                        title: Text(musicPlayer.song?.title ?? ""),
                        titleTextStyle: Theme.of(context).textTheme.titleLarge,
                        subtitle: Text(musicPlayer.song?.artist ?? ""),
                      ),
                      Expanded(
                        child: AnalyzerCard(),
                      ),
                    ],
                  ),
                  DemixerCard(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentedTabControl(
              barDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(32),
              ),
              tabTextColor: Theme.of(context).colorScheme.onSurface,
              indicatorDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              selectedTabTextColor:
                  Theme.of(context).colorScheme.onPrimaryContainer,
              tabs: const [
                SegmentTab(label: "Chords"),
                SegmentTab(label: "Instruments"),
              ],
            ),
            const SizedBox(height: 16),
            PositionSlider(),
            ButtonPanel(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<T?> _showModalBottomSheet<T>(BuildContext context, Widget? child) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // TODO: Remove when this is in the framework https://github.com/flutter/flutter/issues/118619
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        );
      },
    );
  }
}
