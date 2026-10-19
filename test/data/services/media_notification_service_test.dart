import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/models/media_command.dart';
import 'package:musbx/data/models/media_notification_state.dart';
import 'package:musbx/data/services/media_notification_service.dart';
import 'package:musbx/data/services/service.dart';

MediaNotificationState state({
  bool isPlaying = true,
  Duration position = Duration.zero,
}) => MediaNotificationState(
  id: "song",
  title: "Prelude",
  artist: "Bach",
  duration: const Duration(minutes: 3),
  isPlaying: isPlaying,
  position: position,
  speed: 1.5,
);

void main() {
  late MediaNotificationHandler handler;

  setUp(() {
    handler = MediaNotificationHandler();
    addTearDown(handler.dispose);
  });

  test("controls become commands", () async {
    final commands = handler.commands.take(4).toList();

    await handler.play();
    await handler.pause();
    await handler.seek(const Duration(seconds: 7));
    await handler.stop();

    final received = await commands;
    expect(received[0], isA<Play>());
    expect(received[1], isA<Pause>());
    expect(
      received[2],
      isA<Seek>().having((s) => s.position, "position", Duration(seconds: 7)),
    );
    expect(received[3], isA<Stop>());
  });

  test("update shows the song and its playback", () {
    handler.update(state(position: const Duration(seconds: 30)));

    final item = handler.mediaItem.value!;
    expect(item.title, "Prelude");
    expect(item.artist, "Bach");
    expect(item.artUri, isNotNull);

    final playback = handler.playbackState.value;
    expect(playback.playing, isTrue);
    expect(playback.controls.first, MediaControl.pause);
    expect(playback.updatePosition, const Duration(seconds: 30));
    expect(playback.speed, 1.5);
  });

  test("a paused song offers play", () {
    handler.update(state(isPlaying: false));
    expect(handler.playbackState.value.controls.first, MediaControl.play);
  });

  test("the media item is only replaced when it changes", () async {
    final items = <MediaItem?>[];
    final subscription = handler.mediaItem.skip(1).listen(items.add);

    handler.update(state());
    handler.update(state(position: const Duration(seconds: 1)));
    await pumpEventQueue();
    await subscription.cancel();

    expect(items, hasLength(1));
  });

  test("update with nothing removes the notification", () {
    handler.update(state());
    handler.update(null);

    expect(handler.mediaItem.value, isNull);
    expect(handler.playbackState.value.playing, isFalse);
  });

  group("disabled", () {
    final disabled = MediaNotificationService.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("throws from everything that needs the notification", () {
      expect(() => disabled.commands, throwsA(isA<ServiceDisabled>()));
      expect(() => disabled.update(null), throwsA(isA<ServiceDisabled>()));
    });
  });
}
