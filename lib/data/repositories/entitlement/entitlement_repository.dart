import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository_remote.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/utils/result.dart';

abstract class EntitlementRepository extends ChangeNotifier {
  // TODO: Remove once we introduce `provider`.
  static final EntitlementRepository instance = EntitlementRepositoryRemote(
    purchaseService: PurchaseService.instance,
  );

  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  bool get hasPremium;

  @useResult
  Future<Result<bool>> buyPremium();

  /// Restore all previous purchases.
  @useResult
  Future<Result<void>> restore();
}
