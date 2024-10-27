import 'package:animated_segmented_tab_control/animated_segmented_tab_control.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/analyzer_card.dart';
import 'package:musbx/music_player/demixer/demixer_card.dart';
import 'package:musbx/music_player/equalizer/equalizer_sheet.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pick_song_button/components/search_youtube_button.dart';
import 'package:musbx/music_player/pick_song_button/components/upload_file_button.dart';
import 'package:musbx/music_player/bottom_bar/button_panel.dart';
import 'package:musbx/music_player/bottom_bar/position_slider.dart';
import 'package:musbx/music_player/slowdowner/slowdowner_sheet.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';
import 'package:musbx/page/default_app_bar.dart';
import 'package:musbx/purchases.dart';
import 'package:musbx/widgets.dart';

class MusicPlayerPage extends StatefulWidget {
  /// Page that allows the user to select and play a song.
  ///
  /// Includes:
  ///  - Label showing current song, and button to load a song from device.
  ///  - Buttons to play/pause, forward and rewind.
  ///  - Slider for seeking a position in the song.
  ///  - Sliders for changing pitch and speed of the song.
  ///  - Slider and buttons for looping a section of the song.
  ///  - Controls for the Demixer.
  ///  - Controls for the Equalizer.
  const MusicPlayerPage({super.key});

  @override
  State<StatefulWidget> createState() => MusicPlayerPageState();
}

class MusicPlayerPageState extends State<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin {
  static const String helpText =
      """Press the plus-button and load a song from your device or by searching.

- Mute or isolate specific instruments using the Demixer.
- Loop a section of the song using the range slider. Use the arrows to set the start or end of the section to the current position.
- Adjust pitch and speed using the circular sliders. Greater accuracy can be obtained by dragging away from the center.""";

  @override
  bool get wantKeepAlive => true;

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  Size? bottomBarSize;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
      valueListenable: musicPlayer.stateNotifier,
      builder: (context, state, _) {
        switch (state) {
          case MusicPlayerState.idle:
            return _buildLibraryPage(context);

          case MusicPlayerState.pickingAudio:
          case MusicPlayerState.loadingAudio:
            return const LoadingPage(text: "Loading song...");

          case MusicPlayerState.ready:
            return DefaultTabController(
              length: 2,
              initialIndex: 0,
              animationDuration: const Duration(milliseconds: 200),
              child: ValueListenableBuilder(
                valueListenable: Purchases.hasPremiumNotifier,
                builder: (context, hasPremium, child) {
                  return _buildSongPage(context);
                },
              ),
            );
        }
      },
    );
  }

  Widget _buildSongPage(BuildContext context) {
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

  final TextEditingController searchController = TextEditingController();

  Widget _buildLibraryPage(BuildContext context) {
    final List<Song> songHistory =
        musicPlayer.songHistory.sorted(ascending: false);

    return Scaffold(
      body: ListenableBuilder(
        listenable: searchController,
        builder: (context, child) {
          final String searchPhrase = searchController.text.toLowerCase();
          final Iterable<Song> filteredSongHistory = songHistory.where((song) =>
              song.title.toLowerCase().contains(searchPhrase) ||
              (song.artist?.toLowerCase().contains(searchPhrase) ?? false));

          return CustomScrollView(slivers: [
            SliverAppBar.medium(
              pinned: true,
              title: const Text("Songs"),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    controller: searchController,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (searchPhrase.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: const Icon(Icons.clear),
                        )
                    ],
                    hintText: "Search your library",
                    elevation: const WidgetStatePropertyAll(0),
                  ),
                ),
              ),
            ),
            SliverList.list(
              children: [
                for (final Song song in filteredSongHistory)
                  ListTile(
                    leading: _buildSongSourceAvatar(song) ?? Container(),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(song.artist ?? "Unknown artist"),
                    onTap: musicPlayer.isLoading
                        ? null
                        : () async {
                            if (musicPlayer.isAccessRestricted &&
                                !musicPlayer.songsPlayedThisWeek
                                    .contains(song)) {
                              showExceptionDialog(
                                  const MusicPlayerAccessRestrictedDialog());
                              return;
                            }

                            MusicPlayerState prevState = musicPlayer.state;
                            musicPlayer.stateNotifier.value =
                                MusicPlayerState.pickingAudio;
                            try {
                              await musicPlayer.loadSong(song);
                            } catch (error) {
                              debugPrint("[MUSIC PLAYER] $error");
                              showExceptionDialog(
                                song.source is YoutubeSource
                                    ? const YoutubeUnavailableDialog()
                                    : const FileCouldNotBeLoadedDialog(),
                              );
                              // Restore state
                              musicPlayer.stateNotifier.value = prevState;
                            }
                          },
                  ),
              ],
            )
          ]);
        },
      ),
      floatingActionButton: _buildLoadSongFAB(),
    );
  }

  Widget _buildLoadSongFAB({Object? heroTag}) {
    return SpeedDial.extended(
      heroTag: heroTag,
      label: const Text("Add to library"),
      children: [
        UploadSongButton(),
      ],
      onExpandedPressed: MusicPlayer.instance.isLoading
          ? null
          : () async {
              if (musicPlayer.isAccessRestricted) {
                showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
                return;
              }

              await pickYoutubeSong(context);
            },
      expandedChild: const Icon(Icons.search),
      expandedLabel: const Text("Search"),
      child: const Icon(Icons.add),
    );
  }

  Widget? _buildSongSourceAvatar(Song song) {
    if (song.source is FileSource) {
      return const Icon(Icons.file_present);
    }
    if (song.source is YoutubeSource) {
      return const Icon(Icons.youtube_searched_for);
    }

    return null;
  }
}
