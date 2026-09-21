import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/play_song.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/songs/analyzer/waveform_card.dart';
import 'package:musbx/songs/demixer/demixer_card.dart';
import 'package:musbx/songs/equalizer/equalizer_sheet.dart';

import 'package:musbx/songs/slowdowner/slowdowner_sliders.dart';
import 'package:musbx/songs/song_page/button_panel.dart';
import 'package:musbx/songs/song_page/position_slider.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:provider/provider.dart';

/// The player for one song: the position slider and transport controls, above
/// two tabs holding the stem controls and the waveform, chords, pitch and
/// speed.
///
/// Loads [song] when first shown, and shimmers until it has finished loading.
/// If loading fails, shows a dialog and returns to the library.
class SongPage extends StatefulWidget {
  const SongPage({super.key, required this.song});

  static const Duration loadTimeout = Duration(seconds: 30);

  final Song song;

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  late final Future<Result<void>> _loading;

  @override
  void initState() {
    super.initState();
    final PlaySong playSong = context.read();
    // Deferred so that the notifications emitted by unloading the previous
    // song do not fire during the build phase.
    _loading = Future.microtask(() => playSong.call(widget.song)).timeout(
      SongPage.loadTimeout,
      onTimeout: () => Result.failed(
        TimeoutException("Loading the song took too long"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loading,
      builder: (context, snapshot) {
        Widget fail(Object error, Widget dialog) {
          debugPrint("[Navigation] $error");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showExceptionDialog(dialog);
            context.go(Routes.library);
          });
          return const SizedBox();
        }

        return switch (snapshot.data) {
          null || Ok() => const _SongPlayer(),
          AccessRestricted(:final error) => fail(
            error,
            const MusicPlayerAccessRestrictedDialog(),
          ),
          Failure(:final error) => fail(
            error,
            SongCouldNotBeLoadedDialog(error: error),
          ),
        };
      },
    );
  }
}

/// The player UI, shimmering while [PlaybackRepository.song] is `null`.
class _SongPlayer extends StatelessWidget {
  const _SongPlayer();

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    return ListenableBuilder(
      listenable: playback,
      builder: (context, child) {
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
                  if (playback.song == null)
                    // Loading
                    Expanded(
                      child: ShimmerLoading(
                        child: FlatCard(
                          child: SizedBox.expand(),
                        ),
                      ),
                    )
                  else
                    // Card tabs
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          DemixerCard(),

                          Column(
                            children: [
                              SizedBox(height: 4),
                              Expanded(
                                child: WaveformCard(
                                  radius: BorderRadius.vertical(
                                    top: Radius.circular(32),
                                    bottom: Radius.circular(4),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2),
                              FlatCard(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                radius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                  bottom: Radius.circular(32),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              SizedBox(height: 4),
                            ],
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

/// The title and artwork of the loaded song, above the tab bar.
class SongAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SongAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(
    kToolbarHeight + kTextTabBarHeight,
  );

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    if (playback.song == null) {
      return AppBar(
        titleSpacing: 0,
        title: ListTile(
          title: TextPlaceholder(),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: TextPlaceholder(width: 160),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(12),
            child: IconPlaceholder(),
          ),
          const GetPremiumButton(),
          const SettingsButton(),
        ],
        bottom: TabBar(
          tabs: [
            for (int i = 0; i < 2; i++)
              Tab(
                child: TextPlaceholder(width: 128),
              ),
          ],
        ),
      );
    }

    final numBands = playback.numEqualizerBands;
    final bool isEqualizerReset = numBands == null
        ? true
        : [for (int i = 0; i < numBands; i++) playback.getBandGain(i)].every(
            (gain) =>
                gain?.toStringAsFixed(2) ==
                PlaybackRepository.equalizerDefaultGain.toStringAsFixed(2),
          );
    return AppBar(
      titleSpacing: 0,
      title: ListTile(
        title: Text(
          playback.song!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(playback.song!.artist ?? "Unknown artist"),
      ),
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
      bottom: TabBar(
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Symbols.piano),
                Text("Instruments"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Symbols.tune),
                Text("Playback"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
