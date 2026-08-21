import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/entitlement.dart';

/// Sells the app's [Entitlement]s through the store the app was installed from.
///
/// Purchases are optional. [disabled] returns a service that sells nothing, for
/// platforms with no store and for devices where the store cannot be reached.
///
/// This reports what the store says but does not remember it. Which
/// entitlements the user currently holds is app state, and belongs to the layer
/// above.
class PurchaseService extends OptionalService {
  PurchaseService._(
    this._inAppPurchase,
  ) {
    final purchases = _inAppPurchase?.purchaseStream;
    if (purchases == null) return;

    _subscription = _processPurchases(purchases).listen(
      _statusController.add,
      onError: (Object error) {
        debugPrint("[PURCHASES] Purchase stream error: $error");
      },
    );
  }

  @override
  bool get isEnabled => _inAppPurchase != null;

  /// The store connection, or `null` when this service is [disabled].
  final InAppPurchase? _inAppPurchase;

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

  /// A service that sells nothing, for when no store is available.
  static PurchaseService disabled() => PurchaseService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final PurchaseService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  final _statusController =
      StreamController<
        (Entitlement entitlement, EntitlementStatus status)
      >.broadcast();
  StreamSubscription<(Entitlement, EntitlementStatus)>? _subscription;

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
  Stream<(Entitlement entitlement, EntitlementStatus status)>
  get statusStream => _statusController.stream;

  /// Restore purchases the user has already made, for example after
  /// reinstalling the app.
  ///
  /// Anything restored arrives on [statusStream] rather than being returned.
  /// Does nothing when this service is [disabled].
  Future<void> restore() async {
    await _inAppPurchase?.restorePurchases();
  }

  /// Look up how [entitlement] is presented to the user.
  ///
  /// Returns `null` when this service is disabled, when the entitlement is not
  /// for sale, and when the store cannot be reached.
  Future<EntitlementDetails?> details(Entitlement entitlement) async {
    if (_inAppPurchase == null) return null;

    final details = await _details(entitlement);
    if (details == null) return null;

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
  Future<bool> buy(Entitlement entitlement) async {
    if (_inAppPurchase == null) return false;

    final d = await _details(entitlement);
    if (d == null) return false;

    return await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: d),
    );
  }

  /// The store product that sells each entitlement.
  ///
  /// Product ids identify the entitlement to the store and never leave this
  /// service; the rest of the app deals in [Entitlement].
  final Map<Entitlement, String> _productIds = {
    Entitlement.premium: "premium",
  };

  String? _entitlementToProduct(Entitlement entitlement) =>
      _productIds[entitlement];

  Entitlement? _productToEntitlement(String productId) =>
      _productIds.keys.where((k) => _productIds[k] == productId).firstOrNull;

  /// Ask the store to describe the product that sells [entitlement].
  Future<ProductDetails?> _details(Entitlement entitlement) async {
    if (_inAppPurchase == null) return null;

    final id = _entitlementToProduct(entitlement);
    if (id == null) return null;
    final response = await _inAppPurchase.queryProductDetails({id});
    return response.productDetails.firstOrNull;
  }

  /// Translate the store's purchase updates into entitlement statuses.
  ///
  /// Every purchase is completed, including ones for products this app does not
  /// recognize. A transaction that is never completed stays in the store's
  /// queue: it is redelivered on every launch, and blocks any later attempt to
  /// buy the same product.
  Stream<(Entitlement, EntitlementStatus)> _processPurchases(
    Stream<List<PurchaseDetails>> purchaseStream,
  ) async* {
    await for (final purchases in purchaseStream) {
      for (final purchase in purchases) {
        final entitlement = _productToEntitlement(purchase.productID);
        if (entitlement != null) {
          switch (purchase.status) {
            case PurchaseStatus.purchased || PurchaseStatus.restored:
              if (!await _verifyPurchase(purchase)) break;

              yield (entitlement, EntitlementStatus.purchased);

            case PurchaseStatus.pending:
              // On iOS, the pending status is emitted immediately when the native payment dialog opens.
              // On Android, it is emitted once the user has paid but the payment hasn't been verified yet.
              if (Platform.isAndroid) {
                yield (entitlement, EntitlementStatus.pending);
              }

            case PurchaseStatus.canceled:
              yield (entitlement, EntitlementStatus.notPurchased);

            case PurchaseStatus.error:
              debugPrint(
                "[PURCHASES] Purchasing $entitlement failed: "
                "${purchase.error?.message ?? "no message given"}",
              );
              yield (entitlement, EntitlementStatus.notPurchased);
          }
        }
        if (purchase.pendingCompletePurchase) {
          try {
            await _inAppPurchase?.completePurchase(purchase);
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
