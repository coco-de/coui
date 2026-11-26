import 'package:coui_web/coui_web.dart';

class KbdDefaultExample extends StatelessComponent {
  const KbdDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']);
  }
}
