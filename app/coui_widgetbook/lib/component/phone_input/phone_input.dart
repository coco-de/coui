import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.PhoneInput)
Widget buildPhoneInputDefaultUseCase(BuildContext _) {
  return coui.PhoneInput(
    onChanged: (phone) => print('Phone: $phone'),
  );
}
