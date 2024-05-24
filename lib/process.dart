import 'package:flutter/material.dart';

/// A helper class for handling lengthy tasks.
/// Features progress tracking, cancellation and automatic error handling.
abstract class Process<T> {
  /// The future that completes with this task.
  late final Future<T> future = _processAndReportErrors();

  /// The progress of the process.
  /// Should be a fraction between 0 and 1.
  double? get progress => progressNotifier.value;
  final ValueNotifier<double?> progressNotifier = ValueNotifier(null);

  /// Whether this process has encountered an error.
  bool get hasError => error != null;

  /// The error encountered by this process, if any.
  Object? get error => errorNotifier.value;
  final ValueNotifier<Object?> errorNotifier = ValueNotifier(null);

  /// Whether this process has been cancelled.
  bool get isCancelled => isCancelledNotifier.value;
  set isCancelled(bool value) => isCancelledNotifier.value = value;
  final ValueNotifier<bool> isCancelledNotifier = ValueNotifier(false);

  /// Start the [process] and catch any errors that occur.
  Future<T> _processAndReportErrors() async {
    try {
      return await process();
    } catch (e) {
      errorNotifier.value = e;
      rethrow;
    }
  }

  /// The method that this process executes.
  Future<T> process();
}
