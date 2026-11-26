import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

// #5351 — a horizontal Stepper's step columns are bounded by the row, so a
// label that does not fit wraps inside its own column instead of pushing
// the row past its edge. The overflow claim itself is pinned by
// `test/components/layout/stepper_overflow_test.dart`; these goldens pin
// how the bounded columns look — labels that fit unchanged, labels that
// do not wrapped under their indicator — in both brightnesses.

Widget _stepper(double width, List<String> labels, {int currentStep = 1}) {
  return SizedBox(
    width: width,
    child: Stepper(
      steps: [for (final label in labels) CoreStepItem(label: label)],
      currentStep: currentStep,
    ),
  );
}

void main() {
  group('Stepper Golden', () {
    for (final (name, preset) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      final theme = ThemeData.fromCore(preset);
      goldenTest(
        'horizontal steps — $name',
        fileName: 'stepper_horizontal_$name',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 520),
          children: [
            GoldenTestScenario(
              name: 'labels that fit ($name)',
              child: buildGoldenTestApp(
                _stepper(480, const ['Account', 'Details', 'Confirm']),
                theme: theme,
              ),
            ),
            GoldenTestScenario(
              name: 'long labels wrap in their column ($name)',
              child: buildGoldenTestApp(
                _stepper(360, const [
                  '받는 사람 정보 입력하기',
                  '송금 금액과 환율 확인하기',
                  '본인 인증 및 약관 동의',
                  '최종 송금 내역 검토하기',
                ]),
                theme: theme,
              ),
            ),
            GoldenTestScenario(
              name: 'unbreakable compounds stay in the row ($name)',
              child: buildGoldenTestApp(
                _stepper(360, const [
                  'Empfängerinformationen',
                  'Überweisungsbetragsbestätigung',
                  'Identitätsüberprüfung',
                ], currentStep: 2),
                theme: theme,
              ),
            ),
          ],
        ),
      ).ignore();
    }
  });
}
