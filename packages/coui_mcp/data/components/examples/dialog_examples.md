# Dialog Examples

This document contains example code for the dialog component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DialogExample1 extends StatelessWidget {
  const DialogExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: Text(t.docs.components.button.edit_profile),
      onPressed: () {
        showDialog(
          builder: (context) {
            final FormController controller = FormController();
            return AlertDialog(
              actions: [
                PrimaryButton(
                  child: Text(t.docs.components.button.save_changes),
                  onPressed: () {
                    Navigator.of(context).pop(controller.values);
                  },
                ),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.docs.components.dialog.edit_profile_description),
                  const Gap(size: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      controller: controller,
                      child: FormTableLayout(
                        rows: [
                          FormField<String>(
                            key: const FormKey(#name),
                            label: Text(t.docs.components.dialog.name_label),
                            child: const TextField(
                              autofocus: true,
                              initialValue: 'Thito Yalasatria Sunarya',
                            ),
                          ),
                          FormField<String>(
                            key: const FormKey(#username),
                            label: Text(
                              t.docs.components.dialog.username_label,
                            ),
                            child: const TextField(
                              initialValue: '@sunaryathito',
                            ),
                          ),
                        ],
                      ),
                    ).withPadding(vertical: 16),
                  ),
                ],
              ),
              title: Text(t.docs.components.dialog.edit_profile_title),
            );
          },
          context: context,
        );
      },
    );
  }
}

```

