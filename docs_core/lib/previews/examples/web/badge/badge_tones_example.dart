import 'package:coui_web/coui_web.dart';

class BadgeTonesExample extends StatelessComponent {
  const BadgeTonesExample({super.key});

  @override
  Component build(BuildContext context) {
    // The tone says what the colour means — the same tonal label in each.
    return div([
      Badge(child: Text('중립')),
      Badge(tone: CoreBadgeTone.primary, child: Text('주요')),
      Badge(tone: CoreBadgeTone.info, child: Text('정보')),
      Badge(tone: CoreBadgeTone.success, child: Text('성공')),
      Badge(tone: CoreBadgeTone.warning, child: Text('경고')),
      Badge(tone: CoreBadgeTone.destructive, child: Text('위험')),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
