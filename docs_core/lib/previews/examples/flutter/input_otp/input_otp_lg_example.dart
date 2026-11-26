import 'package:coui_flutter/coui_flutter.dart';

class InputOtpLgExample extends StatelessWidget {
  const InputOtpLgExample({super.key});

  @override
  Widget build(BuildContext context) {
    return InputOtp(
      length: 6,
      size: CoreInputOtpSize.lg,
      onCompleted: (_) {},
    );
  }
}
