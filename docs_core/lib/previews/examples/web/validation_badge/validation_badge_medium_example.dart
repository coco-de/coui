import 'package:coui_web/coui_web.dart';

class ValidationBadgeMediumExample extends StatelessComponent {
  const ValidationBadgeMediumExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '대문자 1개 이상',
      state: CoreValidationState.valid,
      size: CoreValidationBadgeSize.medium,
    );
  }
}
