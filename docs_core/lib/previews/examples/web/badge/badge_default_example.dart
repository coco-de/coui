import 'package:coui_web/coui_web.dart';

class BadgeDefaultExample extends StatelessComponent {
  const BadgeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // Every default — a neutral tone, tonal strength, a word, md.
    return Badge(child: Text('신규'));
  }
}
