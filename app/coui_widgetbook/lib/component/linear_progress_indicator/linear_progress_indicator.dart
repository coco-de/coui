import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.LinearProgressIndicator] use case.
@UseCase(
  name: 'default',
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorDefaultUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    color: context.knobs.colorOrNull(label: 'color'),
    minHeight: context.knobs.double.slider(
      initialValue: 4,
      label: 'minHeight',
      max: 16,
      min: 1,
    ),
  );
}

/// A determinate [coui.LinearProgressIndicator] use case.
@UseCase(
  name: 'determinate',
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorDeterminateUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    color: context.knobs.colorOrNull(label: 'color'),
    minHeight: context.knobs.double.slider(
      initialValue: 4,
      label: 'minHeight',
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

/// A [coui.LinearProgressIndicator] use case with sparks.
@UseCase(
  name: 'with sparks',
  type: coui.LinearProgressIndicator,
)
Widget buildLinearProgressIndicatorWithSparksUseCase(BuildContext context) {
  return coui.LinearProgressIndicator(
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    color: context.knobs.colorOrNull(label: 'color'),
    minHeight: context.knobs.double.slider(
      initialValue: 8,
      label: 'minHeight',
      max: 16,
      min: 1,
    ),
    showSparks: true,
    value: context.knobs.double.slider(
      initialValue: 0.75,
      label: 'value',
      max: 1,
      min: 0,
    ),
  );
}
