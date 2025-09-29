import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorDefaultUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    minHeight: context.knobs.double.slider(
      label: 'minHeight',
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
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorDeterminateUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    value: context.knobs.double.slider(
      label: 'value',
      initialValue: 0.75,
      min: 0,
      max: 1,
    ),
    minHeight: context.knobs.double.slider(
      label: 'minHeight',
      initialValue: 4,
      min: 1,
      max: 16,
    ),
    color: context.knobs.colorOrNull(label: 'color'),
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
  );
}

@UseCase(
  name: 'with sparks',
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorWithSparksUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    value: context.knobs.double.slider(
      label: 'value',
      initialValue: 0.75,
      min: 0,
      max: 1,
    ),
    showSparks: true,
    minHeight: context.knobs.double.slider(
      label: 'minHeight',
      initialValue: 8,
      min: 1,
      max: 16,
    ),
    color: context.knobs.colorOrNull(label: 'color'),
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
  );
}
