# Alert Dialog Examples

This document contains example code for the alert_dialog component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class AlertDialogExample1 extends StatelessWidget {
  const AlertDialogExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: Text(t.docs.components.alert_dialog.click_here),
      onPressed: () {
        showDialog(
          builder: (context) {
            return AlertDialog(
              actions: [
                OutlineButton(
                  child: Text(t.docs.common.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.components.dialog.ok),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
              content: Text(t.docs.components.alert_dialog.alert_content),
              title: Text(t.docs.components.alert_dialog.alert_title),
            );
          },
          context: context,
        );
      },
    );
  }
}

```

