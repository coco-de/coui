import 'package:coui_flutter/coui_flutter.dart';

class ValidationBadgeDefaultExample extends StatelessWidget {
  const ValidationBadgeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    );
  }
}
