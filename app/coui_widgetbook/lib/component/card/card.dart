import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the default Card use case for Widgetbook.
@UseCase(name: 'Default', type: Card)
material.Widget buildCardUseCase(material.BuildContext context) {
  return const Card(child: Text('Card Content'));
}
