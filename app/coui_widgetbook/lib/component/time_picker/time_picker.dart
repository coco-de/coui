import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.TimePicker)
Widget buildTimePickerDefaultUseCase(BuildContext _) {
  return coui.TimePicker(
    onChanged: (time) {
      final t = time;
      if (t != null) {
        debugPrint('Time: $t');
      }
    },
    value: const coui.TimeOfDay(hour: 14, minute: 30),
  );
}
