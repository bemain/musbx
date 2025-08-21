import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class AccessRestrictedException implements Exception {
  /// An exception thrown when access to a feature is restricted,
  /// such as when the user has used up their free songs.
  const AccessRestrictedException([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? "Access restricted";
  }
}

class Purchases {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Whether the payment platform is ready and available.
  static bool isAvailable = false;

  /// ID of the 'premium' product.
  static const String _premiumID = "premium";

  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  static bool get hasPremium => hasPremiumNotifier.value;
  static final ValueNotifier<bool> hasPremiumNotifier = ValueNotifier(false);

  static Future<void> intialize() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      debugPrint("[PURCHASES] The current platform is not supported");
      isAvailable = false;
      hasPremiumNotifier.value = true;
      return;
    }

    try {
      isAvailable = await _inAppPurchase.isAvailable();
    } catch (e) {
      debugPrint("[PURCHASES] An error occured during intialization: $e");
      isAvailable = false;
    }

    if (!isAvailable) {
      // Payments are only supported on mobile. On other platforms, simply enable premium.
      hasPremiumNotifier.value = true;
      return;
    }

    _inAppPurchase.purchaseStream.listen((newPurchases) async {
      for (PurchaseDetails purchase in newPurchases) {
        await _processPurchase(purchase);
      }
    });

    await _inAppPurchase.restorePurchases();
  }

  /// Restore all previous purchases.
  static Future<void> restore() async {
    if (!isAvailable) return;
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
        }

      case PurchaseStatus.pending:
        // On iOS, the pending status is emitted immediately when the native payment dialog opens.
        // On Android, it is emitted once the user has paid but the payment hasn't been verified yet.s
        switch (purchase.productID) {
          case _premiumID:
            if (Platform.isAndroid) {
              unawaited(
                showExceptionDialog(const PremiumPurchasedDialog()),
              );
            }
        }

      case PurchaseStatus.canceled:
        break;
      case PurchaseStatus.error:
        switch (purchase.productID) {
          case _premiumID:
            debugPrint(
              "[PURCHASES] Buying Premium failed: ${purchase.error?.message ?? "Cancelled"}",
            );
            unawaited(
              showExceptionDialog(const PremiumPurchaseFailedDialog()),
            );
        }
    }

    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  static Future<bool> buyPremium() async {
    if (!isAvailable) return false;

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
