import 'package:coui_web/coui_web.dart';
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

void main() {
  group('Chip and Badge chrome slots', () {
    testComponents('chip can zero its border and restate radius and fill', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveChip(
        context,
        variant: CoreChipVariant.outlined,
        chipColor: CoreChipColor.neutral,
        size: CoreChipSize.md,
        selected: false,
        emphasis: CoreChipEmphasis.high,
        enabled: true,
        // A corner that is not the `md` row's own (8), so the restatement is
        // told apart from the default.
        chipStyle: const CoreChipStyle(
          borderWidth: CoreStrokeWidth.stroke0,
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      );

      final inline = resolved.root.inlineStyles?.properties ?? const {};
      expect(inline['border-width'], 'var(--coui-stroke-width-0)');
      expect(inline['border-radius'], contains('var(--coui-radius-4)'));
      expect(
        resolved.root.className.split(' '),
        contains('bg-surface-container'),
      );
    });

    testComponents('badge can zero its border and restate radius and fill', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveBadge(
        context,
        tone: CoreBadgeTone.neutral,
        variant: CoreBadgeVariant.outlined,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.sm,
        interactive: false,
        badgeStyle: const CoreBadgeStyle(
          borderWidth: CoreStrokeWidth.stroke0,
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      );

      final inline = resolved.root.inlineStyles?.properties ?? const {};
      expect(inline['border-width'], 'var(--coui-stroke-width-0)');
      expect(inline['border-radius'], contains('var(--coui-radius-8)'));
      expect(
        resolved.root.className.split(' '),
        contains('bg-surface-container'),
      );
    });
  });
}
