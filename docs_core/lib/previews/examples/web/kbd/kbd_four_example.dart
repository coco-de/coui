import 'package:coui_web/coui_web.dart';

class KbdFourExample extends StatelessComponent {
  const KbdFourExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Kbd(keys: ['⌃', '⇧', '⌘', '4']);
  }
}
