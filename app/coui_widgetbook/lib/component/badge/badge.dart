import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A primary [coui.Badge] use case.
@UseCase(
  name: 'primary',
  type: coui.PrimaryBadge,
)
Widget buildPrimaryBadgeUseCase(BuildContext context) {
  return coui.PrimaryBadge(
    leading: context.knobs.boolean(label: 'leading icon')
        ? const Icon(Icons.star, size: 16)
        : null,
    onPressed: context.knobs.boolean(label: 'interactive') ? () {} : null,
    trailing: context.knobs.boolean(label: 'trailing icon')
        ? const Icon(Icons.notifications, size: 14)
        : null,
    child: Text(context.knobs.string(initialValue: 'Primary', label: 'text')),
  );
}

/// A secondary [coui.Badge] use case.
@UseCase(
  name: 'secondary',
  type: coui.SecondaryBadge,
)
Widget buildSecondaryBadgeUseCase(BuildContext context) {
  return coui.SecondaryBadge(
    leading: context.knobs.boolean(label: 'leading icon')
        ? const Icon(Icons.info, size: 16)
        : null,
    onPressed: context.knobs.boolean(label: 'interactive') ? () {} : null,
    trailing: context.knobs.boolean(label: 'trailing icon')
        ? const Icon(Icons.arrow_forward, size: 14)
        : null,
    child: Text(context.knobs.string(initialValue: 'Secondary', label: 'text')),
  );
}

/// An outline [coui.Badge] use case.
@UseCase(
  name: 'outline',
  type: coui.OutlineBadge,
)
Widget buildOutlineBadgeUseCase(BuildContext context) {
  return coui.OutlineBadge(
    leading: context.knobs.boolean(label: 'leading icon')
        ? const Icon(Icons.info, size: 16)
        : null,
    onPressed: context.knobs.boolean(label: 'interactive') ? () {} : null,
    trailing: context.knobs.boolean(label: 'trailing icon')
        ? const Icon(Icons.arrow_forward, size: 14)
        : null,
    child: Text(context.knobs.string(initialValue: 'Outline', label: 'text')),
  );
}

/// A destructive [coui.Badge] use case.
@UseCase(
  name: 'destructive',
  type: coui.DestructiveBadge,
)
Widget buildDestructiveBadgeUseCase(BuildContext context) {
  return coui.DestructiveBadge(
    leading: context.knobs.boolean(label: 'leading icon')
        ? const Icon(Icons.warning, size: 16)
        : null,
    onPressed: context.knobs.boolean(label: 'interactive') ? () {} : null,
    trailing: context.knobs.boolean(label: 'trailing icon')
        ? const Icon(Icons.delete, size: 14)
        : null,
    child: Text(
      context.knobs.string(initialValue: 'Destructive', label: 'text'),
    ),
  );
}
