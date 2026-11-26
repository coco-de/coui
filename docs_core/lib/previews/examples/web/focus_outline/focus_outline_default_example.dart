import 'package:coui_web/coui_web.dart';

class FocusOutlineDefaultExample extends StatelessComponent {
  const FocusOutlineDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return FocusOutline(
      focused: true,
      child: Card(child: Text('포커스된 요소').bodyMedium),
    );
  }
}
