import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Skeleton Golden', () {
    // `pumpOnce` — an enabled `Skeleton` starts a repeating pulse
    // `AnimationController` (`..repeat(reverse: true)`) in
    // `didChangeDependencies`, so the default `onlyPumpAndSettle` pump
    // action would never observe a settled frame.
    goldenTest(
      'all variants',
      fileName: 'skeleton_variants',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'rectangular',
            child: buildGoldenTestApp(
              const Skeleton(width: 200, height: 20),
            ),
          ),
          GoldenTestScenario(
            name: 'circular',
            child: buildGoldenTestApp(const Skeleton.circle(size: 48)),
          ),
          GoldenTestScenario(
            name: 'text',
            child: buildGoldenTestApp(const Skeleton.text()),
          ),
        ],
      ),
    ).ignore();
  });
}
