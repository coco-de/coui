import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A primary [coui.Button] use case.
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
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Primary', label: 'text')),
  );
}

/// A secondary [coui.Button] use case.
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
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Secondary', label: 'text')),
  );
}

/// An outline [coui.Button] use case.
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
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Outline', label: 'text')),
  );
}

/// A ghost [coui.Button] use case.
@UseCase(
  name: 'ghost',
  type: coui.Button,
)
Widget buildButtonGhostUseCase(BuildContext context) {
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Ghost', label: 'text')),
  );
}

/// A link [coui.Button] use case.
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
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(context.knobs.string(initialValue: 'Link', label: 'text')),
  );
}

/// A destructive [coui.Button] use case.
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
    onPressed: () {},
    trailing: context.knobs.boolean(initialValue: false, label: 'trailing icon')
        ? const Icon(Icons.arrow_forward)
        : null,
    child: Text(
      context.knobs.string(initialValue: 'Destructive', label: 'text'),
    ),
  );
}
