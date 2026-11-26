// A selected custom chip at high emphasis wears its seed as the fill and the
// seed's own on-colour as the label (designer decision 22 of #5319). The
// choice is made once in Core; this reads it back where the Flutter resolver
// hands it to the widget, so a resolver that skipped the Core function and
// kept a fixed label paints the wrong one here.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Future<({ResolvedChip resolved, CoreColorScheme scheme})> _resolveSelected(
  WidgetTester tester,
  CoreColor seed,
) async {
  late ResolvedChip resolved;
  late CoreColorScheme scheme;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            resolved = resolveChip(
              context,
              variant: CoreChipVariant.outlined,
              chipColor: CoreChipColor.custom,
              emphasis: CoreChipEmphasis.high,
              size: CoreChipSize.md,
              selected: true,
              enabled: true,
              seedColor: seed,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (resolved: resolved, scheme: scheme);
}

void main() {
  group('a selected custom chip labels its fill with the fill on-colour', () {
    testWidgets('a paired token seed takes its on-token', (tester) async {
      const pairs = [
        (CoreColors.tertiary, CoreColors.onTertiary),
        (CoreColors.success, CoreColors.onSuccess),
        (CoreColors.primaryContainer, CoreColors.onPrimaryContainer),
      ];

      for (final (fill, on) in pairs) {
        final (:resolved, :scheme) = await _resolveSelected(
          tester,
          CoreColor.token(fill),
        );

        expect(
          resolved.foregroundColor,
          scheme.resolve(CoreColor.token(on)).toValue(),
          reason: '${fill.name} did not get ${on.name}',
        );
      }
    });

    testWidgets('a raw seed gets the end that reads on it', (tester) async {
      final dark = await _resolveSelected(tester, const CoreColor(0xFF3366FF));
      final light = await _resolveSelected(
        tester,
        const CoreColor(0xFFFFE066),
      );

      expect(
        dark.resolved.foregroundColor,
        CoreChipStyle.defaultCustomSelectedForegroundColor.toValue(),
      );
      expect(
        light.resolved.foregroundColor,
        CoreChipStyle.defaultCustomSelectedDarkForegroundColor.toValue(),
      );
    });
  });
}
