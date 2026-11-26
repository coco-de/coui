import 'package:coui_flutter/coui_flutter.dart';

class ValidationBadgePendingExample extends StatelessWidget {
  const ValidationBadgePendingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '입력 대기 중',
      state: CoreValidationState.pending,
    );
  }
}
