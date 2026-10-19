import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/notification.dart';

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidNotifications extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

const _notification = AppNotification(
  channel: NotificationChannel.metronomeControls,
  title: "Metronome",
  summary: "Playing",
  body: "120 bpm",
  actionSet: NotificationActionSet.metronomePlaying,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const AndroidNotificationChannelGroup("", ""));
    registerFallbackValue(const AndroidNotificationChannel("", ""));
    registerFallbackValue(const AndroidNotificationDetails("", ""));
    registerFallbackValue(AndroidServiceStartType.startNotSticky);
    registerFallbackValue(<AndroidServiceForegroundType>{});
    registerFallbackValue((NotificationResponse _) {});
  });

  late MockNotificationsPlugin plugin;
  late MockAndroidNotifications? android;
  late void Function(NotificationResponse) respond;

  Future<NotificationService> create({bool onAndroid = true}) async {
    android = onAndroid ? MockAndroidNotifications() : null;
    final a = android;
    if (a != null) {
      when(() => a.createNotificationChannelGroup(any())).thenAnswer(
        (_) async {},
      );
      when(() => a.createNotificationChannel(any())).thenAnswer((_) async {});
      when(
        () => a.startForegroundService(
          id: any(named: "id"),
          title: any(named: "title"),
          body: any(named: "body"),
          notificationDetails: any(named: "notificationDetails"),
          startType: any(named: "startType"),
          foregroundServiceTypes: any(named: "foregroundServiceTypes"),
        ),
      ).thenAnswer((_) async {});
      when(a.stopForegroundService).thenAnswer((_) async {});
    }
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(a);

    final service = await NotificationService.createWith(plugin);
    respond =
        verify(
              () => plugin.initialize(
                settings: any(named: "settings"),
                onDidReceiveNotificationResponse: captureAny(
                  named: "onDidReceiveNotificationResponse",
                ),
                onDidReceiveBackgroundNotificationResponse: any(
                  named: "onDidReceiveBackgroundNotificationResponse",
                ),
              ),
            ).captured.last
            as void Function(NotificationResponse);
    return service;
  }

  setUp(() {
    plugin = MockNotificationsPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: "settings"),
        onDidReceiveNotificationResponse: any(
          named: "onDidReceiveNotificationResponse",
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: "onDidReceiveBackgroundNotificationResponse",
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: "id"),
        title: any(named: "title"),
        body: any(named: "body"),
        notificationDetails: any(named: "notificationDetails"),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: "id"))).thenAnswer((_) async {});
    when(plugin.cancelAll).thenAnswer((_) async {});
  });

  test("create registers every channel with Android", () async {
    await create();

    final channels = verify(
      () => android!.createNotificationChannel(captureAny()),
    ).captured.cast<AndroidNotificationChannel>();
    expect(channels.map((c) => c.id), ["metronome-controls"]);
    verify(() => android!.createNotificationChannelGroup(any()));
  });

  group("on Android", () {
    late NotificationService notifications;

    setUp(() async => notifications = await create());

    test("the first post starts the foreground service", () async {
      await notifications.post(_notification);

      verify(
        () => android!.startForegroundService(
          id: 1,
          title: "Metronome",
          body: "120 bpm",
          notificationDetails: any(named: "notificationDetails"),
          startType: AndroidServiceStartType.startNotSticky,
          foregroundServiceTypes: any(named: "foregroundServiceTypes"),
        ),
      );
      verifyNever(
        () => plugin.show(
          id: any(named: "id"),
          title: any(named: "title"),
          body: any(named: "body"),
          notificationDetails: any(named: "notificationDetails"),
        ),
      );
    });

    test("later posts replace the notification in place", () async {
      await notifications.post(_notification);
      await notifications.post(_notification);

      final details =
          verify(
                () => plugin.show(
                  id: 1,
                  title: "Metronome",
                  body: "120 bpm",
                  notificationDetails: captureAny(
                    named: "notificationDetails",
                  ),
                ),
              ).captured.single
              as NotificationDetails;
      expect(details.android?.subText, "Playing");
      expect(details.android?.actions?.map((a) => a.id), ["pause"]);
      expect(details.iOS?.categoryIdentifier, "metronomePlaying");
    });

    test("cancel stops the foreground service it started", () async {
      await notifications.post(_notification);
      await notifications.cancel(NotificationChannel.metronomeControls);

      verify(android!.stopForegroundService);
      verify(() => plugin.cancel(id: 1));

      await notifications.post(_notification);
      verify(
        () => android!.startForegroundService(
          id: 1,
          title: any(named: "title"),
          body: any(named: "body"),
          notificationDetails: any(named: "notificationDetails"),
          startType: any(named: "startType"),
          foregroundServiceTypes: any(named: "foregroundServiceTypes"),
        ),
      ).called(2);
    });

    test("cancelAll without a foreground service only cancels", () async {
      await notifications.cancelAll();

      verifyNever(android!.stopForegroundService);
      verify(plugin.cancelAll);
    });
  });

  test("off Android every post is shown directly", () async {
    final notifications = await create(onAndroid: false);

    await notifications.post(_notification);

    verify(
      () => plugin.show(
        id: 1,
        title: any(named: "title"),
        body: any(named: "body"),
        notificationDetails: any(named: "notificationDetails"),
      ),
    );
  });

  group("actionStream", () {
    late NotificationService notifications;

    setUp(() async => notifications = await create());

    NotificationResponse response(int? id, String? actionId) =>
        NotificationResponse(
          notificationResponseType: actionId == null
              ? NotificationResponseType.selectedNotification
              : NotificationResponseType.selectedNotificationAction,
          id: id,
          actionId: actionId,
        );

    test("reports buttons and taps on the body", () async {
      final tapped = notifications.actionStream.take(2).toList();

      respond(response(1, "pause"));
      respond(response(1, null));

      final actions = await tapped;
      expect(actions.map((a) => a.channel), [
        NotificationChannel.metronomeControls,
        NotificationChannel.metronomeControls,
      ]);
      expect(actions.map((a) => a.action), [NotificationAction.pause, null]);
    });

    test("drops notifications and buttons this app does not know", () async {
      final tapped = notifications.actionStream.first;

      respond(response(null, "pause"));
      respond(response(99, "pause"));
      respond(response(1, "retired"));
      respond(response(1, "pause"));

      expect((await tapped).action, NotificationAction.pause);
    });
  });

  group("disabled", () {
    final disabled = NotificationService.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("throws from everything that needs the plugin", () {
      expect(disabled.post(_notification), throwsA(isA<ServiceDisabled>()));
      expect(
        disabled.cancel(NotificationChannel.metronomeControls),
        throwsA(isA<ServiceDisabled>()),
      );
      expect(disabled.cancelAll(), throwsA(isA<ServiceDisabled>()));
    });
  });
}
