import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.RadioGroup,
)
Widget buildRadioGroupDefaultUseCase(BuildContext context) {
  final options = ['Apple', 'Banana', 'Orange'];
  return coui.RadioGroup<String>(
    onChanged: (value) => print('Radio group value changed to: $value'),
    value: context.knobs.options(
      label: 'selected',
      options: options,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map(
            (option) => coui.RadioItem(
              trailing: Text(option),
              value: option,
            ),
          )
          .toList(),
    ),
  );
}

@UseCase(
  name: 'card',
  type: coui.RadioGroup,
)
Widget buildRadioGroupCardUseCase(BuildContext context) {
  final options = ['Small', 'Medium', 'Large'];
  return coui.RadioGroup<String>(
    onChanged: (value) => print('Radio group value changed to: $value'),
    value: context.knobs.options(
      label: 'selected',
      options: options,
    ),
    child: Row(
      children: options
          .map(
            (option) => Flexible(
              child: coui.RadioCard(
                value: option,
                child: Center(child: Text(option)),
              ),
            ),
          )
          .toList(),
    ),
  );
}
