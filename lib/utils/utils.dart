import 'package:flutter/material.dart';

extension IfNotNull<T extends Object?> on T {
  /// Returns `null` if this is `null`, and [value] otherwise.
  S? ifNotNull<S>(S value) => this == null ? null : value;
}

Type typeOf<T>() => T;

typedef Json = Map<String, dynamic>;

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
