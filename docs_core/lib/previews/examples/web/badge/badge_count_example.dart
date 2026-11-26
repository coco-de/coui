import 'package:coui_web/coui_web.dart';

class BadgeCountExample extends StatelessComponent {
  const BadgeCountExample({super.key});

  @override
  Component build(BuildContext context) {
    // A number sits in a pill that is never narrower than it is tall.
    return div([
      Badge(
        tone: CoreBadgeTone.info,
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.xs,
        child: Text('3'),
      ),
      Badge(
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.xs,
        child: Text('12'),
      ),
      Badge(
        tone: CoreBadgeTone.info,
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.sm,
        child: Text('8'),
      ),
      Badge(
        tone: CoreBadgeTone.destructive,
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.sm,
        child: Text('99+'),
      ),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
