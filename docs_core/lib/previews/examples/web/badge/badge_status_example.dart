import 'package:coui_web/coui_web.dart';

class BadgeStatusExample extends StatelessComponent {
  const BadgeStatusExample({super.key});

  @override
  Component build(BuildContext context) {
    // A status label — the tone's colour plus a leading dot in the label colour.
    return div([
      Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
      Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
      Badge(tone: CoreBadgeTone.warning, showDot: true, child: Text('대기 중')),
      Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('반려됨')),
      Badge(showDot: true, child: Text('임시 저장')),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
