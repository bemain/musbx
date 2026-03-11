import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/library_page/search_bar.dart';
import 'package:musbx/songs/library_page/song_tile.dart';
import 'package:musbx/songs/library_page/soundcloud_search.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            scrolledUnderElevation: 0,
            toolbarHeight: 68,
            expandedHeight: 128,
            title: LibrarySearchBar(),
            actions: const [
              GetPremiumButton(),
              SettingsButton(),
            ],
          ),
          ListenableBuilder(
            listenable: SongLibrary.history,
            builder: (context, child) {
              return SliverList.list(
                children: [
                  const SizedBox(height: 8),
                  for (final Song song in SongLibrary.history.sorted(
                    ascending: false,
                  ))
                    SongTile(
                      song: song,
                      showOptions: true,
                    ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildLoadSongFAB(context),
    );
  }

  Widget _buildLoadSongFAB(BuildContext context, {Object? heroTag}) {
    return SpeedDial.extended(
      heroTag: heroTag,
      shouldExpand: () {
        if (Songs.isAccessRestricted) {
          showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
        }

        return !Songs.isAccessRestricted;
      },
      onExpandedPressed: () => SoundCloudSearch.pickSong(context),
      expandedChild: const Icon(Symbols.search),
      expandedLabel: const Text("Search"),
      children: [
        UploadSongButton(),
      ],
      label: const Text("Add to library"),
      child: const Icon(Symbols.add),
    );
  }
}
