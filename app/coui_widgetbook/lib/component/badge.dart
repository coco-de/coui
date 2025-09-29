import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'primary',
  type: coui.PrimaryBadge,
)
Widget buildPrimaryBadgeUseCase(BuildContext context) {
  return coui.PrimaryBadge(
    onPressed: context.knobs.boolean(label: 'interactive', initialValue: false)
        ? () => print('Badge pressed')
        : null,
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.star, size: 16)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.notifications, size: 14)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Primary')),
  );
}

@UseCase(
  name: 'secondary',
  type: coui.SecondaryBadge,
)
Widget buildSecondaryBadgeUseCase(BuildContext context) {
  return coui.SecondaryBadge(
    onPressed: context.knobs.boolean(label: 'interactive', initialValue: false)
        ? () => print('Badge pressed')
        : null,
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.info, size: 16)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward, size: 14)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Secondary')),
  );
}

@UseCase(
  name: 'outline',
  type: coui.OutlineBadge,
)
Widget buildOutlineBadgeUseCase(BuildContext context) {
  return coui.OutlineBadge(
    onPressed: context.knobs.boolean(label: 'interactive', initialValue: false)
        ? () => print('Badge pressed')
        : null,
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.check_circle_outline, size: 16)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.arrow_forward, size: 14)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Outline')),
  );
}

@UseCase(
  name: 'destructive',
  type: coui.DestructiveBadge,
)
Widget buildDestructiveBadgeUseCase(BuildContext context) {
  return coui.DestructiveBadge(
    onPressed: context.knobs.boolean(label: 'interactive', initialValue: false)
        ? () => print('Badge pressed')
        : null,
    leading: context.knobs.boolean(label: 'leading icon', initialValue: false)
        ? const Icon(Icons.warning, size: 16)
        : null,
    trailing: context.knobs.boolean(label: 'trailing icon', initialValue: false)
        ? const Icon(Icons.delete, size: 14)
        : null,
    child: Text(context.knobs.string(label: 'text', initialValue: 'Destructive')),
  );
}