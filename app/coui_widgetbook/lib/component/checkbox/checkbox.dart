import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Checkbox,
)
Widget buildCheckboxDefaultUseCase(BuildContext context) {
  return coui.Checkbox(
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    onChanged: (state) => print('Checkbox state changed to: $state'),
    state: context.knobs.object.dropdown(
      label: 'state',
      options: coui.CheckboxState.values,
    ),
  );
}

@UseCase(
  name: 'tristate',
  type: coui.Checkbox,
)
Widget buildCheckboxTristateUseCase(BuildContext context) {
  return coui.Checkbox(
    onChanged: (state) => print('Checkbox state changed to: $state'),
    state: context.knobs.object.dropdown(
      label: 'state',
      options: coui.CheckboxState.values,
    ),
    tristate: true,
  );
}

@UseCase(
  name: 'with label',
  type: coui.Checkbox,
)
Widget buildCheckboxWithLabelUseCase(BuildContext context) {
  return coui.Checkbox(
    onChanged: (state) => print('Checkbox state changed to: $state'),
    state: context.knobs.object.dropdown(
      label: 'state',
      options: coui.CheckboxState.values,
    ),
    trailing: Text(
      context.knobs.string(initialValue: 'Accept terms', label: 'label'),
    ),
  );
}
