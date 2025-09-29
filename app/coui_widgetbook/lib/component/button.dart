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
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.add)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Primary')),
  );
}

@UseCase(
  name: 'secondary',
  type: coui.Button,
)
Widget buildButtonSecondaryUseCase(BuildContext context) {
  return coui.Button.secondary(
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.add)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Secondary')),
  );
}

@UseCase(
  name: 'outline',
  type: coui.Button,
)
Widget buildButtonOutlineUseCase(BuildContext context) {
  return coui.Button.outline(
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.add)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Outline')),
  );
}

@UseCase(
  name: 'ghost',
  type: coui.Button,
)
Widget buildButtonGhostUseCase(BuildContext context) {
  return coui.Button.ghost(
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.add)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Ghost')),
  );
}

@UseCase(
  name: 'link',
  type: coui.Button,
)
Widget buildButtonLinkUseCase(BuildContext context) {
  return coui.Button.link(
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.add)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Link')),
  );
}

@UseCase(
  name: 'destructive',
  type: coui.Button,
)
Widget buildButtonDestructiveUseCase(BuildContext context) {
  return coui.Button.destructive(
    onPressed: () => print('Button pressed'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.delete)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Destructive')),
  );
}