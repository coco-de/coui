import 'package:coui_flutter/coui_flutter.dart';

class ValidationBadgeInvalidExample extends StatelessWidget {
  const ValidationBadgeInvalidExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '숫자 포함',
      state: CoreValidationState.invalid,
    );
  }
}
