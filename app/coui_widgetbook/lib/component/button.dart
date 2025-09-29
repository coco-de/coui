import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'primary',
  type: coui.Button,
)
Widget buildButtonPrimaryUseCase(BuildContext context) {
  return coui.Button.primary(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.add)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Primary', label: 'text')),
  );
}

@UseCase(
  name: 'secondary',
  type: coui.Button,
)
Widget buildButtonSecondaryUseCase(BuildContext context) {
  return coui.Button.secondary(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.add)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Secondary', label: 'text')),
  );
}

@UseCase(
  name: 'outline',
  type: coui.Button,
)
Widget buildButtonOutlineUseCase(BuildContext context) {
  return coui.Button.outline(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.add)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Outline', label: 'text')),
  );
}

@UseCase(
  name: 'ghost',
  type: coui.Button,
)
Widget buildButtonGhostUseCase(BuildContext context) {
  return coui.Button.ghost(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.add)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Ghost', label: 'text')),
  );
}

@UseCase(
  name: 'link',
  type: coui.Button,
)
Widget buildButtonLinkUseCase(BuildContext context) {
  return coui.Button.link(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.add)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Link', label: 'text')),
  );
}

@UseCase(
  name: 'destructive',
  type: coui.Button,
)
Widget buildButtonDestructiveUseCase(BuildContext context) {
  return coui.Button.destructive(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    leading: context.knobs.boolean(initialValue: false, label: 'leading icon')
        ? const Icon(Icons.delete)
        : null,
    onPressed: () => print('Button pressed'),
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(
      context.knobs.string(initialValue: 'Destructive', label: 'text'),
    ),
  );
}
