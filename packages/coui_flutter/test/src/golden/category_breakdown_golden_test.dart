import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

const List<CoreCategoryBreakdownItem> _items = [
  CoreCategoryBreakdownItem(label: 'Billing', value: 128, valueLabel: '128'),
  CoreCategoryBreakdownItem(label: 'Shipping', value: 61, valueLabel: '61'),
  CoreCategoryBreakdownItem(label: 'Account', value: 33, valueLabel: '33'),
  CoreCategoryBreakdownItem(label: 'Other', value: 0, valueLabel: '0'),
];

// The harness paints no theme surface, so each chart sits on its theme's
// own surface — otherwise the dark set draws light-on-light.
Widget _chart(CoreCategoryBreakdownVariant variant) => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface.toValue(),
    child: SizedBox(width: 360, child: _breakdown(variant)),
  ),
);

Widget _breakdown(CoreCategoryBreakdownVariant variant) => CategoryBreakdown(
  variant: variant,
  semanticLabel: 'Breakdown',
  center: variant == .donut ? const Text('222') : null,
  items: _items,
);

void main() {
  group('CategoryBreakdown Golden', () {
    for (final (name, preset) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      goldenTest(
        'variants — $name',
        fileName: 'category_breakdown_$name',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 380),
          children: [
            for (final variant in CoreCategoryBreakdownVariant.values)
              GoldenTestScenario(
                name: variant.name,
                child: buildGoldenTestApp(
                  _chart(variant),
                  theme: ThemeData.fromCore(preset),
                ),
              ),
            GoldenTestScenario(
              name: 'bar rtl',
              child: buildGoldenTestApp(
                _chart(CoreCategoryBreakdownVariant.bar),
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
