import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A simple dialog example use case.
@UseCase(
  name: 'simple',
  type: Center,
)
Widget buildDialogSimpleUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showDialog(
          builder: (context) => coui.AlertDialog(
            actions: [
              coui.Button.secondary(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              coui.Button.primary(
                onPressed: () {
                  // ignore: avoid_print
                  print('Confirmed');
                  Navigator.of(context).pop();
                },
                child: const Text('Confirm'),
              ),
            ],
            content: const Text('Are you sure you want to continue?'),
            title: const Text('Confirmation'),
          ),
          context: context,
        );
      },
      child: const Text('Show Dialog'),
    ),
  );
}

/// A dialog with long content use case.
@UseCase(
  name: 'long content',
  type: Center,
)
Widget buildDialogLongContentUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showDialog(
          builder: (context) => coui.AlertDialog(
            actions: [
              coui.Button.primary(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
            content: const SingleChildScrollView(
              child: Text(
                'This is a very long content that demonstrates how the dialog handles '
                'scrolling when the content exceeds the available space. '
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. '
                'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum. '
                'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.',
              ),
            ),
            title: const Text('Long Content Dialog'),
          ),
          context: context,
        );
      },
      child: const Text('Show Long Dialog'),
    ),
  );
}

/// A destructive dialog use case.
@UseCase(
  name: 'destructive',
  type: Center,
)
Widget buildDialogDestructiveUseCase(BuildContext context) {
  return Center(
    child: coui.Button.destructive(
      onPressed: () {
        coui.showDialog(
          builder: (context) => coui.AlertDialog(
            actions: [
              coui.Button.secondary(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              coui.Button.destructive(
                onPressed: () {
                  // ignore: avoid_print
                  print('Deleted');
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this item?',
            ),
            title: const Text('Delete Item'),
          ),
          context: context,
        );
      },
      child: const Text('Show Delete Dialog'),
    ),
  );
}

/// A dialog without title use case.
@UseCase(
  name: 'no title',
  type: Center,
)
Widget buildDialogNoTitleUseCase(BuildContext context) {
  return Center(
    child: coui.Button.primary(
      onPressed: () {
        coui.showDialog(
          builder: (context) => coui.AlertDialog(
            actions: [
              coui.Button.primary(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
            content: const Text('This dialog has no title, only content.'),
          ),
          context: context,
        );
      },
      child: const Text('Show Titleless Dialog'),
    ),
  );
}
