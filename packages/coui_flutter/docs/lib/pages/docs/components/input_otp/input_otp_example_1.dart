import 'package:coui_flutter/coui_flutter.dart';

class InputOTPExample1 extends StatefulWidget {
  const InputOTPExample1({super.key});

  @override
  State<InputOTPExample1> createState() => _InputOTPExample1State();
}

class _InputOTPExample1State extends State<InputOTPExample1> {
  String value = '';
  String? submittedValue;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InputOTP(
          children: [
            InputOTPChild.character(allowDigit: true),
            InputOTPChild.character(allowDigit: true),
            InputOTPChild.character(allowDigit: true),
            InputOTPChild.separator,
            InputOTPChild.character(allowDigit: true),
            InputOTPChild.character(allowDigit: true),
            InputOTPChild.character(allowDigit: true),
          ],
          onChanged: (value) {
            setState(() {
              this.value = value.otpToString();
            });
          },
          onSubmitted: (value) {
            setState(() {
              submittedValue = value.otpToString();
            });
          },
        ),
        gap(16),
        Text('Value: $value'),
        Text('Submitted Value: $submittedValue'),
      ],
    );
  }
}
