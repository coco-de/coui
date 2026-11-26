// A disabled selected radio is told from a disabled unselected one by its
// ring alone — the dot is not drawn by default. These tests hold the colours
// the two disabled rings wear, and that the selected one stands off its fill.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../tool/check_contrast.dart' show auditedSchemes;

void main() {
  final vs = CoreRadioGroupStyle
      .defaultsByVariant[CoreRadioGroupVariant.defaultVariant]!;

  group('the disabled rings', () {
    test('a selected ring reads in disabledContent, an unselected one rests '
        'on disabledOutline', () {
      expect(
        vs.disabledActiveColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        vs.disabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        vs.disabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
    });

    test('the two disabled rings differ — the selection has a mark', () {
      expect(vs.disabledActiveColor, isNot(vs.disabledBorderColor));
    });

    // The selected width is the other half of the mark: a disabled selected
    // ring keeps it, so it is heavier than the resting one on every size that
    // states a selected width.
    test('the selected ring is heavier than the resting ring on every size '
        'that states one', () {
      for (final entry in CoreRadioGroupStyle.defaultsBySize.entries) {
        final row = entry.value;
        final selected = row.selectedIndicatorBorderWidth;
        if (selected == null) continue;
        expect(
          selected,
          greaterThan(row.indicatorBorderWidth!),
          reason: 'CoreComponentSize.${entry.key.name}',
        );
      }
    });

    // The ring is a graphics mark (WCAG 1.4.11 reads a component's visual
    // boundary at 3:1; a disabled control is exempt from it, but this ring is
    // the one thing that says "selected" once the dot is gone). Measured on
    // every scheme the contrast gate audits.
    //
    // CoUI's light schemes draw `disabledContent` at neutral 400 (#5748), so
    // there the ring stands off its fill at 1.89:1 — a designer decision; the
    // heavier selected width still marks the selection. The lower floor pins
    // that value so a further drift fails.
    group('the disabled selected ring stands off its fill (≥ 3:1)', () {
      const graphicsFloor = 3.0;
      const couiLightFloor = 1.85;

      for (final audited in auditedSchemes()) {
        final floor = _isCouiLight(audited.key)
            ? couiLightFloor
            : graphicsFloor;
        test(audited.key, () {
          CoreColor opaque(CoreColor c) =>
              CoreColor(audited.scheme.resolve(c).argb | 0xFF000000);
          final ratio = CoreContrast.ratio(
            opaque(vs.disabledActiveColor),
            opaque(vs.disabledBackgroundColor),
          );
          expect(
            ratio,
            greaterThanOrEqualTo(floor),
            reason:
                'disabled selected ring on its fill is '
                '${ratio.toStringAsFixed(2)}:1 in ${audited.key}',
          );
        });
      }
    });
  });
}

/// CoUI's light schemes (plain and preset) — the ones whose disabled
/// content sits at neutral 400 (#5748). High contrast keeps its own step.
// CoUI's light disabled tones (#5748), and those of a brand registered by
// colour — it reads CoUI's mapping for every disabled slot.
bool _isCouiLight(String key) {
  final prefix = key.split(' ').first;
  final couiMapping = prefix == 'coui' || prefix == 'brand';

  return couiMapping &&
      !key.contains('high-contrast') &&
      (key == '$prefix light' || key.endsWith('(light)'));
}
