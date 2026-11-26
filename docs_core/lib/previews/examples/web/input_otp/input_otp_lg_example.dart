import 'package:coui_web/coui_web.dart';

class InputOtpLgExample extends StatelessComponent {
  const InputOtpLgExample({super.key});

  @override
  Component build(BuildContext context) {
    return InputOtp(length: 6, size: CoreInputOtpSize.lg);
  }
}
