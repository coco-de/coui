import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default toast example use case.
@UseCase(
  name: 'default',
  type: Center,
)
Widget buildToastDefaultUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showToast(
          context: context,
          builder: (ctx, overlay) => coui.SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.knobs.string(
                initialValue: 'This is a toast message',
                label: 'message',
              ),
            ),
          ),
        );
        debugPrint('Toast shown');
      },
      child: const Text('Show Toast'),
    ),
  );
}

/// A success toast example use case.
@UseCase(
  name: 'success',
  type: Center,
)
Widget buildToastSuccessUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showToast(
          context: context,
          builder: (ctx, overlay) => const coui.SurfaceCard(
            padding: EdgeInsets.all(16),
            child: Text('Operation completed successfully!'),
          ),
        );
        debugPrint('Success toast shown');
      },
      child: const Text('Show Success Toast'),
    ),
  );
}

/// An error toast example use case.
@UseCase(
  name: 'error',
  type: Center,
)
Widget buildToastErrorUseCase(BuildContext context) {
  return Center(
    child: coui.Button.destructive(
      onPressed: () {
        coui.showToast(
          context: context,
          builder: (ctx, overlay) => const coui.SurfaceCard(
            padding: EdgeInsets.all(16),
            child: Text('An error occurred. Please try again.'),
          ),
        );
        debugPrint('Error toast shown');
      },
      child: const Text('Show Error Toast'),
    ),
  );
}

/// A toast with action use case.
@UseCase(
  name: 'with action',
  type: Center,
)
Widget buildToastWithActionUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showToast(
          context: context,
          builder: (ctx, overlay) => const coui.SurfaceCard(
            padding: EdgeInsets.all(16),
            child: Text('Item deleted'),
          ),
        );
        debugPrint('Action toast shown');
      },
      child: const Text('Show Toast with Action'),
    ),
  );
}

/// A long message toast use case.
@UseCase(
  name: 'long message',
  type: Center,
)
Widget buildToastLongMessageUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showToast(
          context: context,
          builder: (ctx, overlay) => const coui.SurfaceCard(
            padding: EdgeInsets.all(16),
            child: Text(
              'This is a much longer toast message that might wrap to multiple lines depending on the screen width.',
            ),
          ),
        );
        debugPrint('Long toast shown');
      },
      child: const Text('Show Long Toast'),
    ),
  );
}
