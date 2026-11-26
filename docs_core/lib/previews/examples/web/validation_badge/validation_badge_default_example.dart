import 'package:coui_web/coui_web.dart';

class ValidationBadgeDefaultExample extends StatelessComponent {
  const ValidationBadgeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    );
  }
}
