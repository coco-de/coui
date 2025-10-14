import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';
import '../input_otp/input_otp_example_2.dart';

class InputOTPTile extends StatelessWidget implements IComponentPage {
  const InputOTPTile({super.key});

  @override
  String get title => 'Input OTP';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'input_otp',
      title: 'Input OTP',
      example: Column(
        children: [
          const Card(child: InputOTPExample2()),
          const Gap(24),
          Transform.translate(
            offset: const Offset(-150, 0),
            child: Card(
              child: InputOTP(
                children: [
                  InputOTPChild.character(allowDigit: true, obscured: true),
                  InputOTPChild.character(allowDigit: true, obscured: true),
                  InputOTPChild.character(allowDigit: true, obscured: true),
                  InputOTPChild.separator,
                  InputOTPChild.character(allowDigit: true, obscured: true),
                  InputOTPChild.character(allowDigit: true, obscured: true),
                  InputOTPChild.character(allowDigit: true, obscured: true),
                ],
                initialValue: '123456'.codeUnits,
              ),
            ),
          ),
        ],
      ),
      scale: 1,
    );
  }
}
