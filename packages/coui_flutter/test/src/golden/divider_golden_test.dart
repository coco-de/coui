import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Divider Golden', () {
    goldenTest(
      'all variants',
      fileName: 'divider_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 250),
        children: [
          GoldenTestScenario(
            name: 'horizontal',
            child: buildGoldenTestApp(const Divider()),
          ),
          GoldenTestScenario(
            name: 'horizontal with label',
            child: buildGoldenTestApp(
              const Divider(child: Text('OR')),
            ),
          ),
          GoldenTestScenario(
            name: 'vertical',
            // `VerticalDivider`-shaped content needs a bounded height
            // ancestor — the widget itself asks for `height: infinity`
            // internally and relies on a parent (normally a `Row`) to
            // clamp that down, matching real usage.
            child: buildGoldenTestApp(
              const SizedBox(
                height: 80,
                child: Divider(orientation: CoreDividerOrientation.vertical),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'vertical with label',
            child: buildGoldenTestApp(
              const SizedBox(
                height: 100,
                child: Divider(
                  orientation: CoreDividerOrientation.vertical,
                  child: Text('OR'),
                ),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
