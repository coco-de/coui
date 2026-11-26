import 'package:coui_flutter/coui_flutter.dart';

class BadgeVariantsExample extends StatelessWidget {
  const BadgeVariantsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The variant says how loud one tone is — a fill, a tint, or a line.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.filled, child: Text('채움')),
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.tonal, child: Text('톤')),
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.outlined, child: Text('외곽선')),
      ],
    );
  }
}
