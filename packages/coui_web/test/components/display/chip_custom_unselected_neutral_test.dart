// The Web half of "an unselected chip states no colour": an enabled
// unselected custom chip is the neutral chip. The seed paints a chip only
// when it is selected.
//
// Web emits token names, so the proof is that the custom chip's class list,
// inline styles and state-layer rules are the neutral chip's — a resolver
// that kept a custom branch for the resting chip would put the seed on the
// label (a raw seed inline, a token seed as its own class) and into the
// wash. `resolveChipRules` re-walks the colours on its own, so it is read
// as well: a chrome/rules pair that disagreed would wash toward a label
// nobody sees.
import 'package:coui_web/coui_web.dart';
// chip_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

const _seeds = <String, CoreColor>{
  'a token seed': CoreColor.token(CoreColors.tertiary),
  'a raw seed': CoreColor(0xFF3366FF),
};

ResolvedChip _resolve(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipEmphasis emphasis,
  required CoreChipVariant variant,
  required bool selected,
  CoreColor? seedColor,
}) => resolveChip(
  context,
  variant: variant,
  chipColor: chipColor,
  size: CoreChipSize.md,
  selected: selected,
  emphasis: emphasis,
  enabled: true,
  seedColor: seedColor,
);

ResolvedChipRules _rules(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipEmphasis emphasis,
  required CoreChipVariant variant,
  required bool selected,
  CoreColor? seedColor,
}) => resolveChipRules(
  context,
  variant: variant,
  chipColor: chipColor,
  size: CoreChipSize.md,
  selected: selected,
  emphasis: emphasis,
  enabled: true,
  seedColor: seedColor,
);

void main() {
  group('an enabled unselected custom chip is the neutral chip', () {
    for (final MapEntry(key: seedName, value: seed) in _seeds.entries) {
      for (final emphasis in CoreChipEmphasis.values) {
        for (final variant in CoreChipVariant.values) {
          testComponents('$seedName · ${emphasis.name} · ${variant.name}', (
            tester,
          ) async {
            final context = _themedContext(tester);

            final custom = _resolve(
              context,
              chipColor: CoreChipColor.custom,
              emphasis: emphasis,
              variant: variant,
              selected: false,
              seedColor: seed,
            );
            final neutral = _resolve(
              context,
              chipColor: CoreChipColor.neutral,
              emphasis: emphasis,
              variant: variant,
              selected: false,
            );

            expect(custom.root.className, neutral.root.className);
            expect(
              custom.root.inlineStyles?.properties,
              neutral.root.inlineStyles?.properties,
            );

            final customRules = _rules(
              context,
              chipColor: CoreChipColor.custom,
              emphasis: emphasis,
              variant: variant,
              selected: false,
              seedColor: seed,
            );
            final neutralRules = _rules(
              context,
              chipColor: CoreChipColor.neutral,
              emphasis: emphasis,
              variant: variant,
              selected: false,
            );

            expect(customRules.css, neutralRules.css);
            expect(customRules.scopeClass, neutralRules.scopeClass);
          });
        }
      }
    }

    testComponents('the seed still paints a selected custom chip', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final MapEntry(key: seedName, value: seed) in _seeds.entries) {
        final custom = _resolve(
          context,
          chipColor: CoreChipColor.custom,
          emphasis: CoreChipEmphasis.high,
          variant: CoreChipVariant.outlined,
          selected: true,
          seedColor: seed,
        );
        final neutral = _resolve(
          context,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          variant: CoreChipVariant.outlined,
          selected: true,
        );

        expect(
          [custom.root.className, custom.root.inlineStyles?.properties],
          isNot([
            neutral.root.className,
            neutral.root.inlineStyles?.properties,
          ]),
          reason: '$seedName must still fill a selected chip',
        );
      }
    });
  });
}
