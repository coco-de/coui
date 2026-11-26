import 'package:coui_flutter/coui_flutter.dart';

class BadgeDotExample extends StatelessWidget {
  const BadgeDotExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A dot holds nothing, yet it still wears its tone — the form says
    // what is inside, not which colour it is.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.primary, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.info, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.warning, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot),
      ],
    );
  }
}
