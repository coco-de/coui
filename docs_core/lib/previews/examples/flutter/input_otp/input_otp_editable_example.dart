import 'package:coui_flutter/coui_flutter.dart';

class InputOtpEditableExample extends StatelessWidget {
  const InputOtpEditableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputOtp(
      length: 6,
      initialValue: [49, 50, 51],
      allowCellEditing: true,
    );
  }
}
