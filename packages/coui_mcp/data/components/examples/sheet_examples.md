# Sheet Examples

This document contains example code for the sheet component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SheetExample1 extends StatefulWidget {
  const SheetExample1({super.key});

  @override
  State<SheetExample1> createState() => _SheetExample1State();
}

class _SheetExample1State extends State<SheetExample1> {
  final FormController controller = FormController();

  void saveProfile() {
    showDialog(
      builder: (context) {
        return AlertDialog(
          actions: [
            PrimaryButton(
              child: Text(t.docs.common.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
          content: Text(
            'Profile saved with values: ${controller.values.toString()}',
          ),
          title: const Text('Profile Updated'),
        );
      },
      context: context,
    );
  }

  Widget buildSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        controller: controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    t.docs.components.dialog.edit_profile_title,
                  ).lg().md(),
                ),
                TextButton(
                  onPressed: () {
                    closeSheet(context);
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const Gap(size: 8),
            Text(
              t.docs.components.dialog.edit_profile_description,
            ).baseContent(),
            const Gap(size: 16),
            FormTableLayout(
              rows: [
                FormField<String>(
                  key: const FormKey(#name),
                  label: Text(t.docs.components.dialog.name_label),
                  validator:
                      const NotEmptyValidator() & const LengthValidator(min: 4),
                  child: const TextField(
                    initialValue: 'Thito Yalasatria Sunarya',
                    placeholder: Text('Your full name'),
                  ),
                ),
                FormField<String>(
                  key: const FormKey(#username),
                  label: Text(t.docs.components.dialog.username_label),
                  validator:
                      const NotEmptyValidator() & const LengthValidator(min: 4),
                  child: const TextField(
                    initialValue: '@coco-de',
                    placeholder: Text('Your username'),
                  ),
                ),
              ],
            ),
            const Gap(size: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FormErrorBuilder(
                builder: (context, errors, child) {
                  return PrimaryButton(
                    onPressed: errors.isNotEmpty
                        ? null
                        : () {
                            context.submitForm().then((value) {
                              if (value.errors.isEmpty) {
                                closeSheet(context).then((value) {
                                  saveProfile();
                                });
                              }
                            });
                          },
                    child: Text(t.docs.components.button.save_changes),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Open Sheet'),
      onPressed: () {
        openSheet(
          builder: (context) {
            return buildSheet(context);
          },
          context: context,
          position: OverlayPosition.end,
        );
      },
    );
  }
}

```

