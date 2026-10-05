import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/entitlement.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

/// Tracks entitlements through the store, restoring previous purchases as soon
/// as the store is reached.
///
/// On platforms without a store there is nothing to sell, so everything is
/// unlocked. Until it is known whether there is one, nothing is.
class EntitlementRepositoryRemote extends EntitlementRepository {
  EntitlementRepositoryRemote({
    required ServiceLoader<PurchaseService> purchase,
  }) : _purchase = purchase {
    _unbind = purchase.bind(_attach);
  }

  final ServiceLoader<PurchaseService> _purchase;
  late final VoidCallback _unbind;
  StreamSubscription<({Entitlement entitlement, EntitlementStatus status})>?
  _subscription;

  bool _isBuyingPremium = false;
  bool _hasPremium = false;

  @override
  bool get hasPremium => _hasPremium;

  void _attach(PurchaseService service) {
    unawaited(_subscription?.cancel());
    _subscription = null;

    if (!service.isEnabled) {
      if (_purchase.availability == ServiceAvailability.unsupported) {
        debugPrint("[PURCHASES] The current platform is not supported");
        _hasPremium = true;
        notifyListeners();
      }
      return;
    }

    _subscription = service.statusStream.listen(
      (record) => _processStatus(record.entitlement, record.status),
    );

    unawaited(restore());
  }

  @override
  void dispose() {
    _unbind();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Future<Result<void>> restore() async {
    return OptionalService.guard(
      () => _purchase.value.restore(),
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
        await _purchase.value.buy(Entitlement.premium),
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
