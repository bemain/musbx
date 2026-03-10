import 'package:flutter/material.dart';
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
  const SongTile({
    super.key,
    required this.song,
    this.onSelected,
    this.showOptions = true,
  });

  final Song song;
  final void Function()? onSelected;
  final bool showOptions;

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
      minLeadingWidth: 64,
      leading: SizedBox(
        width: 64,
        height: 64,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: isLocked
              ? Icon(
                  Symbols.lock,
                  color: Theme.of(context).disabledColor,
                )
              : buildSongIcon(song),
        ),
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
