import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository_remote.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/domain/models/entitlement.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

class MockPurchaseService extends Mock implements PurchaseService {}

typedef Status = ({Entitlement entitlement, EntitlementStatus status});

void main() {
  setUpAll(() => registerFallbackValue(Entitlement.premium));

  EntitlementRepositoryRemote create(
    Future<PurchaseService> Function() store,
  ) {
    final repository = EntitlementRepositoryRemote(
      purchase: ServiceLoader(
        create: store,
        fallback: PurchaseService.disabled,
      ),
    );
    addTearDown(repository.dispose);
    return repository;
  }

  test("nothing is unlocked until the store is known", () {
    final entitlements = create(() async => PurchaseService.disabled());
    expect(entitlements.hasPremium, isFalse);
  });

  test("everything is unlocked where there is no store", () async {
    final loader = loaderOf(
      PurchaseService.disabled(),
      fallback: PurchaseService.disabled,
    );
    final entitlements = EntitlementRepositoryRemote(purchase: loader);
    addTearDown(entitlements.dispose);

    await loader.ensureAvailable();
    expect(entitlements.hasPremium, isTrue);
  });

  group("with a store", () {
    late MockPurchaseService store;
    late StreamController<Status> statuses;
    late ServiceLoader<PurchaseService> loader;
    late EntitlementRepositoryRemote entitlements;

    setUp(() async {
      store = MockPurchaseService();
      statuses = StreamController.broadcast();
      addTearDown(statuses.close);
      when(() => store.isEnabled).thenReturn(true);
      when(() => store.statusStream).thenAnswer((_) => statuses.stream);
      when(() => store.restore()).thenAnswer((_) async {});
      when(() => store.buy(any())).thenAnswer((_) async => true);

      loader = loaderOf(store, fallback: PurchaseService.disabled);
      entitlements = EntitlementRepositoryRemote(purchase: loader);
      addTearDown(entitlements.dispose);
      await loader.ensureAvailable();
    });

    test("restores earlier purchases as soon as it is reached", () {
      verify(() => store.restore()).called(1);
    });

    test("a confirmed purchase unlocks premium", () async {
      var notifications = 0;
      entitlements.addListener(() => notifications++);

      statuses.add((
        entitlement: Entitlement.premium,
        status: EntitlementStatus.purchased,
      ));
      await pumpEventQueue();

      expect(entitlements.hasPremium, isTrue);
      expect(notifications, 1);
    });

    test("buying goes through the store", () async {
      expect((await entitlements.buyPremium()).asOk, isTrue);
      verify(() => store.buy(Entitlement.premium)).called(1);
    });

    test("buying again once premium does not reach the store", () async {
      statuses.add((
        entitlement: Entitlement.premium,
        status: EntitlementStatus.purchased,
      ));
      await pumpEventQueue();

      expect((await entitlements.buyPremium()).asOk, isTrue);
      verifyNever(() => store.buy(any()));
    });
  });

  test("buying without a store is Unavailable", () async {
    final entitlements = create(() async => PurchaseService.disabled());
    expect(await entitlements.buyPremium(), isA<Unavailable<bool>>());
    expect(await entitlements.restore(), isA<Unavailable<void>>());
  });
}
