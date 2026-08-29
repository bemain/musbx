import 'package:flutter/foundation.dart';
import 'package:musbx/utils/result.dart';

/// Thrown when something is asked of a service that has nothing behind it.
///
/// Says nothing about the request itself. The feature is absent on this device
/// and stays absent for the rest of the process, so retrying cannot help.
/// [OptionalService.guard] turns this into [Result.unavailable]; nothing above a
/// repository should have to catch it.
final class ServiceDisabled implements Exception {
  @override
  String toString() => "This service is currently disabled";
}

/// A service that may not be there at all.
///
/// Some services have nothing behind them on some devices: a platform with no
/// notifications, no store, no ad SDK, or credentials that could not be
/// obtained. Rather than each method degrading in its own way, a disabled
/// service throws [ServiceDisabled] from everything that needs what it is
/// missing.
abstract class OptionalService {
  /// Whether this service is currently active.
  ///
  /// Decided when the service is created and fixed for its lifetime, so it is
  /// safe to read once rather than before every call.
  bool get isEnabled;

  /// Refuse to go on when there is nothing behind this service.
  ///
  /// Called from the accessor that hands out the missing handle, so every method
  /// needing it is covered without repeating the check in each one.
  @protected
  void throwIfDisabled() {
    if (!isEnabled) throw ServiceDisabled();
  }

  /// Run [body] and report what happened as a [Result].
  ///
  /// The translation every repository over an optional service needs: a value
  /// becomes [Result.ok], a [ServiceDisabled] becomes [Result.unavailable]
  /// carrying [reason], and anything else thrown becomes [Result.failed].
  ///
  /// [reason] reaches the user through [Unavailable.message], so it should read
  /// as the end of "This feature is currently unavailable; ...".
  static Future<Result<T>> guard<T>(
    Future<T> Function() body,
    String reason,
  ) async {
    try {
      return Result.ok(await body());
    } on ServiceDisabled catch (_) {
      return Result.unavailable(reason);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
