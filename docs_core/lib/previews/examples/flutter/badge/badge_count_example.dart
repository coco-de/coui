import 'package:coui_flutter/coui_flutter.dart';

class BadgeCountExample extends StatelessWidget {
  const BadgeCountExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A number sits in a pill that is never narrower than it is tall.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
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
      ],
    );
  }
}
