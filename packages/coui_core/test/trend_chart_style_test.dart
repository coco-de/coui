import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTrendChartGeometry', () {
    test('rounds the domain outward to a nice step', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [12, 47, 33],
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      expect(g.domainMin, 10);
      expect(g.domainMax, 50);
      expect(g.ticks, const [10, 20, 30, 40, 50]);
      expect(g.tickDecimals, 0);
    });

    test('a bar domain always contains zero; a line domain does not', () {
      const values = [120.0, 140.0];
      final bar = CoreTrendChartGeometry.compute(
        values: values,
        variant: CoreTrendChartVariant.bar,
        tickCount: 4,
      );
      final line = CoreTrendChartGeometry.compute(
        values: values,
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      expect(bar.domainMin, 0);
      expect(bar.baselineFraction, 0);
      expect(line.domainMin, greaterThan(0));
    });

    test('negative values put the baseline inside the plot', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [-20, 0, 20],
        variant: CoreTrendChartVariant.bar,
        tickCount: 4,
      );
      expect(g.baselineFraction, closeTo(0.5, 1e-9));
      expect(g.pointFractions, [
        closeTo(0, 1e-9),
        closeTo(0.5, 1e-9),
        closeTo(1, 1e-9),
      ]);
    });

    test('a flat or single-point series gets an extent', () {
      for (final values in const [
        [5.0],
        [5.0, 5.0],
        [0.0],
      ]) {
        final g = CoreTrendChartGeometry.compute(
          values: values,
          variant: CoreTrendChartVariant.line,
          tickCount: 4,
        );
        expect(g.domainMax, greaterThan(g.domainMin), reason: '$values');
        for (final f in g.pointFractions) {
          expect(f, inInclusiveRange(0, 1));
        }
      }
    });

    test('empty input still yields a drawable axis', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [],
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      expect(g.ticks.length, greaterThanOrEqualTo(2));
      expect(g.pointFractions, isEmpty);
    });

    test('the reference value widens the domain', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [10, 20],
        referenceValue: 100,
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      expect(g.domainMax, greaterThanOrEqualTo(100));
      expect(g.referenceFraction, closeTo(1, 1e-9));
    });

    test('fractional steps keep their decimals and never print -0', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [-0.4, 0.3],
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      expect(g.tickDecimals, 1);
      expect(g.ticks.map(g.formatTick), contains('0.0'));
      expect(g.ticks.map(g.formatTick), isNot(contains('-0.0')));
    });

    test('ticks are evenly spaced on the plot', () {
      final g = CoreTrendChartGeometry.compute(
        values: const [3, 97],
        variant: CoreTrendChartVariant.line,
        tickCount: 4,
      );
      final gap = g.tickFraction(1) - g.tickFraction(0);
      for (var i = 1; i < g.ticks.length; i++) {
        expect(g.tickFraction(i) - g.tickFraction(i - 1), closeTo(gap, 1e-9));
      }
      expect(g.tickFraction(0), 0);
      expect(g.tickFraction(g.ticks.length - 1), closeTo(1, 1e-9));
    });

    test('date labels: first, middle and last only', () {
      expect(CoreTrendChartGeometry.dateLabelIndices(0), isEmpty);
      expect(CoreTrendChartGeometry.dateLabelIndices(1), [0]);
      expect(CoreTrendChartGeometry.dateLabelIndices(2), [0, 1]);
      expect(CoreTrendChartGeometry.dateLabelIndices(7), [0, 3, 6]);
      expect(CoreTrendChartGeometry.dateLabelIndices(30), [0, 14, 29]);
    });

    test('slot centres split the width evenly', () {
      expect(CoreTrendChartGeometry.slotCenter(0, 4), 0.125);
      expect(CoreTrendChartGeometry.slotCenter(3, 4), 0.875);
    });

    test('fallback date label is ISO and locale-neutral', () {
      expect(
        CoreTrendChartGeometry.formatDate(DateTime(2026, 3, 7)),
        '2026-03-07',
      );
    });
  });

  group('CoreTrendChartStyle', () {
    test('merge: right side wins, nested text style merges', () {
      const base = CoreTrendChartStyle(
        lineWidth: 2,
        axisLabelStyle: CoreTextStyle(fontSize: 11),
      );
      const patch = CoreTrendChartStyle(
        lineWidth: 3,
        axisLabelStyle: CoreTextStyle(fontWeight: 600),
      );
      final merged = base.merge(patch);
      expect(merged.lineWidth, 3);
      expect(merged.axisLabelStyle?.fontSize, 11);
      expect(merged.axisLabelStyle?.fontWeight, 600);
    });

    test('equality covers every field', () {
      expect(
        const CoreTrendChartStyle(plotHeight: 100),
        isNot(const CoreTrendChartStyle(plotHeight: 120)),
      );
      expect(
        const CoreTrendChartStyle(axisTickCount: 4),
        const CoreTrendChartStyle(axisTickCount: 4),
      );
      expect(
        const CoreTrendChartStyle(axisTickCount: 4).hashCode,
        const CoreTrendChartStyle(axisTickCount: 4).hashCode,
      );
    });

    test('theme equality compares variant styles by value', () {
      const a = CoreTrendChartTheme(
        variantStyles: {
          CoreTrendChartVariant.bar: CoreTrendChartStyle(barSpacing: 2),
        },
      );
      const b = CoreTrendChartTheme(
        variantStyles: {
          CoreTrendChartVariant.bar: CoreTrendChartStyle(barSpacing: 2),
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('variant defaults to line', () {
      expect(CoreTrendChartVariant.defaultVariant, CoreTrendChartVariant.line);
    });
  });
}
