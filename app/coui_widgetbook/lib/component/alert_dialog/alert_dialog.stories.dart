import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'alert_dialog.stories.g.dart';

/// Opens a confirmation dialog without blocking the catalog on initial render.
class AlertDialogDemo extends StatelessWidget {
  /// Creates an [AlertDialogDemo].
  const AlertDialogDemo({
    super.key,
    this.title = 'Confirm Action',
    this.message = 'Are you sure you want to proceed with this action?',
    this.showCancelButton = false,
    this.destructive = false,
  });

  /// Dialog title text.
  final String title;

  /// Dialog body message text.
  final String message;

  /// Whether a cancel button is shown before the confirm button.
  final bool showCancelButton;

  /// Whether the confirm action is destructive.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Button(
        onPressed: () => unawaited(
          showDialog<void>(
            context: context,
            builder: (dialogContext) => Dialog(
              title: Text(title),
              content: Text(message),
              leading: Icon(
                destructive ? LucideIcons.triangleAlert : LucideIcons.info,
              ),
              actions: [
                if (showCancelButton)
                  Button(
                    onPressed: () => Navigator.pop(dialogContext),
                    variant: .ghost,
                    child: const Text('Cancel'),
                  ),
                if (destructive)
                  Button(
                    onPressed: () => Navigator.pop(dialogContext),
                    variant: .destructive,
                    child: const Text('Delete'),
                  )
                else
                  Button(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Confirm'),
                  ),
              ],
            ),
          ),
        ),
        child: const Text('Show Confirmation'),
      ),
    );
  }
}

/// Navigation metadata for the AlertDialog component.
const kComponentMeta = ComponentMeta(name: 'AlertDialog', path: 'overlay');

/// Story metadata for [AlertDialogDemo].
const kMeta = Meta(AlertDialogDemo.new);

/// Confirm dialog with editable knobs.
final $Default = _Story();

/// Destructive confirm dialog with a cancel button.
final $Destructive = _Story(
  args: _Args(
    showCancelButton: BoolArg(true),
    // distinct story knobs share the same value.
    destructive: BoolArg(true),
  ),
);
