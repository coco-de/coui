import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';

typedef FutureOrWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
);

class FutureOrBuilder<T> extends StatelessWidget {
  const FutureOrBuilder({
    required this.builder,
    required this.future,
    this.initialValue,
    super.key,
  });

  final FutureOr<T> future;
  final FutureOrWidgetBuilder<T> builder;

  final T? initialValue;

  @override
  Widget build(BuildContext context) {
    return future is Future<T>
        ? FutureBuilder<T>(
            builder: builder,
            future: future as Future<T>,
            initialData: initialValue,
          )
        : builder(
            context,
            AsyncSnapshot.withData(ConnectionState.done, future as T),
          );
  }
}
