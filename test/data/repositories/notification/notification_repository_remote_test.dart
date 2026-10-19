import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/notification/notification_repository_remote.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  const notification = AppNotification(
    channel: NotificationChannel.metronomeControls,
    title: "Metronome",
    body: "120 bpm",
  );

  setUpAll(() {
    registerFallbackValue(notification);
    registerFallbackValue(Permission.notifications);
  });

  late MockNotificationService service;
  late MockPermissionService permissions;
  late SharedPreferencesService preferences;

  Future<NotificationRepositoryRemote> create({
    PermissionStatus status = PermissionStatus.granted,
  }) async {
    when(
      () => permissions.status(Permission.notifications),
    ).thenAnswer((_) async => status);
    final repository = NotificationRepositoryRemote(
      sharedPreferences: preferences,
      notifications: loaderOf(service, fallback: () => service),
      permissionService: permissions,
    );
    await pumpEventQueue();
    return repository;
  }

  setUp(() async {
    service = MockNotificationService();
    permissions = MockPermissionService();
    preferences = await createPreferences();
    when(() => service.isEnabled).thenReturn(true);
    when(() => service.post(any())).thenAnswer((_) async {});
  });

  test("posts once permission is granted", () async {
    final notifications = await create();
    expect(await notifications.post(notification), isA<Ok<void>>());
    verify(() => service.post(notification)).called(1);
  });

  test("refuses to post without permission", () async {
    final notifications = await create(status: PermissionStatus.denied);
    final result = await notifications.post(notification);

    expect(
      result,
      isA<Failure<void>>().having(
        (f) => f.error,
        "error",
        isA<PermissionException>(),
      ),
    );
    verifyNever(() => service.post(any()));
  });

  test("platforms without a permission count as granted", () async {
    final notifications = await create(status: PermissionStatus.unavailable);
    expect(notifications.hasPermission, isTrue);
  });

  group("requestPermission", () {
    test("grants permission and remembers it asked", () async {
      final notifications = await create(status: PermissionStatus.denied);
      when(
        () => permissions.request(Permission.notifications),
      ).thenAnswer((_) async => PermissionStatus.granted);

      expect((await notifications.requestPermission()).asOk, isTrue);
      expect(notifications.hasPermission, isTrue);
      expect((await create()).hasRequestedPermission, isTrue);
    });

    test("reports a refusal", () async {
      final notifications = await create(status: PermissionStatus.denied);
      when(
        () => permissions.request(Permission.notifications),
      ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);

      expect((await notifications.requestPermission()).asOk, isFalse);
    });

    test("does not prompt again once granted", () async {
      final notifications = await create();
      expect((await notifications.requestPermission()).asOk, isTrue);
      verifyNever(() => permissions.request(any()));
    });
  });

  test("a disabled service reports Unavailable", () async {
    when(() => service.post(any())).thenThrow(ServiceDisabled());
    when(() => service.cancelAll()).thenThrow(ServiceDisabled());
    final notifications = await create();

    expect(await notifications.post(notification), isA<Unavailable<void>>());
    expect(await notifications.cancelAll(), isA<Unavailable<void>>());
  });
}
