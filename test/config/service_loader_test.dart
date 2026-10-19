import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/services/service.dart';

class FakeService extends OptionalService {
  FakeService({this.isEnabled = true});

  @override
  final bool isEnabled;
}

void main() {
  final fallback = FakeService(isEnabled: false);

  ServiceLoader<FakeService> loader(
    Future<FakeService> Function() create, {
    Duration retryCooldown = const Duration(minutes: 1),
  }) => ServiceLoader(
    create: create,
    fallback: () => fallback,
    retryCooldown: retryCooldown,
  );

  test("hands out the fallback until the service is created", () async {
    final created = FakeService();
    final services = loader(() async => created);

    expect(services.value, same(fallback));
    expect(services.availability, ServiceAvailability.unknown);
    expect(await services.ready, same(created));
    expect(services.availability, ServiceAvailability.ready);
  });

  test("a disabled service is unsupported and never retried", () async {
    var attempts = 0;
    final services = loader(() async {
      attempts++;
      return FakeService(isEnabled: false);
    }, retryCooldown: Duration.zero);

    await services.ensureAvailable();
    await services.ensureAvailable();

    expect(services.availability, ServiceAvailability.unsupported);
    expect(services.canRetry, isFalse);
    expect(attempts, 1);
  });

  test("concurrent requests share one attempt", () async {
    var attempts = 0;
    final services = loader(() async {
      attempts++;
      return FakeService();
    });

    await Future.wait([for (var i = 0; i < 3; i++) services.ready]);
    expect(attempts, 1);
  });

  group("after a failure", () {
    test("keeps the fallback and retries after the cooldown", () async {
      var fail = true;
      final services = loader(() async {
        if (fail) throw Exception("offline");
        return FakeService();
      }, retryCooldown: Duration.zero);

      await services.ensureAvailable();
      expect(services.availability, ServiceAvailability.failed);
      expect(services.value, same(fallback));

      fail = false;
      await services.ensureAvailable();
      expect(services.availability, ServiceAvailability.ready);
    });

    test("does not retry within the cooldown", () async {
      var attempts = 0;
      final services = loader(() async {
        attempts++;
        throw Exception("offline");
      });

      await services.ensureAvailable();
      await services.ensureAvailable();
      expect(attempts, 1);
    });
  });

  test(
    "bind re-attaches when the created service replaces the fallback",
    () async {
      final created = FakeService();
      final services = loader(() async => created);
      final attached = <FakeService>[];

      final unbind = services.bind(attached.add);
      await services.ensureAvailable();
      unbind();

      expect(attached, [same(fallback), same(created)]);
    },
  );
}
