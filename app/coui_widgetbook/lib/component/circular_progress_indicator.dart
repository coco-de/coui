import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.CircularProgressIndicator,
)
Widget buildCircularProgressIndicatorDefaultUseCase(BuildContext context) {
  return coui.CircularProgressIndicator(
    size: context.knobs.double.slider(
      label: 'size',
      initialValue: 48,
      min: 24,
      max: 128,
    ),
    strokeWidth: context.knobs.double.slider(
      label: 'strokeWidth',
      initialValue: 4,
      min: 1,
      max: 16,
    ),
    color: context.knobs.colorOrNull(label: 'color'),
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
  );
}

@UseCase(
  name: 'determinate',
  type: coui.CircularProgressIndicator,
)
Widget buildCircularProgressIndicatorDeterminateUseCase(BuildContext context) {
  return coui.CircularProgressIndicator(
    value: context.knobs.double.slider(
      label: 'value',
      initialValue: 0.75,
      min: 0,
      max: 1,
    ),
    size: context.knobs.double.slider(
      label: 'size',
      initialValue: 48,
      min: 24,
      max: 128,
    ),
    strokeWidth: context.knobs.double.slider(
      label: 'strokeWidth',
      initialValue: 4,
      min: 1,
      max: 16,
    ),
    color: context.knobs.colorOrNull(label: 'color'),
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
  );
}
