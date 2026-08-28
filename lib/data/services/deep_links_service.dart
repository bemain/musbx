import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:uri_content/uri_content.dart';
import 'package:uuid/uuid.dart';

/// Turns the files the operating system hands the app into songs.
///
/// Covers every way the app is reached from outside it: a shared file, "Open
/// with" on an audio file, a tapped link. All of them arrive as a URI, and what
/// this service does with one is resolve it far enough to be a [Song].
///
/// It stops there deliberately. Storing that song, deciding whether the user is
/// allowed to open it, and navigating to it are all decisions that belong above
/// a service, so they happen where [songStream] is listened to — once, at
/// startup, since the operating system announces a launch file before there is
/// an app to show it in.
///
/// Optional: [disabled] returns a service that emits nothing, for a platform
/// with no way to hand the app a file.
class DeepLinksService extends OptionalService {
  DeepLinksService._(this._appLinks) {
    _subscription = _appLinks?.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint("[DEEP LINKS] Link stream error: $error");
      },
    );
  }

  @override
  bool get isEnabled => _appLinks != null;

  /// The plugin handle, or `null` when this service is [disabled].
  final AppLinks? _appLinks;

  /// Carries the URIs the operating system sends, for as long as the app runs.
  StreamSubscription<Uri>? _subscription;

  final _songController = StreamController<Song>();

  /// The songs the operating system has asked the app to open.
  ///
  /// Songs are held until something listens, so the file the app was launched
  /// to open still reaches a listener that only attaches once the rest of
  /// startup has finished.
  ///
  /// There can be only one listener, and a second one throws. Two would each
  /// store the song and each navigate to it, so opening one shared file would
  /// add it to the library twice.
  ///
  /// The songs are resolved but not stored — they are not in the library, and
  /// for a shared file the bytes exist only in memory.
  Stream<Song> get songStream => _songController.stream;

  /// Create the service and begin listening for URIs.
  ///
  /// Listening starts here rather than when [songStream] is first subscribed
  /// to, because the operating system delivers the URI that launched the app
  /// once and does not repeat it.
  static Future<DeepLinksService> create({AppLinks? appLinks}) async {
    final a = appLinks ?? AppLinks();

    return DeepLinksService._(a);
  }

  /// A service that emits nothing, for platforms that open no files.
  static DeepLinksService disabled() => DeepLinksService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final DeepLinksService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint("[DEEP LINKS] Disabled, initialization failed: $error");
      instance = disabled();
    }
  }

  /// Resolve one URI into a song, if it names something the app can play.
  ///
  /// A `file:` URI points at something that stays where it is, so its id is
  /// derived from the path: opening the same file twice produces the same song,
  /// and the library recognizes it as one it already has.
  ///
  /// A `content:` or `data:` URI is a handle to bytes the sender may revoke at
  /// any moment, so they are read immediately and carried in memory. There is
  /// nothing stable to identify them by, which is why each one becomes a new
  /// song named after a fresh id — the same file shared twice arrives as two.
  ///
  /// Anything else is ignored rather than treated as an error; the app is
  /// registered for links it does not open a song for.
  Future<void> _handleUri(Uri uri) async {
    try {
      switch (uri.scheme) {
        case "file":
          String path = uri.toFilePath();
          _songController.add(
            Song(
              id: sha1.convert(utf8.encode(path)).toString(),
              title: path.split("/").last.split(".").first,
              audio: FileAudio(File(path)),
            ),
          );

        case "content" || "data":
          final Uint8List content = await uri.getContent();
          final String id = Uuid().v4();
          _songController.add(
            Song(
              id: id,
              title: id,
              audio: BytesAudio(content),
            ),
          );

        case _:
          return;
      }
    } catch (error) {
      debugPrint("[DEEP LINKS] Error resolving file URI: $error");
    }
  }

  /// Stop listening for URIs and close [songStream].
  ///
  /// The app stops being reachable from outside it once this has run, so it is
  /// meant for tests and for tearing the app down, not for a screen going away.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _songController.close();
  }
}
