import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Loading Golden', () {
    // `pumpOnce` — every `Loading` variant starts a repeating
    // `AnimationController` (`..repeat()`) in `initState`, so the
    // default `onlyPumpAndSettle` pump action would never observe a
    // settled frame and would eventually throw a pump-timeout error.
    goldenTest(
      'all variants',
      fileName: 'loading_variants',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'spinner',
            child: buildGoldenTestApp(
              const Loading(),
            ),
          ),
          GoldenTestScenario(
            name: 'dots',
            child: buildGoldenTestApp(
              const Loading(variant: CoreLoadingVariant.dots),
            ),
          ),
          GoldenTestScenario(
            name: 'bar',
            child: buildGoldenTestApp(
              const Loading(variant: CoreLoadingVariant.bar),
            ),
          ),
          GoldenTestScenario(
            name: 'pulse',
            child: buildGoldenTestApp(
              const Loading(variant: CoreLoadingVariant.pulse),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
