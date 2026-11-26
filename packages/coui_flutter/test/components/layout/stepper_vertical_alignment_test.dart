import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

const _steps = [
  CoreStepItem(label: 'Step 1', description: 'Account details'),
  CoreStepItem(label: 'Step 2'),
  CoreStepItem(label: 'Step 3'),
];

void main() {
  setUpAll(loadParityFonts);

  Future<void> pump(
    WidgetTester tester, {
    CoreStepperStyle? style,
    CoreDensity density = .standard,
    double scale = 1,
    double? width,
    bool enabled = true,
    List<CoreStepItem> steps = _steps,
  }) async {
    await tester.pumpWidget(
      KeyedSubtree(
        key: UniqueKey(),
        child: buildTestApp(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SizedBox(
              width: width,
              child: Stepper(
                steps: steps,
                currentStep: 1,
                enabled: enabled,
                orientation: .vertical,
                stepperStyle: style,
              ),
            ),
          ),
          density: density,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  List<Rect> rows(WidgetTester tester) => find
      .descendant(
        of: find.byType(Stepper),
        matching: find.byType(IntrinsicHeight),
      )
      .evaluate()
      .map((e) => tester.getRect(find.byWidget(e.widget)))
      .toList();
  List<Rect> lines(WidgetTester tester) => find
      .descendant(
        of: find.byType(Stepper),
        matching: find.byType(Divider),
      )
      .evaluate()
      .map((e) => tester.getRect(find.byWidget(e.widget)))
      .toList();

  for (final enabled in [true, false]) {
    testWidgets('copy geometry, enabled=$enabled', (tester) async {
      await pump(tester, enabled: enabled);
      final rs = rows(tester);
      final ls = lines(tester);
      expect(rs.map((r) => r.height), [65, 43, 24]);
      // Row minus the circle: the line leaves one circle and reaches the next
      // with no margin on either side.
      expect(ls.map((r) => r.height), [41, 19]);
      expect(rs.last.bottom - rs.first.top, 132);
      for (var i = 0; i < 3; i++) {
        final label = tester.getRect(find.text('Step ${i + 1}'));
        expect(label.top - rs[i].top, 1);
        expect(label.height, 22);
        if (i < 2) {
          expect(ls[i].top - rs[i].top, 24);
          expect(rs[i].bottom - ls[i].bottom, 0);
        }
      }
      expect(ls.length, 2, reason: 'no connector after the final step');
    });
  }

  testWidgets('density moves padding while first-line alignment stays put', (
    tester,
  ) async {
    for (final sample in [
      (CoreDensity.compact, [61, 39, 24], [37, 15]),
      (CoreDensity.spacious, [69, 47, 24], [45, 23]),
    ]) {
      await pump(tester, density: sample.$1);
      expect(rows(tester).map((r) => r.height), sample.$2);
      expect(lines(tester).map((r) => r.height), sample.$3);
      expect(
        tester.getRect(find.text('Step 3')).top - rows(tester).last.top,
        1,
      );
    }
  });

  testWidgets('full parity fixture retains cumulative height', (tester) async {
    await pump(
      tester,
      steps: const [
        CoreStepItem(label: 'Step 1', description: 'Account details'),
        CoreStepItem(label: 'Step 2', description: 'Payment info'),
        CoreStepItem(label: 'Step 3', description: 'Review & submit'),
      ],
    );
    final rs = rows(tester);
    expect(rs.map((r) => r.height), [65, 65, 45]);
    expect(rs.last.bottom - rs.first.top, 175);
    expect(lines(tester).map((r) => r.height), [41, 41]);
  });

  testWidgets('fixed half-pixel line metric rounds upward for alignment', (
    tester,
  ) async {
    await pump(
      tester,
      style: const CoreStepperStyle(
        labelStyle: CoreTextStyle(lineHeightPx: 21.5),
      ),
    );
    final rs = rows(tester);
    expect(tester.getRect(find.text('Step 1')).height, 22);
    expect(tester.getRect(find.text('Step 1')).top - rs.first.top, 1);
  });

  testWidgets('first line, not full paragraph, anchors a multi-line title', (
    tester,
  ) async {
    await pump(
      tester,
      steps: [
        const CoreStepItem(label: 'Step 1\nSecond line'),
        ..._steps.skip(1),
      ],
    );
    expect(rows(tester).map((r) => r.height), [65, 43, 24]);
    expect(
      tester.getRect(find.text('Step 1\nSecond line')).top -
          rows(tester).first.top,
      1,
    );
    expect(tester.getRect(find.text('Step 1\nSecond line')).height, 44);
  });

  testWidgets('wrapping uses the first line at the available width', (
    tester,
  ) async {
    const title = 'A rather long step title for wrapping';
    await pump(
      tester,
      width: 120,
      steps: [
        const CoreStepItem(label: title),
        ..._steps.skip(1),
      ],
    );
    final label = tester.getRect(find.text(title));
    expect(label.height, greaterThan(22));
    expect(label.top - rows(tester).first.top, 1);
    expect(lines(tester).first.height, rows(tester).first.height - 24);
  });

  testWidgets('text scaling and overrides do not cache alignment', (
    tester,
  ) async {
    await pump(tester, scale: 1.5);
    expect(rows(tester).map((r) => r.height), [85, 54, 34]);
    expect(tester.getRect(find.text('Step 1')).top - rows(tester).first.top, 0);
    await pump(tester, style: const CoreStepperStyle(indicatorSize: 32));
    expect(rows(tester).map((r) => r.height), [69, 47, 32]);
    expect(tester.getRect(find.text('Step 1')).top - rows(tester).first.top, 5);
    await pump(
      tester,
      style: const CoreStepperStyle(labelStyle: CoreTextStyle(fontSize: 20)),
    );
    expect(tester.getRect(find.text('Step 1')).top - rows(tester).first.top, 0);
  });

  testWidgets('per-state type overlays determine each visible first line', (
    tester,
  ) async {
    await pump(
      tester,
      style: const CoreStepperStyle(
        labelActiveStyle: CoreTextStyle(lineHeight: 1.8),
        labelUpcomingStyle: CoreTextStyle(fontSize: 10),
      ),
    );
    final rs = rows(tester);
    expect(tester.getRect(find.text('Step 1')).top - rs[0].top, 1);
    expect(tester.getRect(find.text('Step 2')).top - rs[1].top, 0);
    expect(tester.getRect(find.text('Step 3')).top - rs[2].top, 5);
  });

  testWidgets('authored insets survive; last row still omits them', (
    tester,
  ) async {
    await pump(
      tester,
      style: const CoreStepperStyle(
        stepPadding: CoreEdgeInsets.only(top: 4, bottom: 12),
      ),
    );
    expect(rows(tester).map((r) => r.height), [61, 39, 24]);
    expect(tester.getRect(find.text('Step 1')).top - rows(tester).first.top, 5);
    expect(tester.getRect(find.text('Step 3')).top - rows(tester).last.top, 1);
    await pump(
      tester,
      style: const CoreStepperStyle(stepPadding: CoreEdgeInsets.zero),
    );
    expect(rows(tester).map((r) => r.height), [45, 32, 24]);
    expect(tester.getRect(find.text('Step 1')).top - rows(tester).first.top, 1);
  });
}
