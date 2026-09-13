/// The outcome of an operation that is allowed to fail.
///
/// Switch on it to handle both cases; the compiler checks that you did:
/// ```dart
/// switch (result) {
///   case Ok(:final value): ...
///   case Failure(:final message): ...
/// }
/// ```
/// Match a specific [Failure] subtype *before* the general case to treat it
/// differently.
sealed class Result<T> {
  const Result();

  /// The operation produced [value].
  const factory Result.ok(T value) = Ok._;

  /// The operation threw.
  factory Result.failed(Object error, [StackTrace? stackTrace]) =>
      Failure._(error, stackTrace ?? StackTrace.current);

  /// The feature is switched off, so nothing was attempted.
  factory Result.unavailable(String reason) = Unavailable._;

  /// The operation was cancelled before it finished.
  factory Result.cancelled() = Cancelled._;

  /// The user is not allowed to do this, e.g. because their free allowance is
  /// used up.
  factory Result.accessRestricted() = AccessRestricted._;

  /// The value, throwing whatever went wrong if there isn't one.
  ///
  /// For when the caller cannot carry on without the value and a [Failure] is
  /// already being caught further out.
  T get asOk {
    switch (this) {
      case Failure(:final error):
        throw error;

      case Ok(:final value):
        return value;
    }
  }
}

/// The operation produced a value.
final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

/// The operation did not produce a value.
///
/// Not sealed: new kinds of failure are subtypes of this, so a caller that does
/// not care about the distinction keeps compiling.
class Failure<T> extends Result<T> {
  const Failure._(this.error, this.stackTrace);

  /// What went wrong.
  final Object error;

  /// Where it went wrong.
  final StackTrace stackTrace;

  /// What to tell the user. Subtypes override it.
  String get message => "Something went wrong. Please try again later.";

  /// Whether trying the same thing again could succeed.
  bool get isRetryable => true;
}

/// The error carried by an [Unavailable] result.
class UnavailableException implements Exception {
  @override
  String toString() => "The feature is currently unavailable";
}

/// The feature is switched off, so the request was never attempted.
///
/// Retrying will not help until the app is restarted — see [OptionalService].
final class Unavailable<T> extends Failure<T> {
  Unavailable._(this.reason)
    : super._(UnavailableException(), StackTrace.current);

  /// Why the feature is unavailable, read as the end of "This feature is
  /// currently unavailable; ...".
  final String reason;

  @override
  String get message => "This feature is currently unavailable; $reason";

  @override
  bool get isRetryable => false;
}

/// The error carried by a [Cancelled] result.
class CancelledException implements Exception {
  @override
  String toString() => "The operation was cancelled before it finished";
}

/// The operation was cancelled before it finished. See [Process.cancel].
final class Cancelled<T> extends Failure<T> {
  Cancelled._() : super._(CancelledException(), StackTrace.current);
}

/// The error carried by an [AccessRestricted] result.
class AccessRestrictedException implements Exception {
  const AccessRestrictedException([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? "Access restricted";
  }
}

/// The user is not allowed to do this, e.g. because their free allowance is used
/// up. Retrying without buying premium or waiting will not help.
final class AccessRestricted<T> extends Failure<T> {
  AccessRestricted._()
    : super._(AccessRestrictedException(), StackTrace.current);
}
