import 'package:coui_flutter/coui_flutter.dart';

class BadgeTonesExample extends StatelessWidget {
  const BadgeTonesExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The tone says what the colour means — the same tonal label in each.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(child: Text('중립')),
        Badge(tone: CoreBadgeTone.primary, child: Text('주요')),
        Badge(tone: CoreBadgeTone.info, child: Text('정보')),
        Badge(tone: CoreBadgeTone.success, child: Text('성공')),
        Badge(tone: CoreBadgeTone.warning, child: Text('경고')),
        Badge(tone: CoreBadgeTone.destructive, child: Text('위험')),
      ],
    );
  }
}
