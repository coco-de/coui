import 'package:coui_web/coui_web.dart';

class KbdComboExample extends StatelessComponent {
  const KbdComboExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'Shift', 'P']);
  }
}
