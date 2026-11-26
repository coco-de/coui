import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreCategoryBreakdownGeometry', () {
    test('shares divide the total', () {
      final g = CoreCategoryBreakdownGeometry.compute(const [50, 30, 20]);
      expect(g.total, 100);
      expect(g.fractions, [0.5, 0.3, 0.2]);
      expect(g.percents, [50, 30, 20]);
    });

    test('printed percentages always add up to 100', () {
      for (final values in const [
        [1.0, 1.0, 1.0],
        [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0],
        [128.0, 61.0, 33.0, 9.0, 1.0],
        [0.4, 0.3, 0.3],
      ]) {
        final g = CoreCategoryBreakdownGeometry.compute(values);
        expect(
          g.percents.fold<int>(0, (a, b) => a + b),
          100,
          reason: '$values',
        );
      }
    });

    test('largest remainder: three thirds read 34 · 33 · 33', () {
      final g = CoreCategoryBreakdownGeometry.compute(const [1, 1, 1]);
      expect(g.percents, [34, 33, 33]);
      expect(g.percentLabel(0), '34%');
    });

    test('a zero category stays at 0% and never takes a remainder', () {
      final g = CoreCategoryBreakdownGeometry.compute(const [1, 0, 1, 1]);
      expect(g.percents[1], 0);
    });

    test('negative values count as zero', () {
      final g = CoreCategoryBreakdownGeometry.compute(const [-5, 10]);
      expect(g.total, 10);
      expect(g.percents, [0, 100]);
    });

    test('empty input and a zero total are empty', () {
      expect(CoreCategoryBreakdownGeometry.compute(const []).isEmpty, isTrue);
      final zero = CoreCategoryBreakdownGeometry.compute(const [0, 0]);
      expect(zero.isEmpty, isTrue);
      expect(zero.percents, [0, 0]);
    });

    test('arcs tile the ring with gaps between drawn arcs only', () {
      final g = CoreCategoryBreakdownGeometry.compute(
        const [1, 1, 0, 2],
        arcGapTurns: 0.01,
      );
      expect(g.arcStarts[0], closeTo(0.005, 1e-9));
      expect(g.arcSweeps[0], closeTo(0.24, 1e-9));
      expect(g.arcSweeps[2], 0);
      expect(g.arcStarts[3], closeTo(0.505, 1e-9));
      expect(g.arcSweeps[3], closeTo(0.49, 1e-9));
    });

    test('a lone category fills the whole ring', () {
      final g = CoreCategoryBreakdownGeometry.compute(
        const [0, 7],
        arcGapTurns: 0.02,
      );
      expect(g.arcStarts[1], 0);
      expect(g.arcSweeps[1], 1);
    });

    test('gap turns come from the ring centre line', () {
      final turns = CoreCategoryBreakdownGeometry.arcGapTurnsFor(
        gap: 2,
        diameter: 160,
        thickness: 24,
      );
      expect(turns, closeTo(2 / (3.141592653589793 * 136), 1e-12));
    });

    test('value fallback is locale-neutral', () {
      expect(CoreCategoryBreakdownGeometry.formatValue(128), '128');
      expect(CoreCategoryBreakdownGeometry.formatValue(12.5), '12.5');
      expect(CoreCategoryBreakdownGeometry.formatValue(0.25), '0.25');
    });
  });

  group('CoreCategoryBreakdownStyle', () {
    test('merge: right side wins, text styles merge', () {
      const base = CoreCategoryBreakdownStyle(
        barHeight: 8,
        labelStyle: CoreTextStyle(fontSize: 13),
      );
      const patch = CoreCategoryBreakdownStyle(
        barHeight: 12,
        labelStyle: CoreTextStyle(fontWeight: 600),
      );
      final merged = base.merge(patch);
      expect(merged.barHeight, 12);
      expect(merged.labelStyle?.fontSize, 13);
      expect(merged.labelStyle?.fontWeight, 600);
    });

    test('series colours compare by value', () {
      expect(
        const CoreCategoryBreakdownStyle(
          seriesColors: [CoreColor.token(CoreColors.primary)],
        ),
        const CoreCategoryBreakdownStyle(
          seriesColors: [CoreColor.token(CoreColors.primary)],
        ),
      );
      expect(
        const CoreCategoryBreakdownStyle(
          seriesColors: [CoreColor.token(CoreColors.primary)],
        ).hashCode,
        const CoreCategoryBreakdownStyle(
          seriesColors: [CoreColor.token(CoreColors.primary)],
        ).hashCode,
      );
      expect(
        const CoreCategoryBreakdownStyle(
          seriesColors: [CoreColor.token(CoreColors.primary)],
        ),
        isNot(
          const CoreCategoryBreakdownStyle(
            seriesColors: [CoreColor.token(CoreColors.error)],
          ),
        ),
      );
    });

    test('the default palette is token-only', () {
      for (final c in CoreCategoryBreakdownStyle.defaultSeriesColors) {
        expect(c.token, isNotNull);
      }
    });

    test('variant defaults to bar', () {
      expect(
        CoreCategoryBreakdownVariant.defaultVariant,
        CoreCategoryBreakdownVariant.bar,
      );
    });
  });
}
