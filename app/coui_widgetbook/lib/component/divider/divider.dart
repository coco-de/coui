import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the default Divider use case for Widgetbook.
@UseCase(name: 'Default', type: Divider)
material.Widget buildDividerUseCase(material.BuildContext context) {
  return const Divider();
}
