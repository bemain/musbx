import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/analyzer/waveform_card.dart';
import 'package:musbx/songs/demixer/demixer_card.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/equalizer/equalizer_sheet.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/slowdowner/slowdowner_sliders.dart';
import 'package:musbx/songs/song_page/button_panel.dart';
import 'package:musbx/songs/song_page/position_slider.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/flat_card.dart';

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
                            FlatCard(
                              radius: BorderRadius.vertical(
                                top: Radius.circular(32),
                                bottom: Radius.circular(4),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PitchSlider(),
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: PitchSpeedResetButton(),
                                    ),
                                    SpeedSlider(),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: WaveformCard(
                                radius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                  bottom: Radius.circular(32),
                                ),
                              ),
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
        title: ListTile(
          title: TextPlaceholder(),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: TextPlaceholder(width: 160),
          ),
        ),
        actions: [
          IconPlaceholder(),
          const GetPremiumButton(),
          SettingsButton(),
        ],
      );
    }

    final SongPlayer player = Songs.player!;

    return ListenableBuilder(
      listenable: player.equalizer,
      builder: (context, child) {
        final bool isEqualizerReset = player.equalizer.bands.every(
          (band) =>
              band.gain.toStringAsFixed(2) ==
              EqualizerBand.defaultGain.toStringAsFixed(2),
        );
        return AppBar(
          title: ListTile(
            title: Text(
              player.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(player.song.artist ?? "Unknown artist"),
          ),
          titleSpacing: 0,
          actions: [
            IconButton(
              onPressed: () {
                showAlertSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => EqualizerSheet(),
                );
              },
              isSelected: !isEqualizerReset,
              color: isEqualizerReset
                  ? null
                  : Theme.of(context).colorScheme.primary,
              icon: const Icon(Symbols.instant_mix),
            ),
            const GetPremiumButton(),
            const SettingsButton(),
          ],
        );
      },
    );
  }
}
