import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Select,
)
Widget buildSelectDefaultUseCase(BuildContext context) {
  final options = ['Apple', 'Banana', 'Orange', 'Mango', 'Pineapple'];
  return coui.Select<String>(
    value: context.knobs.options(
      label: 'selected',
      options: options,
    ),
    onChanged: (value) => print('Select value changed to: $value'),
    placeholder: const Text('Select a fruit'),
    popup: coui.SelectPopup.noVirtualization(
      items: coui.SelectItemList(
        children: options
            .map((e) => coui.SelectItemButton(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
      ),
    ),
  );
}
