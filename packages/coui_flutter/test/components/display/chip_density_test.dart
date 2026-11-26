// A chip's corners (6 · 8 · 10) sit on the radius band a density moves; its
// height (28 · 32 · 40) is a floor of its own ladder and does not move.
//
// Read back from what the resolver hands the painter — the cast's baked
// corner — under a real `CoUIApp(density: …)`, not from the theme that
// carries the density. The numbers are written out, the way
// `coui_core/test/chip_density_test.dart` writes its rungs, so a change to a
// ladder fails here rather than moving implementation and expectation
// together.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

/// Every scaling axis at 1, so a measured pixel is the density's rung and
/// nothing else.
final _theme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    textScaling: 1,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

Future<ResolvedChip> _resolve(
  WidgetTester tester,
  CoreChipSize size,
  CoreDensity density,
) async {
  late ResolvedChip resolved;
  await tester.pumpWidget(
    CoUIApp(
      theme: _theme,
      density: density,
      home: w.Builder(
        builder: (context) {
          resolved = resolveChip(
            context,
            variant: CoreChipVariant.outlined,
            chipColor: CoreChipColor.neutral,
            emphasis: CoreChipEmphasis.high,
            size: size,
            selected: false,
            enabled: true,
          );
          return const w.SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return resolved;
}

void main() {
  for (final (density, corners) in [
    (CoreDensity.compact, [6.0, 8.0, 8.0]),
    (CoreDensity.standard, [6.0, 8.0, 10.0]),
    (CoreDensity.spacious, [8.0, 10.0, 12.0]),
  ]) {
    testWidgets('chip corners are $corners under ${density.name}', (
      tester,
    ) async {
      const sizes = CoreChipSize.values;
      for (final (i, size) in sizes.indexed) {
        final resolved = await _resolve(tester, size, density);
        expect(
          resolved.castBorderRadius.topLeft.x,
          corners[i],
          reason: '${size.name} under ${density.name}',
        );
      }
    });

    testWidgets('chip heights stay 28 · 32 · 40 under ${density.name}', (
      tester,
    ) async {
      final heights = [
        for (final size in CoreChipSize.values)
          (await _resolve(tester, size, density)).minHeight,
      ];
      expect(heights, [28.0, 32.0, 40.0]);
    });
  }
}
