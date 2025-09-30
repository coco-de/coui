import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.Slider)
Widget buildSliderDefaultUseCase(BuildContext context) {
  return coui.Slider(
    onChanged: (value) => print('Slider: $value'),
    value: coui.SliderValue.single(
      context.knobs.double.slider(
        initialValue: 0.5,
        label: 'value',
        max: 1,
        min: 0,
      ),
    ),
  );
}
