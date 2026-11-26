import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/test/fixtures/loading_bar_motion_cases.dart';
import '../helpers/test_app.dart';

void main() {
  for (final scenario in kLoadingBarMotionCases) {
    testWidgets(
      '${scenario.name}: native bar follows the same shared cycle samples',
      (tester) async {
        await pumpTestApp(
          tester,
          Loading(
            variant: .bar,
            componentSize: scenario.componentSize,
            loadingStyle: scenario.style,
          ),
          componentTheme: CoreComponentTheme(loading: scenario.theme),
        );
        final rows = <Map<String, Object?>>[];
        var previous = Duration.zero;
        for (final phase in kLoadingBarMotionPhases) {
          final elapsed = Duration(
            microseconds: (phase * scenario.durationMs * 1000).round(),
          );
          await tester.pump(elapsed - previous);
          previous = elapsed;
          final transform = tester.widget<Transform>(
            find.descendant(
              of: find.byType(Loading),
              matching: find.byType(Transform),
            ),
          );
          final actual = transform.transform.storage[12];
          final eased = CoreEasing.move.toValue().transform(phase % 1);
          final expected =
              scenario.length *
              (1 - CoreLoadingStyle.defaultBarFillRatio) *
              math.sin(eased * math.pi);
          expect(actual, closeTo(expected, 0.005), reason: 't=$phase');
          rows.add({
            'case': scenario.name,
            't': phase,
            'actualDx': actual,
            'expectedDx': expected,
            'exactDx':
                scenario.length *
                (1 - CoreLoadingStyle.defaultBarFillRatio) *
                math.sin(CoreEasing.move.transform(phase % 1) * math.pi),
          });
        }
        final evidence = Platform.environment['COUI_LOADING_MOTION_EVIDENCE'];
        if (evidence != null) {
          Directory(evidence).createSync(recursive: true);
          File(
            '$evidence/flutter-${scenario.name}.json',
          ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
        }
      },
    );
  }
}
