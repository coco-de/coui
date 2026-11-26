import 'package:coui_web/coui_web.dart';

class ValidationBadgeInvalidExample extends StatelessComponent {
  const ValidationBadgeInvalidExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '숫자 포함',
      state: CoreValidationState.invalid,
    );
  }
}
