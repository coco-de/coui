// The Web half of the chip label ladder: each size emits its own role
// class (`text-label-small` / `text-label-medium` / `text-label-large`) and
// no `font-size` overlay — the role carries size, line-height and
// letter-spacing together. The weight is the role's own 500 too, so
// nothing typographic rides inline.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext) onBuild;

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

ResolvedChip _resolve(BuildContext context, CoreChipSize size) => resolveChip(
  context,
  variant: CoreChipVariant.outlined,
  chipColor: CoreChipColor.neutral,
  size: size,
  selected: false,
  emphasis: CoreChipEmphasis.high,
  enabled: true,
);

void main() {
  group('Chip label role ladder (Web)', () {
    testComponents('each size emits its own role class, nothing inline', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const roles = {
        CoreChipSize.sm: CoreTextStyles.labelSmall,
        CoreChipSize.md: CoreTextStyles.labelMedium,
        CoreChipSize.lg: CoreTextStyles.labelLarge,
      };
      for (final size in CoreChipSize.values) {
        final label = _resolve(context, size).label;
        expect(
          label.className,
          contains('text-${roles[size]!.name}'),
          reason: '${size.name} role class',
        );
        // A scalar overlay was what the old ladder emitted here — the
        // role now states the size, so the inline slot is empty.
        expect(
          label.inlineStyles?.properties['font-size'],
          isNull,
          reason: '${size.name} font-size inline',
        );
      }
    });

    testComponents("every size keeps its role's weight", (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final label = _resolve(context, size).label;
        expect(
          label.inlineStyles?.properties ?? const <String, String>{},
          isNot(contains('font-weight')),
          reason: '${size.name} weight',
        );
        expect(
          label.inlineStyles?.properties['letter-spacing'],
          isNull,
          reason: '${size.name} tracking is the role, not an overlay',
        );
      }
    });

    testComponents('sm is not labelMedium with a smaller font', (tester) async {
      final context = _themedContext(tester);
      final sm = _resolve(context, CoreChipSize.sm).label;
      expect(
        sm.className,
        isNot(contains('text-${CoreTextStyles.labelMedium.name}')),
      );
    });
  });
}
