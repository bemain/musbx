import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/entitlement.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

PurchaseDetails purchase(
  PurchaseStatus status, {
  String productID = "premium",
  bool pendingCompletePurchase = false,
}) => PurchaseDetails(
  productID: productID,
  verificationData: PurchaseVerificationData(
    localVerificationData: "",
    serverVerificationData: "",
    source: "test",
  ),
  transactionDate: null,
  status: status,
)..pendingCompletePurchase = pendingCompletePurchase;

final premiumDetails = ProductDetails(
  id: "premium",
  title: "Premium",
  description: "Everything",
  price: "€5",
  rawPrice: 5,
  currencyCode: "EUR",
);

void main() {
  setUpAll(() {
    registerFallbackValue(purchase(PurchaseStatus.purchased));
    registerFallbackValue(PurchaseParam(productDetails: premiumDetails));
  });

  late MockInAppPurchase store;
  late StreamController<List<PurchaseDetails>> updates;
  late PurchaseService purchases;

  setUp(() async {
    store = MockInAppPurchase();
    updates = StreamController();
    addTearDown(updates.close);
    when(store.isAvailable).thenAnswer((_) async => true);
    when(() => store.purchaseStream).thenAnswer((_) => updates.stream);
    when(store.restorePurchases).thenAnswer((_) async {});
    when(() => store.completePurchase(any())).thenAnswer((_) async {});
    when(() => store.queryProductDetails({"premium"})).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: [premiumDetails],
        notFoundIDs: [],
      ),
    );
    when(
      () => store.buyNonConsumable(purchaseParam: any(named: "purchaseParam")),
    ).thenAnswer((_) async => true);

    purchases = await PurchaseService.createWith(store);
    addTearDown(purchases.dispose);
  });

  test("an unreachable store gives a disabled service", () async {
    when(store.isAvailable).thenAnswer((_) async => false);
    final unavailable = await PurchaseService.createWith(store);
    expect(unavailable.isEnabled, isFalse);
  });

  test("purchased and restored products are reported as purchased", () async {
    final statuses = purchases.statusStream.take(2).toList();

    updates.add([
      purchase(PurchaseStatus.purchased),
      purchase(PurchaseStatus.restored),
    ]);

    expect(await statuses, [
      (entitlement: Entitlement.premium, status: EntitlementStatus.purchased),
      (entitlement: Entitlement.premium, status: EntitlementStatus.purchased),
    ]);
  });

  test(
    "canceled and failed purchases are reported as not purchased",
    () async {
      final statuses = purchases.statusStream.take(2).toList();

      updates.add([
        purchase(PurchaseStatus.canceled),
        purchase(PurchaseStatus.error),
      ]);

      expect((await statuses).map((s) => s.status), [
        EntitlementStatus.notPurchased,
        EntitlementStatus.notPurchased,
      ]);
    },
  );

  test("every pending transaction is completed, known or not", () async {
    final known = purchase(
      PurchaseStatus.purchased,
      pendingCompletePurchase: true,
    );
    final unknown = purchase(
      PurchaseStatus.purchased,
      productID: "retired",
      pendingCompletePurchase: true,
    );
    final status = purchases.statusStream.first;

    updates.add([unknown, known]);

    expect((await status).entitlement, Entitlement.premium);
    await pumpEventQueue();
    verify(() => store.completePurchase(unknown));
    verify(() => store.completePurchase(known));
  });

  test(
    "a transaction that cannot be completed does not stop updates",
    () async {
      when(
        () => store.completePurchase(any()),
      ).thenThrow(Exception("store hiccup"));
      final statuses = purchases.statusStream.take(2).toList();

      updates.add([
        purchase(PurchaseStatus.purchased, pendingCompletePurchase: true),
      ]);
      updates.add([purchase(PurchaseStatus.canceled)]);

      expect((await statuses).map((s) => s.status), [
        EntitlementStatus.purchased,
        EntitlementStatus.notPurchased,
      ]);
    },
  );

  test("details describe the product that sells the entitlement", () async {
    final details = await purchases.details(Entitlement.premium);

    expect(details.title, "Premium");
    expect(details.description, "Everything");
    expect(details.price, "€5");
  });

  test("buy starts the store's flow for that product", () async {
    expect(await purchases.buy(Entitlement.premium), isTrue);

    final param =
        verify(
              () => store.buyNonConsumable(
                purchaseParam: captureAny(named: "purchaseParam"),
              ),
            ).captured.single
            as PurchaseParam;
    expect(param.productDetails.id, "premium");
  });

  test("dispose does not wait for the store's next update", () {
    expect(purchases.dispose(), completes);
  });

  test("restore asks the store", () async {
    await purchases.restore();
    verify(store.restorePurchases);
  });

  group("disabled", () {
    final disabled = PurchaseService.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("throws from everything that needs the store", () {
      expect(disabled.restore(), throwsA(isA<ServiceDisabled>()));
      expect(
        disabled.details(Entitlement.premium),
        throwsA(isA<ServiceDisabled>()),
      );
      expect(
        disabled.buy(Entitlement.premium),
        throwsA(isA<ServiceDisabled>()),
      );
    });

    test("reports no statuses", () async {
      final isEmpty = disabled.statusStream.isEmpty;
      await disabled.dispose();
      expect(await isEmpty, isTrue);
    });
  });
}
