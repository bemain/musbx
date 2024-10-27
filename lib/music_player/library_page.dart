import 'package:flutter/material.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pick_song_button/components/search_youtube_button.dart';
import 'package:musbx/music_player/pick_song_button/components/upload_file_button.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: _buildLoadSongFAB(context),
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
