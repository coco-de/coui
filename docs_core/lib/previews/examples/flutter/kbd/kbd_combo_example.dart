import 'package:coui_flutter/coui_flutter.dart';

class KbdComboExample extends StatelessWidget {
  const KbdComboExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'Shift', 'P']);
  }
}
