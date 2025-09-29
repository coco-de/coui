import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Chip] use case.
@UseCase(
  name: 'default',
  type: coui.Chip,
)
Widget buildChipDefaultUseCase(BuildContext context) {
  return coui.Chip(
    child: Text(context.knobs.string(initialValue: 'Chip', label: 'text')),
  );
}

/// A [coui.Chip] use case with a leading icon.
@UseCase(
  name: 'with leading',
  type: coui.Chip,
)
Widget buildChipWithLeadingUseCase(BuildContext context) {
  return coui.Chip(
    leading: const Icon(Icons.star, size: 16),
    child: Text(
      context.knobs.string(initialValue: 'Chip with leading', label: 'text'),
    ),
  );
}

/// A [coui.Chip] use case with a trailing button.
@UseCase(
  name: 'with trailing',
  type: coui.Chip,
)
Widget buildChipWithTrailingUseCase(BuildContext context) {
  return coui.Chip(
    trailing: coui.ChipButton(
      onPressed: () {},
      child: const Icon(Icons.close, size: 16),
    ),
    child: Text(
      context.knobs.string(initialValue: 'Chip with trailing', label: 'text'),
    ),
  );
}

/// An interactive [coui.Chip] use case.
@UseCase(
  name: 'interactive',
  type: coui.Chip,
)
Widget buildChipInteractiveUseCase(BuildContext context) {
  return coui.Chip(
    onPressed: () {},
    child: Text(
      context.knobs.string(initialValue: 'Interactive Chip', label: 'text'),
    ),
  );
}
