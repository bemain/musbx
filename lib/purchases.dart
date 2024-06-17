import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Whether the payment platform is ready and available.
  static late final bool isAvailable;

  /// ID of the 'premium' product.
  static const String _premiumID = "premium";

  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  /// TODO: Show dialog when the user has paid and the payment is pending, and when 'premium' has been activated.
  static bool get hasPremium => hasPremiumNotifier.value;
  static final ValueNotifier<bool> hasPremiumNotifier = ValueNotifier(false);

  static Future<void> intialize() async {
    isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) return;

    _inAppPurchase.purchaseStream.listen((newPurchases) async {
      for (PurchaseDetails purchase in newPurchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          if (await _verifyPurchase(purchase)) {
            _onPurchase(purchase);
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    });

    await _inAppPurchase.restorePurchases();
  }

  static void _onPurchase(PurchaseDetails purchase) {
    switch (purchase.productID) {
      case _premiumID:
        debugPrint("[PURCHASES] Premium features unlocked");
        hasPremiumNotifier.value = true;
        break;
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
    // FIXME: Validate purchase
    return true;
  }
}
