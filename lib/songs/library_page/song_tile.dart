import 'package:flutter/material.dart';
import 'package:flutter_m3shapes/flutter_m3shapes.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/options_sheet.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class SongTile extends StatelessWidget {
  /// A list tile widget that displays information about a [song].
  const SongTile({
    super.key,
    required this.song,
    this.onSelected,
    this.showOptions = true,
    this.leadingColor,
  });

  /// The song this tile represents.
  final Song song;

  /// Called when the tile is tapped.
  final void Function()? onSelected;

  /// Whether to show the options button.
  final bool showOptions;

  /// The color used behind the leading icon.
  /// Defaults to [ColorScheme.surfaceContainerHigh].
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final bool isLocked =
        Songs.isAccessRestricted &&
        !Songs.songsPlayedThisWeek.contains(song) &&
        song != demoSong;
    final TextStyle? textStyle = !isLocked
        ? null
        : TextStyle(color: Theme.of(context).disabledColor);

    return ListTile(
      minTileHeight: 72,
      contentPadding: EdgeInsets.only(left: 16, right: 8),
      leading: buildLeading(
        context,
        song,
        color: leadingColor,
        isLocked: isLocked,
      ),
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
      trailing: showOptions
          ? IconButton(
              onPressed: () {
                _showOptionsSheet(context);
              },
              icon: const Icon(Symbols.more_vert),
            )
          : null,
      onTap: () async {
        if (isLocked) {
          await showExceptionDialog(
            const MusicPlayerAccessRestrictedDialog(),
          );
          return;
        }

        onSelected?.call();
        await context.push(Routes.song(song.id));
      },
      onLongPress: showOptions
          ? () {
              _showOptionsSheet(context);
            }
          : null,
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showAlertSheet<void>(
      context: context,
      builder: (context) => SongOptionsSheet(song: song),
    );
  }

  static Widget buildLeading(
    BuildContext context,
    Song song, {
    Color? color,
    bool isLocked = false,
  }) {
    return SizedBox(
      width: 64,
      child: M3Container.c4SidedCookie(
        height: 64,
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: isLocked
              ? Icon(
                  Symbols.lock,
                  color: Theme.of(context).disabledColor,
                )
              : buildSongIcon(song),
        ),
      ),
    );
  }

  static Widget buildSongIcon(Song song) {
    if (song == demoSong) {
      return const Icon(Symbols.science);
    }
    return Icon(switch (song.audio) {
      FileAudio() => Symbols.file_present,
      YtdlpAudio() => Symbols.music_note,
      _ => Symbols.music_note,
    });
  }
}
