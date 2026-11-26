import 'package:coui_flutter/coui_flutter.dart';

class FocusOutlineDefaultExample extends StatelessWidget {
  const FocusOutlineDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusOutline(
      focused: true,
      child: Card(child: Text('포커스된 요소').bodyMedium),
    );
  }
}
