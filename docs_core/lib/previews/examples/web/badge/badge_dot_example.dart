import 'package:coui_web/coui_web.dart';

class BadgeDotExample extends StatelessComponent {
  const BadgeDotExample({super.key});

  @override
  Component build(BuildContext context) {
    // A dot holds nothing, yet it still wears its tone — the form says
    // what is inside, not which colour it is.
    return div([
      Badge(form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.primary, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.info, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.warning, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
