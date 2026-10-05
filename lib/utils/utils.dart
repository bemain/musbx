import 'package:flutter/material.dart';

extension IfNotNull<T extends Object?> on T {
  /// Returns `null` if this is `null`, and [value] otherwise.
  S? ifNotNull<S>(S value) => this == null ? null : value;
}

/// The [Type] of [T], including its type arguments.
Type typeOf<T>() => T;

/// A decoded JSON object.
typedef Json = Map<String, dynamic>;

/// Show a modal bottom sheet that stays clear of the on-screen keyboard.
///
/// Completes with whatever the sheet is popped with, or `null` if it is
/// dismissed.
Future<T?> showAlertSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool showDragHandle = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: showDragHandle,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: builder(context),
      );
    },
  );
}
