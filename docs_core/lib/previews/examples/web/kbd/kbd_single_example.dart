import 'package:coui_web/coui_web.dart';

class KbdSingleExample extends StatelessComponent {
  const KbdSingleExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Kbd(keys: ['Esc']);
  }
}
