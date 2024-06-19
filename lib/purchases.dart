import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:musbx/music_player/exception_dialogs.dart';

class Purchases {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Whether the payment platform is ready and available.
  static late final bool isAvailable;

  /// ID of the 'premium' product.
  static const String _premiumID = "premium";

  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  static bool get hasPremium => hasPremiumNotifier.value;
  static final ValueNotifier<bool> hasPremiumNotifier = ValueNotifier(false);

  static Future<void> intialize() async {
    isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) return;

    _inAppPurchase.purchaseStream.listen((newPurchases) async {
      for (PurchaseDetails purchase in newPurchases) {
        await _processPurchase(purchase);
      }
    });

    await _inAppPurchase.restorePurchases();
  }

  static Future<void> _processPurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (!await _verifyPurchase(purchase)) break;

        switch (purchase.productID) {
          case _premiumID:
            debugPrint("[PURCHASES] Premium features unlocked");
            hasPremiumNotifier.value = true;
            break;
        }
        break;

      case PurchaseStatus.pending:
        switch (purchase.productID) {
          case _premiumID:
            showExceptionDialog(const PremiumPurchasedDialog());
            break;
        }
        break;

      default:
    }

    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  static Future<bool> buyPremium() async {
    final response = await _inAppPurchase.queryProductDetails({_premiumID});
    final ProductDetails? details = response.productDetails.firstOrNull;
    if (details == null) return false;

    return await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  static Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Validate purchase
    // See https://stackoverflow.com/questions/73322404/how-to-perform-the-verification-off-the-in-app-purchase
    return true;
  }
}
