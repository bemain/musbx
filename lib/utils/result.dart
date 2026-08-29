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

  const factory Result.ok(T value) = Ok._;

  factory Result.failed(Object error, [StackTrace? stackTrace]) =>
      Failure._(error, stackTrace ?? StackTrace.current);

  factory Result.unavailable(String reason) = Unavailable._;

  factory Result.cancelled() = Cancelled._;
}

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
  final Object error;
  final StackTrace stackTrace;

  /// What to tell the user. Subtypes override it.
  String get message => "Something went wrong. Please try again later.";

  /// Whether trying the same thing again could succeed.
  bool get isRetryable => true;
}

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

  final String reason;

  @override
  String get message => "This feature is currently unavailable; $reason";

  @override
  bool get isRetryable => false;
}

class CancelledException implements Exception {
  @override
  String toString() => "The operation was cancelled before it finished";
}

/// The operation was cancelled before it finished. See [Process.cancel].
final class Cancelled<T> extends Failure<T> {
  Cancelled._() : super._(CancelledException(), StackTrace.current);
}
