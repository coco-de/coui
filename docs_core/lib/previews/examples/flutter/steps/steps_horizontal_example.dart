import 'package:coui_flutter/coui_flutter.dart';

class StepsHorizontalExample extends StatelessWidget {
  const StepsHorizontalExample({super.key});

  @override
  Widget build(BuildContext context) {
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
