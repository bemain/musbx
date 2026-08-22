import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/domain/models/entitlement.dart';
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
  /// Whether the payment platform is ready and available.
  static bool isAvailable = false;

  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  static bool get hasPremium => hasPremiumNotifier.value;
  static final ValueNotifier<bool> hasPremiumNotifier = ValueNotifier(false);

  static Future<void> intialize() async {
    if (!PurchaseService.instance.isEnabled) {
      debugPrint("[PURCHASES] The current platform is not supported");
      isAvailable = false;
      hasPremiumNotifier.value = true;
      return;
    }

    PurchaseService.instance.statusStream.listen(
      (record) => _processStatus(record.entitlement, record.status),
    );

    await restore();
  }

  /// Restore all previous purchases.
  static Future<void> restore() => PurchaseService.instance.restore();

  static Future<void> _processStatus(
    Entitlement entitlement,
    EntitlementStatus status,
  ) async {
    switch (entitlement) {
      case Entitlement.premium:
        switch (status) {
          case EntitlementStatus.purchased:
            debugPrint("[PURCHASES] Premium features unlocked");
            hasPremiumNotifier.value = true;
            if (Platform.isIOS) {
              unawaited(
                showExceptionDialog(const PremiumPurchasedDialog()),
              );
            }

          case EntitlementStatus.pending:
            // On iOS, the pending status is emitted immediately when the native payment dialog opens.
            // On Android, it is emitted once the user has paid but the payment hasn't been verified yet.
            switch (entitlement) {
              case Entitlement.premium:
                if (Platform.isAndroid) {
                  unawaited(
                    showExceptionDialog(const PremiumPurchasedDialog()),
                  );
                }
            }

          default:
        }
    }
  }

  static Future<bool> buyPremium() =>
      PurchaseService.instance.buy(Entitlement.premium);
}
