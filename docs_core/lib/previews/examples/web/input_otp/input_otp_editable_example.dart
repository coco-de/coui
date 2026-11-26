import 'package:coui_web/coui_web.dart';

class InputOtpEditableExample extends StatelessComponent {
  const InputOtpEditableExample({super.key});

  @override
  Component build(BuildContext context) {
    return const InputOtp(
      length: 6,
      initialValue: '123',
      allowCellEditing: true,
    );
  }
}
