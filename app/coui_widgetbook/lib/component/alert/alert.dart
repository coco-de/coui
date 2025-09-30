import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Alert] use case.
@UseCase(
  name: 'default',
  type: coui.Alert,
)
Widget buildAlertDefaultUseCase(BuildContext context) {
  return coui.Alert(
    leading: context.knobs.boolean(initialValue: true, label: 'show leading')
        ? const Icon(Icons.info_outline)
        : null,
    title: context.knobs.boolean(initialValue: true, label: 'show title')
        ? Text(context.knobs.string(initialValue: 'Alert Title', label: 'title'))
        : null,
    content:
        context.knobs.boolean(initialValue: true, label: 'show content')
            ? Text(context.knobs.string(
                initialValue: 'This is an informational alert message.',
                label: 'content'))
            : null,
    trailing:
        context.knobs.boolean(initialValue: false, label: 'show trailing')
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              )
            : null,
  );
}

/// A destructive [coui.Alert] use case.
@UseCase(
  name: 'destructive',
  type: coui.Alert,
)
Widget buildAlertDestructiveUseCase(BuildContext context) {
  return coui.Alert.destructive(
    leading: const Icon(Icons.error_outline),
    title: const Text('Error'),
    content: const Text('Something went wrong. Please try again.'),
    trailing: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {},
    ),
  );
}

/// A success [coui.Alert] use case.
@UseCase(
  name: 'success',
  type: coui.Alert,
)
Widget buildAlertSuccessUseCase(BuildContext context) {
  return coui.Alert(
    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
    title: const Text('Success'),
    content: const Text('Your changes have been saved successfully.'),
  );
}

/// A warning [coui.Alert] use case.
@UseCase(
  name: 'warning',
  type: coui.Alert,
)
Widget buildAlertWarningUseCase(BuildContext context) {
  return coui.Alert(
    leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
    title: const Text('Warning'),
    content: const Text('This action cannot be undone.'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        const SizedBox(width: 8),
        TextButton(onPressed: () {}, child: const Text('Proceed')),
      ],
    ),
  );
}