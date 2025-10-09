import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the PrimaryButton use case for Widgetbook.
@UseCase(name: 'Primary', type: PrimaryButton)
material.Widget buildPrimaryButtonUseCase(material.BuildContext context) {
  return PrimaryButton(
    onPressed: () {},
    child: const Text('Primary Button'),
  );
}

/// Builds the SecondaryButton use case for Widgetbook.
@UseCase(name: 'Secondary', type: SecondaryButton)
material.Widget buildSecondaryButtonUseCase(material.BuildContext context) {
  return SecondaryButton(
    onPressed: () {},
    child: const Text('Secondary Button'),
  );
}
