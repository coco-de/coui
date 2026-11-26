import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

final List<CoreTrendPoint> _points = [
  for (final (i, v) in [12.0, 47.0, 33.0, -8.0, 0.0, 25.0, 61.0].indexed)
    CoreTrendPoint(
      date: DateTime(2026, 1, i + 1),
      value: v,
      label: '1/${i + 1}',
      valueLabel: '${v.toInt()}',
    ),
];

// The harness paints no theme surface, so each chart sits on its theme's
// own surface — otherwise the dark set draws light-on-light and shows
// nothing.
Widget _chart(CoreTrendChartVariant variant) => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface.toValue(),
    child: SizedBox(width: 320, child: _trendChart(variant)),
  ),
);

Widget _trendChart(CoreTrendChartVariant variant) => TrendChart(
  variant: variant,
  semanticLabel: 'Trend',
  periods: const ['7D', '30D', '12M'],
  selectedPeriodIndex: 0,
  referenceValue: 40,
  referenceLabel: 'Target 40',
  points: _points,
);

void main() {
  group('TrendChart Golden', () {
    for (final (name, preset) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      goldenTest(
        'variants — $name',
        fileName: 'trend_chart_$name',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 340),
          children: [
            for (final variant in CoreTrendChartVariant.values)
              GoldenTestScenario(
                name: variant.name,
                child: buildGoldenTestApp(
                  _chart(variant),
                  theme: ThemeData.fromCore(preset),
                ),
              ),
            GoldenTestScenario(
              name: 'line rtl',
              child: buildGoldenTestApp(
                _chart(CoreTrendChartVariant.line),
                theme: ThemeData.fromCore(preset),
                textDirection: .rtl,
              ),
            ),
          ],
        ),
      ).ignore();
    }
  });
}
