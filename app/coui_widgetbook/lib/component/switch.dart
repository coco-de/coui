import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Switch,
)
Widget buildSwitchDefaultUseCase(BuildContext context) {
  return coui.Switch(
    value: context.knobs.boolean(
      label: 'value',
      initialValue: false,
    ),
    onChanged: (value) => print('Switch value changed to: $value'),
    enabled: context.knobs.boolean(
      label: 'enabled',
      initialValue: true,
    ),
    activeColor: context.knobs.colorOrNull(
      label: 'activeColor',
    ),
    inactiveColor: context.knobs.colorOrNull(
      label: 'inactiveColor',
    ),
    activeThumbColor: context.knobs.colorOrNull(
      label: 'activeThumbColor',
    ),
    inactiveThumbColor: context.knobs.colorOrNull(
      label: 'inactiveThumbColor',
    ),
  );
}

@UseCase(
  name: 'with_label',
  type: coui.Switch,
)
Widget buildSwitchWithLabelUseCase(BuildContext context) {
  return coui.Switch(
    value: context.knobs.boolean(
      label: 'value',
      initialValue: true,
    ),
    onChanged: (value) => print('Switch value changed to: $value'),
    leading: Text(context.knobs.string(
      label: 'leading text',
      initialValue: 'Leading',
    )),
    trailing: Text(context.knobs.string(
      label: 'trailing text',
      initialValue: 'Trailing',
    )),
    gap: context.knobs.double.slider(
      label: 'gap',
      initialValue: 8,
      min: 0,
      max: 32,
    ),
  );
}

@UseCase(
  name: 'disabled',
  type: coui.Switch,
)
Widget buildSwitchDisabledUseCase(BuildContext context) {
  return const coui.Switch(
    value: false,
    onChanged: null,
    enabled: false,
  );
}
