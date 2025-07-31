import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/analyzer/analyzer_card.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/button_panel.dart';
import 'package:musbx/songs/song_page/position_slider.dart';
import 'package:musbx/songs/demixer/demixer_card.dart';
import 'package:musbx/songs/equalizer/equalizer_sheet.dart';
import 'package:musbx/songs/slowdowner/slowdowner_sheet.dart';
import 'package:musbx/utils/loading.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/segmented_tab_control/segment_tab.dart';
import 'package:musbx/widgets/segmented_tab_control/segmented_tab_control.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  static final String helpText =
      """- Play along with the chords or loop a section of the song in the Chords tab.
- Mute or isolate specific instruments in the Instruments tab.
- Adjust pitch and speed ${Platform.isAndroid ? "and apply equalizer effects " : ""}using the options in the toolbar.""";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Songs.playerNotifier,
      builder: (context, player, child) {
        return DefaultTabController(
          length: 2,
          initialIndex: 0,
          animationDuration: const Duration(milliseconds: 200),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: SongAppBar(),
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
                              title: player == null
                                  ? TextPlaceholder()
                                  : Text(player.song.title),
                              titleTextStyle:
                                  Theme.of(context).textTheme.titleLarge,
                              subtitle: player == null
                                  ? TextPlaceholder(width: 160)
                                  : Text(player.song.artist ?? ""),
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
                  const SizedBox(height: 12),
                  ShimmerLoading(
                    isLoading: player == null,
                    child: SegmentedTabControl(
                      enabled: player != null,
                      tabs: [
                        SegmentTab(
                          text: "Chords",
                          icon: Icon(CustomIcons.waveform),
                        ),
                        SegmentTab(
                          text: "Instruments",
                          icon: Icon(Symbols.piano),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PositionSlider(),
                  ButtonPanel(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SongAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SongAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (Songs.player == null) {
      return AppBar(
        actions: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: IconPlaceholder(),
            ),
          const GetPremiumButton(),
          InfoButton(child: Text(SongPage.helpText)),
        ],
      );
    }

    final SongPlayer player = Songs.player!;

    return ValueListenableBuilder(
      valueListenable: player.slowdowner.pitchNotifier,
      builder: (context, pitch, child) => ValueListenableBuilder(
        valueListenable: player.slowdowner.speedNotifier,
        builder: (context, speed, child) => ValueListenableBuilder(
          valueListenable: player.equalizer.bandsNotifier,
          builder: (context, bands, child) {
            final bool isPitchReset = pitch.toStringAsFixed(1) == "0.0";
            final bool isSpeedReset = speed.toStringAsFixed(2) == "1.00";
            final bool isEqualizerReset = bands.every((band) =>
                band.gain.toStringAsFixed(2) ==
                EqualizerBand.defaultGain.toStringAsFixed(2));
            return AppBar(
              actions: [
                IconButton(
                  onPressed: () {
                    _showModalBottomSheet(
                      context,
                      SlowdownerSheet(),
                    );
                  },
                  isSelected: !isPitchReset,
                  color: isPitchReset
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  icon: const Icon(CustomIcons.accidentals),
                ),
                IconButton(
                  onPressed: () {
                    _showModalBottomSheet(
                      context,
                      SlowdownerSheet(),
                    );
                  },
                  isSelected: !isSpeedReset,
                  color: isSpeedReset
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  icon: const Icon(Symbols.avg_pace),
                ),
                IconButton(
                  onPressed: () {
                    _showModalBottomSheet(
                      context,
                      const EqualizerSheet(),
                    );
                  },
                  isSelected: !isEqualizerReset,
                  color: isEqualizerReset
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  icon: const Icon(Symbols.instant_mix),
                ),
                const GetPremiumButton(),
                InfoButton(child: Text(SongPage.helpText)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<T?> _showModalBottomSheet<T>(BuildContext context, Widget? child) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
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
