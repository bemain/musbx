import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/utils/result.dart';

/// What the user has paid for.
abstract class EntitlementRepository extends ChangeNotifier {
  /// Whether the user has bought the 'premium' product that unlocks access to premium features of the app.
  bool get hasPremium;

  /// Take the user through buying premium. Returns whether they went through
  /// with it.
  @useResult
  Future<Result<bool>> buyPremium();

  /// Restore all previous purchases.
  @useResult
  Future<Result<void>> restore();
}
