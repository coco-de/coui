/// A chip's corners (6 · 8 · 10) sit on the radius band a density moves, its
/// heights do not — the chip is a row on its own ladder, and a density moves
/// a row's height only for a row on the control ladder.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chip corner under a density', () {
    test('standard moves nothing', () {
      for (final size in CoreChipSize.values) {
        final corner = CoreChipStyle.defaultsBySize[size]!.borderRadius!;
        expect(
          CoreDensity.standard.radius(corner.topLeft),
          corner.topLeft,
          reason: size.name,
        );
      }
    });

    test('compact steps a corner down a rung and stops at 8', () {
      expect(
        [
          for (final size in CoreChipSize.values)
            CoreDensity.compact.radius(
              CoreChipStyle.defaultsBySize[size]!.borderRadius!.topLeft,
            ),
        ],
        [6, 8, 8],
      );
    });

    test('spacious steps a corner up a rung', () {
      expect(
        [
          for (final size in CoreChipSize.values)
            CoreDensity.spacious.radius(
              CoreChipStyle.defaultsBySize[size]!.borderRadius!.topLeft,
            ),
        ],
        [8, 10, 12],
      );
    });

    test('the pill a caller states stays a pill — it is off the band', () {
      for (final density in CoreDensity.values) {
        expect(
          density.radius(CoreRadius.radius9999),
          CoreRadius.radius9999,
          reason: density.name,
        );
      }
    });

    test('the heights are stated floors, not rows of the control ladder', () {
      // The corner moves with the density; the height does not, because the
      // chip's heights are its own (28 · 32 · 40) and `controlHeight` is only
      // for a row on the control ladder.
      expect(
        [
          for (final size in CoreChipSize.values)
            CoreChipStyle.defaultsBySize[size]!.minHeight,
        ],
        [CoreSize.size28, CoreSize.size32, CoreSize.size40],
      );
    });
  });
}
