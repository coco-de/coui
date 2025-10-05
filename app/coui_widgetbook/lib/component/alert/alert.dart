import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Alert)
material.Widget buildAlertUseCase(material.BuildContext context) {
  return const Alert(
    title: Text('Alert Title'),
    trailing: Text('This is an alert message.'),
  );
}
