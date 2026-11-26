import 'package:coui_web/coui_web.dart';

class BadgeVariantsExample extends StatelessComponent {
  const BadgeVariantsExample({super.key});

  @override
  Component build(BuildContext context) {
    // The variant says how loud one tone is — a fill, a tint, or a line.
    return div([
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.filled, child: Text('채움')),
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.tonal, child: Text('톤')),
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.outlined, child: Text('외곽선')),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
