import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.CircularProgressIndicator] use case.
@UseCase(
  name: 'default',
  type: coui.CircularProgressIndicator,
)
Widget buildCircularProgressIndicatorDefaultUseCase(BuildContext context) {
  return coui.CircularProgressIndicator(
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    color: context.knobs.colorOrNull(label: 'color'),
    size: context.knobs.double.slider(
      initialValue: 48,
      label: 'size',
      max: 128,
      min: 24,
    ),
    strokeWidth: context.knobs.double.slider(
      initialValue: 4,
      label: 'strokeWidth',
      max: 16,
      min: 1,
    ),
  );
}

/// A determinate [coui.CircularProgressIndicator] use case.
@UseCase(
  name: 'determinate',
  type: coui.CircularProgressIndicator,
)
Widget buildCircularProgressIndicatorDeterminateUseCase(BuildContext context) {
  return coui.CircularProgressIndicator(
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    color: context.knobs.colorOrNull(label: 'color'),
    size: context.knobs.double.slider(
      initialValue: 48,
      label: 'size',
      max: 128,
      min: 24,
    ),
    strokeWidth: context.knobs.double.slider(
      initialValue: 4,
      label: 'strokeWidth',
      max: 16,
      min: 1,
    ),
    value: context.knobs.double.slider(
      initialValue: 0.75,
      label: 'value',
      max: 1,
      min: 0,
    ),
  );
}
