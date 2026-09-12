import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/entitlement.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class EntitlementRepositoryRemote extends EntitlementRepository {
  EntitlementRepositoryRemote({required PurchaseService purchaseService})
    : _purchaseService = purchaseService {
    if (!_purchaseService.isEnabled) {
      debugPrint("[PURCHASES] The current platform is not supported");
      _hasPremium = true;
      notifyListeners();
      return;
    }

    PurchaseService.instance.statusStream.listen(
      (record) => _processStatus(record.entitlement, record.status),
    );

    unawaited(restore());
  }

  final PurchaseService _purchaseService;

  bool _isBuyingPremium = false;
  bool _hasPremium = false;

  @override
  bool get hasPremium => _hasPremium;

  @override
  Future<Result<void>> restore() async {
    return OptionalService.guard(
      _purchaseService.restore,
      "In app purchase service disabled",
    );
  }

  Future<void> _processStatus(
    Entitlement entitlement,
    EntitlementStatus status,
  ) async {
    switch (entitlement) {
      case Entitlement.premium:
        switch (status) {
          case EntitlementStatus.purchased:
            if (hasPremium) return;

            debugPrint("[PURCHASES] Premium features unlocked");
            _hasPremium = true;
            notifyListeners();
            if (Platform.isIOS && _isBuyingPremium) {
              unawaited(
                showExceptionDialog(const PremiumPurchasedDialog()),
              );
            }
            _isBuyingPremium = false;

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

          case EntitlementStatus.notPurchased:
            switch (entitlement) {
              case Entitlement.premium:
                unawaited(
                  showExceptionDialog(const PremiumPurchaseFailedDialog()),
                );
            }
        }
    }
  }

  @override
  Future<Result<bool>> buyPremium() async {
    if (hasPremium) return Result.ok(true);
    _isBuyingPremium = true;

    try {
      return Result.ok(
        await _purchaseService.buy(Entitlement.premium),
      );
    } on ServiceDisabled catch (_) {
      _isBuyingPremium = false;
      return Result.unavailable("In app purchase service disabled");
    } catch (e, s) {
      _isBuyingPremium = false;
      return Result.failed(e, s);
    }
  }
}
