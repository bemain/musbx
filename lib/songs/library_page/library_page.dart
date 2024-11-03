import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/library_page/youtube_search.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_source.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: searchController,
        builder: (context, child) {
          final String searchPhrase = searchController.text.toLowerCase();

          return CustomScrollView(slivers: [
            SliverAppBar.medium(
              pinned: true,
              title: const Text("Songs"),
              actions: const [
                GetPremiumButton(),
                InfoButton(),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    controller: searchController,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    leading: const Icon(Symbols.search),
                    trailing: [
                      if (searchPhrase.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: const Icon(Symbols.clear),
                        )
                    ],
                    hintText: "Search your library",
                    elevation: const WidgetStatePropertyAll(0),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: musicPlayer.songHistory,
              builder: (context, child) {
                final Iterable<Song> songHistory = musicPlayer.songHistory
                    .sorted(ascending: false)
                    .where((song) =>
                        song.title.toLowerCase().contains(searchPhrase) ||
                        (song.artist?.toLowerCase().contains(searchPhrase) ??
                            false));

                return SliverList.list(
                  children: [
                    for (final Song song in songHistory)
                      _buildSongTile(context, song),
                    const SizedBox(height: 80),
                  ],
                );
              },
            )
          ]);
        },
      ),
      floatingActionButton: _buildLoadSongFAB(context),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song) {
    final bool isLocked = musicPlayer.isAccessRestricted &&
        !musicPlayer.songsPlayedThisWeek.contains(song) &&
        song != demoSong;
    final TextStyle? textStyle =
        !isLocked ? null : TextStyle(color: Theme.of(context).disabledColor);

    return ListTile(
      leading: isLocked
          ? Icon(
              Symbols.lock,
              color: Theme.of(context).disabledColor,
            )
          : _buildSongSourceAvatar(song) ?? Container(),
      title: Text(
        song.title,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? "Unknown artist",
        style: textStyle,
      ),
      trailing: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Symbols.delete, weight: 600),
                title: const Text("Remove from library?"),
                content: const Text(
                  "Are you sure you want to remove this song from your library? \n\nYou can always add the song again later, but your preferences for this song will be reset.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  FilledButton(
                    onPressed: () {
                      musicPlayer.songHistory.remove(song);
                      Navigator.of(context).pop();
                    },
                    child: const Text("Remove"),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Symbols.delete),
      ),
      onTap: musicPlayer.isLoading
          ? null
          : () async {
              if (isLocked) {
                showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
                return;
              }

              MusicPlayerState prevState = musicPlayer.state;
              musicPlayer.stateNotifier.value = MusicPlayerState.loadingAudio;
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
    );
  }

  Widget _buildLoadSongFAB(BuildContext context, {Object? heroTag}) {
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
      expandedChild: const Icon(Symbols.search),
      expandedLabel: const Text("Search"),
      child: const Icon(Symbols.add),
    );
  }

  Widget? _buildSongSourceAvatar(Song song) {
    if (song == demoSong) {
      return const Icon(Symbols.science);
    }

    if (song.source is FileSource) {
      return const Icon(Symbols.file_present);
    }
    if (song.source is YoutubeSource) {
      return const Icon(Symbols.youtube_searched_for);
    }

    return null;
  }
}
