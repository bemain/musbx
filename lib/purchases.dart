import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Whether the payment platform is ready and available.
  static late final bool isAvailable;

  static List<PurchaseDetails> get purchases => purchasesNotifier.value;
  static final ValueNotifier<List<PurchaseDetails>> purchasesNotifier =
      ValueNotifier([]);

  static Future<void> intialize() async {
    isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) return;

    _inAppPurchase.purchaseStream.listen((newPurchases) async {
      for (var purchase in newPurchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          if (await _verifyPurchase(purchase)) {
            purchasesNotifier.value = [...purchases, purchase];
          }
        }
      }
    });

    await _inAppPurchase.restorePurchases();
  }

  static Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // FIXME: Validate purchase
    return true;
  }
}
