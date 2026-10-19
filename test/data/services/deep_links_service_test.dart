import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/domain/models/song.dart';

class MockAppLinks extends Mock implements AppLinks {}

void main() {
  group("enabled", () {
    late StreamController<Uri> links;
    late DeepLinksService deepLinks;

    setUp(() async {
      links = StreamController();
      addTearDown(links.close);
      final appLinks = MockAppLinks();
      when(() => appLinks.uriLinkStream).thenAnswer((_) => links.stream);

      deepLinks = DeepLinksService.createWith(appLinks);
      addTearDown(deepLinks.dispose);
    });

    test("a file becomes a song identified by its path", () async {
      links.add(Uri.file("/music/Bach - Prelude.mp3"));

      final song = await deepLinks.songStream.first;

      expect(
        song.id,
        sha1.convert(utf8.encode("/music/Bach - Prelude.mp3")).toString(),
      );
      expect(song.title, "Bach - Prelude");
      expect((song.audio as FileAudio).file.path, "/music/Bach - Prelude.mp3");
    });

    test("shared bytes are read immediately into a new song", () async {
      links.add(Uri.dataFromBytes([1, 2, 3]));
      links.add(Uri.dataFromBytes([1, 2, 3]));

      final songs = await deepLinks.songStream.take(2).toList();

      expect((songs.first.audio as BytesAudio).bytes, [1, 2, 3]);
      expect(songs.first.title, songs.first.id);
      expect(songs.first.id, isNot(songs.last.id));
    });

    test("links that name no song are ignored", () async {
      links.add(Uri.parse("https://musbx.app/tools"));
      links.add(Uri.file("/music/a.mp3"));

      expect((await deepLinks.songStream.first).title, "a");
    });

    test("a song that arrives before anyone listens is kept", () async {
      links.add(Uri.file("/music/a.mp3"));
      await pumpEventQueue();

      expect((await deepLinks.songStream.first).title, "a");
    });
  });

  test("dispose completes when nothing ever listened", () {
    final appLinks = MockAppLinks();
    when(() => appLinks.uriLinkStream).thenAnswer((_) => const Stream.empty());

    expect(DeepLinksService.createWith(appLinks).dispose(), completes);
  });

  test("disabled emits nothing", () async {
    final disabled = DeepLinksService.disabled();
    expect(disabled.isEnabled, isFalse);

    final isEmpty = disabled.songStream.isEmpty;
    await disabled.dispose();
    expect(await isEmpty, isTrue);
  });
}
