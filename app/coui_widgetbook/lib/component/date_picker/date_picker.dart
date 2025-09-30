import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.DatePicker)
Widget buildDatePickerDefaultUseCase(BuildContext _) {
  return coui.DatePicker(
    onChanged: (date) => print('Date: $date'),
    value: DateTime.now(),
  );
}
