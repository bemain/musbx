import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/songs/library_page/online_track_search.dart';
import 'package:musbx/songs/library_page/search_bar.dart';
import 'package:musbx/songs/library_page/song_tile.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/announcements_page.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:provider/provider.dart';

/// The user's songs, most recently played first, with search and upload above
/// them.
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
            actions: [
              AnnouncementsButton(),
              GetPremiumButton(),
              SettingsButton(),
            ],
          ),
          ListenableBuilder(
            listenable: context.read<SongRepository>(),
            builder: (context, child) {
              return SliverList.list(
                children: [
                  const SizedBox(height: 8),
                  for (final Song song
                      in context.read<SongRepository>().getAll(
                        order: GetOrder.descending,
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

  /// Let the user search for a track online, add the one they pick to the
  /// library, and open it.
  ///
  /// The search starts from [query] when given.
  Future<void> pickSong(BuildContext context, {String? query}) async {
    OnlineTrack? track = await showSearch<OnlineTrack?>(
      context: context,
      delegate: OnlineTrackSearchDelegate(),
      useRootNavigator: true,
      query: query ?? "",
    );

    if (track == null) return;

    if (!context.mounted) return;
    switch (await context.read<SongRepository>().addTrack(track)) {
      case Ok(value: final song):
        if (context.mounted) context.go(Routes.song(song.id));

      case Failure(:final error):
        debugPrint(
          "[Library] Unable to add track to library; $error",
        );
      // TODO: Show error snackbar
    }
  }

  Widget _buildLoadSongFAB(BuildContext context, {Object? heroTag}) {
    return SpeedDial.extended(
      heroTag: heroTag,
      shouldExpand: () {
        final restricted = context.read<CheckSongAccess>().isRestricted;
        if (restricted) {
          showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
        }

        return !restricted;
      },
      onExpandedPressed: () => pickSong(context),
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
