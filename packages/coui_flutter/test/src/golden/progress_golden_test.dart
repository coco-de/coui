import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Progress Golden', () {
    // `pumpOnce` — the indeterminate scenario starts a repeating
    // `AnimationController` (`..repeat()`), which never settles. The
    // default `onlyPumpAndSettle` would pump until Flutter's fake test
    // clock hits its 10-minute ceiling and throws. A single pump still
    // renders the determinate scenarios correctly since their implicit
    // animations resolve to their target value on the very first frame.
    goldenTest(
      'linear variants',
      fileName: 'progress_variants',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        // `GoldenTestGroup`'s default `IntrinsicColumnWidth` asks every
        // cell for its max intrinsic width, and every `Progress` branch
        // (determinate and indeterminate) contains a `LayoutBuilder` —
        // Flutter's `LayoutBuilder` explicitly refuses intrinsic-
        // dimension queries ("does not support returning intrinsic
        // dimensions"). A *tight* width constraint short-circuits that
        // query before it reaches the `LayoutBuilder`:
        // `RenderConstrainedBox.computeMaxIntrinsicWidth` returns the
        // constraint's own width immediately whenever it is bounded
        // and tight, without recursing into the child.
        scenarioConstraints: const BoxConstraints.tightFor(width: 300),
        children: [
          GoldenTestScenario(
            name: '0%',
            child: buildGoldenTestApp(
              const Progress(value: 0, disableAnimation: true),
            ),
          ),
          GoldenTestScenario(
            name: '50%',
            child: buildGoldenTestApp(
              const Progress(value: 0.5, disableAnimation: true),
            ),
          ),
          GoldenTestScenario(
            name: '100%',
            child: buildGoldenTestApp(
              const Progress(value: 1, disableAnimation: true),
            ),
          ),
          GoldenTestScenario(
            name: 'indeterminate',
            child: buildGoldenTestApp(const Progress()),
          ),
        ],
      ),
    ).ignore();

    goldenTest(
      'radial variants',
      fileName: 'radial_progress_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 200),
        children: [
          GoldenTestScenario(
            name: '0',
            child: buildGoldenTestApp(
              const RadialProgress(value: 0, showValueText: true),
            ),
          ),
          GoldenTestScenario(
            name: '50',
            child: buildGoldenTestApp(
              const RadialProgress(value: 50, showValueText: true),
            ),
          ),
          GoldenTestScenario(
            name: '100',
            child: buildGoldenTestApp(
              const RadialProgress(value: 100, showValueText: true),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
