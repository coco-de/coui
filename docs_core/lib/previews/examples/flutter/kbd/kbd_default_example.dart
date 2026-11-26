import 'package:coui_flutter/coui_flutter.dart';

class KbdDefaultExample extends StatelessWidget {
  const KbdDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']);
  }
}
