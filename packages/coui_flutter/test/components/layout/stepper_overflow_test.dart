import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// #5351 — a horizontal Stepper overflowed its row by 12px in a 768px
// wizard. The row has to hold for any step count, label length and text
// scale a consumer can reach: a label that does not fit wraps inside its
// own column instead of pushing the row past its edge.

const _kWidths = [360.0, 768.0];
const _kStepCounts = [3, 4, 5];
const _kTextScales = [1.0, 1.3, 2.0];

/// Long labels in the two scripts the demos ship — Korean phrases, and
/// German compounds that have no break opportunity inside the word.
const _kLabels = <String, List<String>>{
  'ko': [
    '받는 사람 정보 입력하기',
    '송금 금액과 환율 확인하기',
    '본인 인증 및 약관 동의',
    '최종 송금 내역 검토하기',
    '송금 완료 및 영수증 발급',
  ],
  'de': [
    'Empfängerinformationen',
    'Überweisungsbetragsbestätigung',
    'Identitätsüberprüfung',
    'Zusammenfassungsübersicht',
    'Überweisungsabschluss',
  ],
};

Widget _harness({
  required double width,
  required double textScale,
  required List<CoreStepItem> steps,
  int currentStep = 1,
}) {
  return CoUIApp(
    theme: const ThemeData(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Stepper(steps: steps, currentStep: currentStep),
        ),
      ),
    ),
  );
}

void main() {
  for (final MapEntry(key: language, value: labels) in _kLabels.entries) {
    for (final width in _kWidths) {
      for (final count in _kStepCounts) {
        for (final scale in _kTextScales) {
          testWidgets(
            'horizontal $language · ${width.toInt()}px · $count steps · '
            '×$scale has no overflow',
            (tester) async {
              tester.view.physicalSize = const Size(1024, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                _harness(
                  width: width,
                  textScale: scale,
                  steps: [
                    for (final label in labels.take(count))
                      CoreStepItem(label: label),
                  ],
                ),
              );
              await tester.pumpAndSettle();

              // A RenderFlex overflow is reported through FlutterError.
              expect(tester.takeException(), isNull);
              final row = tester.renderObject<RenderBox>(
                find.byType(Stepper),
              );
              expect(row.size.width, lessThanOrEqualTo(width));
            },
          );
        }
      }
    }
  }

  testWidgets('labels that fit keep their natural width', (tester) async {
    // The bound only bites when a label would not fit; short labels are
    // laid out exactly as before, so a fitting row does not change.
    const steps = [
      CoreStepItem(label: 'Account'),
      CoreStepItem(label: 'Details'),
      CoreStepItem(label: 'Confirm'),
    ];
    await tester.pumpWidget(
      _harness(width: 768, textScale: 1, steps: steps),
    );
    await tester.pumpAndSettle();

    for (final step in steps) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text(step.label).last,
          matching: find.byType(RichText),
        ),
      );
      // Laid out at least as wide as its unwrapped text → one line.
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
        ),
      );
    }
  });

  testWidgets(
    'a horizontal stepper answers intrinsic sizes — inside IntrinsicWidth '
    'and IntrinsicHeight, the way content-width Popup and Card wrap it',
    (tester) async {
      final steps = [
        for (final label in _kLabels['de']!.take(3)) CoreStepItem(label: label),
      ];
      for (final wrap in <Widget Function(Widget)>[
        (child) => IntrinsicWidth(child: child),
        (child) => IntrinsicHeight(child: child),
      ]) {
        await tester.pumpWidget(
          CoUIApp(
            theme: const ThemeData(),
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                child: wrap(Stepper(steps: steps, currentStep: 1)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final row = tester.renderObject<RenderBox>(find.byType(Stepper));
        expect(row.size.width, lessThanOrEqualTo(360));
      }
    },
  );

  testWidgets('a right-to-left stepper starts on the right', (tester) async {
    const steps = [
      CoreStepItem(label: 'Account'),
      CoreStepItem(label: 'Details'),
      CoreStepItem(label: 'Confirm'),
    ];
    final ltr = <double>[];
    // Left-to-right first: the mirrored run is measured against it.
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      await tester.pumpWidget(
        CoUIApp(
          theme: const ThemeData(),
          home: Directionality(
            textDirection: direction,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 600,
                child: Stepper(steps: steps, currentStep: 1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final xs = [
        for (final step in steps)
          tester.getCenter(find.text(step.label).last).dx,
      ];
      if (direction == TextDirection.ltr) {
        ltr.addAll(xs);
        expect(xs, orderedEquals([...xs]..sort()));
      } else {
        // Mirrored about the row's centre.
        for (var index = 0; index < xs.length; index += 1) {
          expect(xs[index], closeTo(600 - ltr[index], 0.5));
        }
      }
    }
  });
}
