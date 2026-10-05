import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/entitlement.dart';

/// Sells the app's [Entitlement]s through the store the app was installed from.
///
/// Purchases are optional. [disabled] returns a service with no store behind
/// it, for platforms that have none and for devices where the store cannot be
/// reached.
///
/// This reports what the store says but does not remember it. Which
/// entitlements the user currently holds is app state, and belongs to the layer
/// above.
class PurchaseService extends OptionalService {
  PurchaseService._(
    this.__inAppPurchase,
  ) {
    if (__inAppPurchase == null) return;
    final purchases = __inAppPurchase.purchaseStream;

    _subscription = _processPurchases(purchases).listen(
      _statusController.add,
      onError: (Object error) {
        debugPrint("[PURCHASES] Purchase stream error: $error");
      },
    );
  }

  final InAppPurchase? __inAppPurchase;

  /// The store connection, or `null` when this service is [disabled].
  InAppPurchase get _inAppPurchase {
    throwIfDisabled();
    return __inAppPurchase!;
  }

  @override
  bool get isEnabled => __inAppPurchase != null;

  /// Create the service, connecting to the store.
  ///
  /// Returns a [disabled] service on platforms that have no store, and on
  /// devices where the store is unreachable or the user has disabled purchases.
  ///
  /// Starts listening for purchase updates immediately: updates that arrive
  /// before anyone is listening are dropped, and the store redelivers
  /// transactions left unfinished by earlier sessions as soon as the app opens.
  static Future<PurchaseService> create({
    InAppPurchase? inAppPurchase,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return disabled();
    }

    final p = inAppPurchase ?? InAppPurchase.instance;
    if (!await p.isAvailable()) return disabled();

    return PurchaseService._(p);
  }

  /// A service with no store behind it, for when none is available.
  static PurchaseService disabled() => PurchaseService._(null);

  final _statusController =
      StreamController<
        ({Entitlement entitlement, EntitlementStatus status})
      >.broadcast();
  StreamSubscription<({Entitlement entitlement, EntitlementStatus status})>?
  _subscription;

  /// Entitlement statuses reported by the store, as they happen.
  ///
  /// Emits [EntitlementStatus.purchased] once the store confirms a purchase,
  /// whether it was just bought or restored from an earlier install. On Android
  /// it also emits [EntitlementStatus.pending] while payment is being
  /// confirmed.
  ///
  /// A purchase the user cancels and one the store rejects both arrive as
  /// [EntitlementStatus.notPurchased] — only the log says which.
  ///
  /// A late listener does not receive earlier statuses, so callers that need to
  /// know the current status have to keep track of it themselves.
  Stream<({Entitlement entitlement, EntitlementStatus status})>
  get statusStream => _statusController.stream;

  /// Restore purchases the user has already made, for example after
  /// reinstalling the app.
  ///
  /// Anything restored arrives on [statusStream] rather than being returned.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  Future<void> restore() async {
    await _inAppPurchase.restorePurchases();
  }

  /// Look up how [entitlement] is presented to the user.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled], and a
  /// [StateError] when the store has nothing to say about the entitlement —
  /// because it is not for sale, or because the store could not be reached.
  Future<EntitlementDetails> details(Entitlement entitlement) async {
    final details = await _details(entitlement);

    return EntitlementDetails(
      entitlement: entitlement,
      title: details.title,
      description: details.description,
      price: details.price,
    );
  }

  /// Start the store's purchase flow for [entitlement].
  ///
  /// Returns whether the flow could be started, which says nothing about
  /// whether the user went on to buy anything — that arrives on [statusStream].
  ///
  /// Throws [ServiceDisabled] when this service is [disabled], and a
  /// [StateError] when [entitlement] is not for sale.
  Future<bool> buy(Entitlement entitlement) async {
    final d = await _details(entitlement);

    return await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: d),
    );
  }

  String _productIdOf(Entitlement entitlement) => switch (entitlement) {
    Entitlement.premium => "premium",
  };
  Entitlement? _entitlementOf(String productId) => Entitlement.values
      .where((entitlement) => _productIdOf(entitlement) == productId)
      .firstOrNull;

  /// Ask the store to describe the product that sells [entitlement].
  Future<ProductDetails> _details(Entitlement entitlement) async {
    final id = _productIdOf(entitlement);
    final response = await _inAppPurchase.queryProductDetails({id});
    return response.productDetails.first;
  }

  /// Translate the store's purchase updates into entitlement statuses.
  ///
  /// Every purchase is completed, including ones for products this app does not
  /// recognize. A transaction that is never completed stays in the store's
  /// queue: it is redelivered on every launch, and blocks any later attempt to
  /// buy the same product.
  Stream<({Entitlement entitlement, EntitlementStatus status})>
  _processPurchases(
    Stream<List<PurchaseDetails>> purchaseStream,
  ) async* {
    await for (final purchases in purchaseStream) {
      for (final purchase in purchases) {
        final entitlement = _entitlementOf(purchase.productID);
        if (entitlement != null) {
          switch (purchase.status) {
            case PurchaseStatus.purchased || PurchaseStatus.restored:
              if (!await _verifyPurchase(purchase)) break;

              yield (
                entitlement: entitlement,
                status: EntitlementStatus.purchased,
              );

            case PurchaseStatus.pending:
              // On iOS, the pending status is emitted immediately when the native payment dialog opens.
              // On Android, it is emitted once the user has paid but the payment hasn't been verified yet.
              if (Platform.isAndroid) {
                yield (
                  entitlement: entitlement,
                  status: EntitlementStatus.pending,
                );
              }

            case PurchaseStatus.canceled:
              yield (
                entitlement: entitlement,
                status: EntitlementStatus.notPurchased,
              );

            case PurchaseStatus.error:
              debugPrint(
                "[PURCHASES] Purchasing $entitlement failed: "
                "${purchase.error?.message ?? "no message given"}",
              );
              yield (
                entitlement: entitlement,
                status: EntitlementStatus.notPurchased,
              );
          }
        }
        if (purchase.pendingCompletePurchase) {
          try {
            await _inAppPurchase.completePurchase(purchase);
          } catch (error) {
            debugPrint(
              "[PURCHASES] Unable to complete ${purchase.productID}: $error",
            );
          }
        }
      }
    }
  }

  /// Whether [purchase] is genuine and was really paid for.
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Validate purchase
    // See https://stackoverflow.com/questions/73322404/how-to-perform-the-verification-off-the-in-app-purchase
    return true;
  }

  /// Stop listening to the store and close [statusStream].
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}
