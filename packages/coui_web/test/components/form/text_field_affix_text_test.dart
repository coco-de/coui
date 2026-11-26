import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The affix `<span>` — the one element carrying the affix colour class.
DomComponent _affixSpan() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere(
      (c) =>
          c.tag == 'span' &&
          (c.classes ?? '')
              .split(' ')
              .contains(
                'text-${CoreTextFieldStyle.defaultAffixColor.tailwindColor}',
              ),
    );

String _roleClass(CoreTextStyle base) => emitTypography(null, base).className;

void main() {
  // `suffix` is `W?` — a unit, a count, a timer are legal suffixes — and the
  // slot used to pin `font-size` to the ICON size inline, so a `Text` suffix
  // rendered at 20px inside a 14px field. Icons never needed that pin (an
  // `Icon` sizes itself); only text ever read it.
  group('TextField affix text', () {
    // xs/sm/md/lg share the `body-medium` rung and xl/xl2 the
    // `body-large` rung (Figma "❖ TextField" 2026-09 개정), so `md` and
    // `xl` are the pair that actually differ — proving "per size", not a
    // coincidence at one size.
    testComponents('the slot wears the size base — bodyMedium at md', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(suffix: Text('02:47')));

      final span = _affixSpan();
      expect(
        span.classes!.split(' '),
        contains(
          _roleClass(const CoreTextStyle.token(CoreTextStyles.bodyMedium)),
        ),
      );
      expect(
        span.styles?.properties ?? const {},
        isNot(contains('font-size')),
        reason: 'no inline icon-size pin on the slot',
      );
    });

    testComponents('and bodyLarge at xl — the base is per size', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(size: CoreComponentSize.xl, suffix: Text('02:47')),
      );

      expect(
        _affixSpan().classes!.split(' '),
        contains(
          _roleClass(const CoreTextStyle.token(CoreTextStyles.bodyLarge)),
        ),
      );
    });
  });
}
