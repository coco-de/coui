import 'package:coui_flutter/coui_flutter.dart';

class BadgeStatusExample extends StatelessWidget {
  const BadgeStatusExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A status label — the tone's colour plus a leading dot in the label colour.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
        Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
        Badge(tone: CoreBadgeTone.warning, showDot: true, child: Text('대기 중')),
        Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('반려됨')),
        Badge(showDot: true, child: Text('임시 저장')),
      ],
    );
  }
}
