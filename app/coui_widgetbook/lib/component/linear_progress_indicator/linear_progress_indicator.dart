import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the default LinearProgressIndicator use case for Widgetbook.
@UseCase(name: 'Default', type: LinearProgressIndicator)
material.Widget buildLinearProgressIndicatorUseCase(
  material.BuildContext context,
) {
  return const LinearProgressIndicator(value: 0.5);
}
