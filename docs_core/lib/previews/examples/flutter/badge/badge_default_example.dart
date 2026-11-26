import 'package:coui_flutter/coui_flutter.dart';

class BadgeDefaultExample extends StatelessWidget {
  const BadgeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Every default — a neutral tone, tonal strength, a word, md.
    return const Badge(child: Text('신규'));
  }
}
