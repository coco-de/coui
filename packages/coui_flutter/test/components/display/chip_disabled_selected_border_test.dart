// The selected disabled chip draws no border, and — separately — that border
// takes no space.
//
// Those are two claims, and the sibling emphasis test only makes the first
// one: it reads `containerStyle.borderColor` and stops there. A resolver that
// names the transparent sentinel while still handing the composed
// `OutlinedContainer` a 1px width would pass it, and the pill would render one
// pixel wider per side than the designer's stroke-less copy — which is exactly
// the shape the canvas measured (46 → 47).
//
// So this reads the value at the point the widget consumes it: `chip.dart`
// hands `resolved.containerStyle` straight to `OutlinedContainer`, so resolving
// that container with the same style is the width the box actually gets.
import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/display/chip/chip_style.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Resolves a chip and then the `OutlinedContainer` it composes, the way
/// `chip.dart` does — `containerStyle` forwarded verbatim, default surface
/// role, no per-instance container override.
Future<({ResolvedChip chip, ResolvedOutlinedContainer box})> _resolve(
  WidgetTester tester, {
  required CoreChipColor chipColor,
  required bool selected,
  bool enabled = false,
  CoreColor? seedColor,
}) async {
  late ResolvedChip chip;
  late ResolvedOutlinedContainer box;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            chip = resolveChip(
              context,
              variant: CoreChipVariant.outlined,
              chipColor: chipColor,
              emphasis: CoreChipEmphasis.high,
              size: CoreChipSize.md,
              selected: selected,
              enabled: enabled,
              seedColor: seedColor,
            );
            box = resolveOutlinedContainer(
              context,
              containerStyle: chip.containerStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (chip: chip, box: box);
}

void main() {
  group('Chip selected+disabled border', () {
    testWidgets('every colour: no stroke, and it eats no layout', (
      tester,
    ) async {
      for (final color in CoreChipColor.values) {
        // `custom` derives from a seed, so it needs one to reach its own
        // branch — the disabled rows drop the seed either way, and that is
        // the point: both branches route through the same shared sentinel.
        final seed = color == CoreChipColor.custom
            ? const CoreColor.token(CoreColors.primary)
            : null;
        final selected = await _resolve(
          tester,
          chipColor: color,
          selected: true,
          seedColor: seed,
        );
        expect(
          selected.chip.containerStyle.borderColor,
          CoreColor.transparent,
          reason: '${color.name}: selected disabled states no border',
        );
        expect(
          selected.box.borderWidth,
          0.0,
          reason:
              '${color.name}: a transparent border still insets the box unless '
              'its width collapses — that is the pixel the canvas measured',
        );

        // The unselected disabled row is the control: it keeps its hairline,
        // so a collapse that fired for every disabled chip would show here.
        final unselected = await _resolve(
          tester,
          chipColor: color,
          selected: false,
          seedColor: seed,
        );
        expect(
          unselected.chip.containerStyle.borderColor,
          isNot(CoreColor.transparent),
          reason: '${color.name}: unselected disabled keeps its hairline',
        );
        expect(
          unselected.box.borderWidth,
          greaterThan(0),
          reason: '${color.name}: and that hairline still takes its width',
        );
      }
    });

    testWidgets('the enabled selected chip is untouched — border is its fill', (
      tester,
    ) async {
      // Stating the fill as the border is right while enabled and wrong while
      // disabled; this pins that the fix did not spread to the enabled row.
      final enabled = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        selected: true,
        enabled: true,
      );
      expect(
        enabled.chip.containerStyle.borderColor,
        isNot(CoreColor.transparent),
      );
      expect(enabled.box.borderWidth, greaterThan(0));
    });
  });
}
