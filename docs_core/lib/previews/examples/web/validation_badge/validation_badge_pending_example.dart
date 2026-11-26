import 'package:coui_web/coui_web.dart';

class ValidationBadgePendingExample extends StatelessComponent {
  const ValidationBadgePendingExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '입력 대기 중',
      state: CoreValidationState.pending,
    );
  }
}
