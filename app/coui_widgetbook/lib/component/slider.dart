import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'single',
  type: coui.Slider,
)
Widget buildSliderSingleUseCase(BuildContext context) {
  return coui.Slider(
    max: context.knobs.double.input(initialValue: 100, label: 'max'),
    min: context.knobs.double.input(initialValue: 0, label: 'min'),
    onChanged: (value) => print('Slider value changed to: $value'),
    value: coui.SliderValue.single(
      context.knobs.double.slider(
        initialValue: 50,
        label: 'value',
        max: 100,
        min: 0,
      ),
    ),
  );
}

@UseCase(
  name: 'ranged',
  type: coui.Slider,
)
Widget buildSliderRangedUseCase(BuildContext context) {
  return coui.Slider(
    max: context.knobs.double.input(initialValue: 100, label: 'max'),
    min: context.knobs.double.input(initialValue: 0, label: 'min'),
    onChanged: (value) => print('Slider value changed to: $value'),
    value: coui.SliderValue.ranged(
      context.knobs.double.slider(
        initialValue: 20,
        label: 'start',
        max: 100,
        min: 0,
      ),
      context.knobs.double.slider(
        initialValue: 80,
        label: 'end',
        max: 100,
        min: 0,
      ),
    ),
  );
}

@UseCase(
  name: 'with divisions',
  type: coui.Slider,
)
Widget buildSliderWithDivisionsUseCase(BuildContext context) {
  return coui.Slider(
    divisions: context.knobs.int.slider(
      initialValue: 10,
      label: 'divisions',
      max: 20,
      min: 1,
    ),
    max: 100,
    min: 0,
    onChanged: (value) => print('Slider value changed to: $value'),
    value: coui.SliderValue.single(
      context.knobs.double.slider(
        initialValue: 50,
        label: 'value',
        max: 100,
        min: 0,
      ),
    ),
  );
}
