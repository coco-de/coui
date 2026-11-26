import 'package:coui_web/coui_web.dart';
// chip_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Web twin of Flutter's `chip_state_layer_engage_test.dart` — that file
/// pins the SELECT (`_pressed`/`_focused`/`_hovered` picking among four
/// baked container styles); this one pins the WIRING the CSS side needs
/// instead, since `:hover`/`:focus-visible`/`:active` can't be exercised
/// without a real browser (→ `process/verify.md` 7-24, a per-PR manual
/// step, not a committed regression test here).
///
/// `resolveChipRules` has to be read as a PAIR with what `chip.dart`
/// does with it: the scope class it returns must be the same class
/// `chip.dart` puts on the `Clickable` root, and the `>` combinator
/// inside the CSS text must target `kChipBodyMarker` — the class
/// `chip.dart` puts on `chipBody`. Neither half alone proves the wiring;
/// this file pins both at once so a rename on either side that forgets
/// its partner fails here instead of silently in a browser.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));

  return context;
}

void main() {
  group('Chip state-layer scoped rules', () {
    testComponents(
      'an enabled chip pairs a non-empty scope class with rules that '
      'target it through the body marker',
      (tester) async {
        final context = _themedContext(tester);
        final rules = resolveChipRules(
          context,
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );

        expect(
          rules.scopeClass,
          isNotEmpty,
          reason: 'nothing for the Clickable root to wear',
        );
        expect(
          rules.css,
          isNotEmpty,
          reason: 'a scope class with no rules behind it washes nothing',
        );
        expect(
          rules.css,
          contains('.${rules.scopeClass}:hover>.$kChipBodyMarker'),
          reason:
              'the rule must select through the body marker, not the '
              'scope element itself — :hover lands on the Clickable '
              'root, chipBody is a plain nested div one level in',
        );
        expect(rules.css, contains(':focus-visible>.$kChipBodyMarker'));
        expect(rules.css, contains(':active>.$kChipBodyMarker'));
        final face = resolveChip(
          context,
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );
        expect(rules.css, contains('var(--co-chip-hover-fill)'));
        expect(
          face.root.inlineStyles?.properties['--co-chip-hover-fill'],
          contains('color-mix(in srgb,'),
          reason: 'the scoped state must read a published composed wash',
        );
      },
    );

    testComponents(
      'the three rungs are ordered hover, focus, pressed — later wins '
      'a specificity tie',
      (tester) async {
        final rules = resolveChipRules(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );

        final hoverAt = rules.css.indexOf(':hover>');
        final focusAt = rules.css.indexOf(':focus-visible>');
        final pressedAt = rules.css.indexOf(':active>');

        expect(
          hoverAt < focusAt && focusAt < pressedAt,
          isTrue,
          reason:
              'a focused chip that is then hovered must not step DOWN '
              'to the hover weight — cascade order is what states that',
        );
      },
    );

    testComponents(
      'pressed washes stronger than hover, not the same weight twice',
      (tester) async {
        final rules = resolveChipRules(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );

        final hoverRule = rules.css.substring(
          rules.css.indexOf(':hover>'),
          rules.css.indexOf(':focus-visible>'),
        );
        final pressedRule = rules.css.substring(rules.css.indexOf(':active>'));

        expect(
          pressedRule,
          isNot(equals(hoverRule.replaceFirst(':hover', ':active'))),
          reason:
              'if the two weights collapsed to the same percentage the '
              'ramp would have only two rungs instead of three',
        );
      },
    );

    testComponents('a disabled chip states no scope class and no rules', (
      tester,
    ) async {
      final rules = resolveChipRules(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.defaultColor,
        size: CoreChipSize.md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: false,
      );

      expect(
        rules.scopeClass,
        isEmpty,
        reason:
            'a disabled chip has no Clickable root to wear a scope class '
            "— its rest chrome IS its disabled chrome, there's nothing "
            'to wash toward',
      );
      expect(rules.css, isEmpty);
    });
  });
}
