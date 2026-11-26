import 'package:coui_flutter/coui_flutter.dart';

class InputOtpDefaultExample extends StatelessWidget {
  const InputOtpDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return InputOtp(
      length: 6,
      onCompleted: (_) {},
    );
  }
}
