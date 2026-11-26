import 'package:coui_web/coui_web.dart';

class StepsHorizontalExample extends StatelessComponent {
  const StepsHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Steps(
      currentStep: 1,
      vertical: false,
      items: [
        CoreStepData(title: '장바구니'),
        CoreStepData(title: '배송'),
        CoreStepData(title: '결제'),
        CoreStepData(title: '확인'),
      ],
    );
  }
}
