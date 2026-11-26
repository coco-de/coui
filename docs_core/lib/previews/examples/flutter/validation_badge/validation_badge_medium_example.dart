import 'package:coui_flutter/coui_flutter.dart';

class ValidationBadgeMediumExample extends StatelessWidget {
  const ValidationBadgeMediumExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '대문자 1개 이상',
      state: CoreValidationState.valid,
      size: CoreValidationBadgeSize.medium,
    );
  }
}
