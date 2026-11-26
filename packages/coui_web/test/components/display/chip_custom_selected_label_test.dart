// The Web half of the custom chip's selected label (designer decision 22 of
// #5319): the seed's own on-colour, decided once in Core. Web emits token
// names, so a paired seed has to come out as the on-token's class — the
// browser resolves it per mode — and a raw seed as the measured end, inline.
// The state-layer rules wash toward the same ink, so they are read too: a
// chrome/rules pair that disagreed would wash toward a label nobody sees.
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

ResolvedChip _resolveSelected(BuildContext context, CoreColor seed) =>
    resolveChip(
      context,
      variant: CoreChipVariant.outlined,
      chipColor: CoreChipColor.custom,
      size: CoreChipSize.md,
      selected: true,
      emphasis: CoreChipEmphasis.high,
      enabled: true,
      seedColor: seed,
    );

ResolvedChipRules _rulesSelected(BuildContext context, CoreColor seed) =>
    resolveChipRules(
      context,
      variant: CoreChipVariant.outlined,
      chipColor: CoreChipColor.custom,
      size: CoreChipSize.md,
      selected: true,
      emphasis: CoreChipEmphasis.high,
      enabled: true,
      seedColor: seed,
    );

void main() {
  group('a selected custom chip labels its fill with the fill on-colour', () {
    testComponents('a paired token seed emits its on-token class', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final (fill, on) in const [
        (CoreColors.tertiary, CoreColors.onTertiary),
        (CoreColors.success, CoreColors.onSuccess),
        (CoreColors.primaryContainer, CoreColors.onPrimaryContainer),
      ]) {
        final resolved = _resolveSelected(context, CoreColor.token(fill));

        expect(
          resolved.root.className.split(' '),
          contains('text-${on.name}'),
          reason: '${fill.name} did not get ${on.name}',
        );
        expect(
          resolved.root.inlineStyles?.properties['color'],
          isNull,
          reason: 'a token label goes out as a class, not inline',
        );
        expect(
          _rulesSelected(context, CoreColor.token(fill)).css,
          contains('rgb(var(--coui-${on.name}))'),
          reason: 'the state wash for ${fill.name} does not use its label',
        );
      }
    });

    testComponents('a raw seed emits the end that reads on it, inline', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final dark = _resolveSelected(context, const CoreColor(0xFF3366FF));
      final light = _resolveSelected(context, const CoreColor(0xFFFFE066));

      expect(
        dark.root.inlineStyles?.properties['color'],
        CoreChipStyle.defaultCustomSelectedForegroundColor.toValue(),
      );
      expect(
        light.root.inlineStyles?.properties['color'],
        CoreChipStyle.defaultCustomSelectedDarkForegroundColor.toValue(),
      );
    });
  });
}
