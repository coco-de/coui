import 'package:coui_web/coui_web.dart';

class PhoneInputDefaultExample extends StatelessComponent {
  const PhoneInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const PhoneInput(placeholder: '전화번호를 입력해 주세요');
  }
}
