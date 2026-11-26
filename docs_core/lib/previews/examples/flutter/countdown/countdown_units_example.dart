import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/shared/countdown_units_sample.dart';

/// Four caller-owned boxes sharing the widest numeral's intrinsic width.
/// Keep this small composition in the caller; it is not a Countdown API.
class CountdownUnitsExample extends StatelessWidget {
  const CountdownUnitsExample({super.key, this.days = 100});

  final int days;

  @override
  Widget build(BuildContext context) {
    final values = [days, 8, 30, 15];
    // IntrinsicWidth asks Row for its intrinsic width: equal flex children
    // contribute four times the largest cell, plus the three gaps. Expanded
    // then gives every cell the same share. No font measurement is cached.
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: CoreSize.size56),
                child: OutlinedContainer(
                  key: ValueKey('countdown-unit-$i'),
                  containerStyle: countdownUnitContainerStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The default max is 99; days must explicitly allow 100+.
                      Countdown(value: values[i], max: i == 0 ? 365 : 59),
                      const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space2)),
                      Text(countdownUnitLabels[i]).bodyXs.onSurfaceVariant,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
