import 'package:go_router/go_router.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class DeepLinks {
  static Future<void> initialize() async {
    DeepLinksService.instance.songStream.listen((song) async {
      song = await SongLibrary.add(song);

      if (Songs.isAccessRestricted) {
        await showExceptionDialog(
          const MusicPlayerAccessRestrictedDialog(),
        );
      } else {
        await Navigation.navigatorKey.currentContext?.push(
          Routes.song(song.id),
        );
      }
    });
  }
}
