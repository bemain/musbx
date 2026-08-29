import 'package:flutter/widgets.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/widgets.dart';

class ResultBuilder<T> extends StatelessWidget {
  const ResultBuilder({
    super.key,
    required this.future,
    this.loading,
    required this.ok,
    this.failure,
  });

  final Future<Result<T>> future;

  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, T value) ok;
  final Widget Function(BuildContext context, Object error)? failure;

  @override
  Widget build(BuildContext context) {
    final loading = this.loading ?? (_) => LoadingPage(text: "Loading...");
    final failure = this.failure ?? (_, e) => ErrorPage(text: "$e");

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return failure(context, snapshot.error!);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return loading(context);
        }

        switch (snapshot.requireData) {
          case Ok<T>(:final value):
            return ok(context, value);

          case Failure(:final error):
            return failure(context, error);
        }
      },
    );
  }
}
