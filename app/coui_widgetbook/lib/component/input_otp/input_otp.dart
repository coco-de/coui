import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.InputOTP)
Widget buildInputOTPDefaultUseCase(BuildContext _) {
  return coui.InputOTP(
    children: List.generate(6, (_) => coui.InputOTPChild.character()),
    onChanged: (v) => print('OTP: $v'),
  );
}

@UseCase(name: 'numeric', type: coui.InputOTP)
Widget buildInputOTPNumericUseCase(BuildContext _) {
  return coui.InputOTP(
    children: List.generate(
      4,
      (_) => coui.InputOTPChild.character(allowDigit: true),
    ),
    onChanged: (v) => print('Numeric: $v'),
  );
}

@UseCase(name: 'password', type: coui.InputOTP)
Widget buildInputOTPPasswordUseCase(BuildContext _) {
  return coui.InputOTP(
    children: List.generate(
      6,
      (_) => coui.InputOTPChild.character(obscured: true),
    ),
    onChanged: (v) => print('Password: $v'),
  );
}
