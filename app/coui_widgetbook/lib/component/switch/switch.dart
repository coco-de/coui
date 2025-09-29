import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Switch] use case.
@UseCase(
  name: 'default',
  type: coui.Switch,
)
Widget buildSwitchDefaultUseCase(BuildContext context) {
  return coui.Switch(
    activeColor: context.knobs.colorOrNull(
      label: 'activeColor',
    ),
    activeThumbColor: context.knobs.colorOrNull(
      label: 'activeThumbColor',
    ),
    enabled: context.knobs.boolean(
      initialValue: true,
      label: 'enabled',
    ),
    inactiveColor: context.knobs.colorOrNull(
      label: 'inactiveColor',
    ),
    inactiveThumbColor: context.knobs.colorOrNull(
      label: 'inactiveThumbColor',
    ),
    onChanged: (value) {},
    value: context.knobs.boolean(
      initialValue: false,
      label: 'value',
    ),
  );
}

/// A [coui.Switch] use case with a label.
@UseCase(
  name: 'with_label',
  type: coui.Switch,
)
Widget buildSwitchWithLabelUseCase(BuildContext context) {
  return coui.Switch(
    gap: context.knobs.double.slider(
      initialValue: 8,
      label: 'gap',
      max: 32,
      min: 0,
    ),
    leading: Text(
      context.knobs.string(
        initialValue: 'Leading',
        label: 'leading text',
      ),
    ),
    onChanged: (value) {},
    trailing: Text(
      context.knobs.string(
        initialValue: 'Trailing',
        label: 'trailing text',
      ),
    ),
    value: context.knobs.boolean(
      initialValue: true,
      label: 'value',
    ),
  );
}

/// A disabled [coui.Switch] use case.
@UseCase(
  name: 'disabled',
  type: coui.Switch,
)
Widget buildSwitchDisabledUseCase(BuildContext context) {
  return const coui.Switch(
    enabled: false,
    onChanged: null,
    value: false,
  );
}
