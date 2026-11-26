// Pins the horizontal connector to the indicator's centre, and the shape of
// the row it sits in.
//
// A horizontal step is a column of one track — a half-line, the circle, a
// half-line — over its label, and every column is an equal share of the row.
// The connector between two steps is the trailing half of one and the leading
// half of the next, so the two meet at the column boundary and read as one
// line; the first step's leading half and the last step's trailing half draw
// nothing.
//
// The line used to be offset by `Padding(top: indicatorSize / 2)` under a
// `Row(crossAxisAlignment: .start)`. That places the line's *top* at the
// indicator's centre, and the line's box is exactly `thickness` tall, so its
// centre landed half a thickness below — a small, permanent misalignment that
// reads as a sloppy seam rather than as a bug.
//
// These read the laid-out rectangles and compare centres. A parity baseline
// would not do: regenerating one encodes whatever the code currently does, so
// reverting the anchor would silently produce a new "correct" baseline.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kSteps = <CoreStepItem>[
  CoreStepItem(label: 'One'),
  CoreStepItem(label: 'Two'),
];

const _kWidth = 400.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: material.SizedBox(width: _kWidth, child: child),
    ),
  ),
);

/// The painted line of every connector half, in reading order — the
/// `Divider`'s own rect, not its padding.
List<Rect> _connectorRects(WidgetTester tester, {required int halves}) {
  final dividers = find.descendant(
    of: find.byType(Stepper),
    matching: find.byType(Divider),
  );
  expect(
    dividers,
    findsNWidgets(halves),
    reason: 'two halves per connector between steps, none beyond the ends',
  );

  return [
    for (final element in dividers.evaluate())
      tester.getRect(find.byWidget(element.widget)),
  ]..sort((a, b) => a.left.compareTo(b.left));
}

/// The first step's circle.
Rect _indicatorRect(WidgetTester tester) => _indicatorRects(tester).first;

/// Every circle, in reading order — located by size rather than by type-order
/// so a wrapper change does not silently retarget the assertion. The ring a
/// circle draws sits inside its own box, so no smaller square is counted.
List<Rect> _indicatorRects(WidgetTester tester) {
  final boxes = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(Stepper),
          matching: find.byType(Container),
        ),
      )
      .toList();
  expect(boxes, isNotEmpty);

  final rects =
      find
          .descendant(
            of: find.byType(Stepper),
            matching: find.byType(Container),
          )
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)))
          .where(
            (r) =>
                r.width == CoreStepperStyle.defaultIndicatorSize &&
                r.height == CoreStepperStyle.defaultIndicatorSize,
          )
          .toList()
        ..sort((a, b) => a.left.compareTo(b.left));
  expect(rects, isNotEmpty, reason: 'the indicator is a square box');

  return rects;
}

void main() {
  group('Stepper horizontal connector', () {
    testWidgets('the line centre sits on the indicator centre', (tester) async {
      await tester.pumpWidget(
        _app(const Stepper(steps: _kSteps)),
      );
      await tester.pumpAndSettle();

      final indicator = _indicatorRect(tester);
      for (final line in _connectorRects(tester, halves: 2)) {
        expect(
          line.center.dy,
          moreOrLessEquals(indicator.center.dy, epsilon: 0.01),
          reason:
              'anchoring the line top — rather than its centre — to the '
              'indicator centre leaves it half a thickness low',
        );
      }
    });

    testWidgets('the line is thinner than the indicator', (tester) async {
      // Guards the assertion above from passing trivially: if the connector
      // ever filled the whole indicator band, the centres would match while
      // the line was plainly wrong.
      await tester.pumpWidget(
        _app(const Stepper(steps: _kSteps)),
      );
      await tester.pumpAndSettle();

      final indicator = _indicatorRect(tester);
      for (final line in _connectorRects(tester, halves: 2)) {
        expect(line.height, lessThan(indicator.height));
        expect(line.height, greaterThan(0));
      }
    });

    testWidgets('every column is an equal share and the circle is centred in '
        'it', (tester) async {
      await tester.pumpWidget(
        _app(const Stepper(steps: _kSteps)),
      );
      await tester.pumpAndSettle();

      final circles = _indicatorRects(tester);
      expect(circles, hasLength(_kSteps.length));
      for (var i = 0; i < circles.length; i++) {
        final share = _kWidth / _kSteps.length;
        expect(
          circles[i].center.dx,
          moreOrLessEquals(share * i + share / 2, epsilon: 0.01),
        );
      }
    });

    testWidgets('the two halves of a connector meet at the column boundary, '
        'and each touches its circle', (tester) async {
      await tester.pumpWidget(
        _app(const Stepper(steps: _kSteps)),
      );
      await tester.pumpAndSettle();

      final circles = _indicatorRects(tester);
      final halves = _connectorRects(tester, halves: 2);

      // The line leaving step one runs from its circle to the boundary, and
      // the line reaching step two from the boundary to its circle: no gap,
      // so it reads as a single connector.
      expect(halves[0].left, moreOrLessEquals(circles[0].right, epsilon: 0.01));
      expect(halves[0].right, moreOrLessEquals(halves[1].left, epsilon: 0.01));
      expect(halves[1].right, moreOrLessEquals(circles[1].left, epsilon: 0.01));
      expect(
        halves[0].right,
        moreOrLessEquals(_kWidth / _kSteps.length, epsilon: 0.01),
      );
    });

    testWidgets('a row with no width to share makes every column as wide as '
        'the widest', (tester) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: const material.Scaffold(
              body: UnconstrainedBox(
                alignment: Alignment.topLeft,
                child: Stepper(
                  steps: [
                    CoreStepItem(label: 'A'),
                    CoreStepItem(label: 'A longer one'),
                    CoreStepItem(label: 'Mid'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final circles = _indicatorRects(tester);
      final gaps = [
        circles[1].center.dx - circles[0].center.dx,
        circles[2].center.dx - circles[1].center.dx,
      ];
      // Equal columns put the circles an equal distance apart, however much
      // wider one label is than the rest.
      expect(gaps[0], moreOrLessEquals(gaps[1], epsilon: 0.01));
      expect(gaps[0], greaterThan(CoreStepperStyle.defaultIndicatorSize));
    });

    testWidgets('each half-line takes the colour of the connector it belongs '
        'to', (tester) async {
      await tester.pumpWidget(
        _app(
          const Stepper(
            currentStep: 1,
            enabled: true,
            steps: [
              CoreStepItem(label: 'One'),
              CoreStepItem(label: 'Two'),
              CoreStepItem(label: 'Three'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final halves =
          tester
              .widgetList<Divider>(
                find.descendant(
                  of: find.byType(Stepper),
                  matching: find.byType(Divider),
                ),
              )
              .toList()
            ..sort(
              (a, b) => tester
                  .getRect(find.byWidget(a))
                  .left
                  .compareTo(tester.getRect(find.byWidget(b)).left),
            );
      // Reading order: step one's trailing half, step two's leading half,
      // step two's trailing half, step three's leading half. The connector
      // between steps one and two is behind the current step (completed); the
      // one between two and three is ahead of it.
      const primary = CoreColor.token(CoreColors.primary);
      const quiet = CoreColor.token(CoreColors.outlineVariant);
      expect(
        [for (final half in halves) half.dividerStyle?.color],
        orderedEquals(const [primary, primary, quiet, quiet]),
      );
    });

    testWidgets('the first and last steps draw no line beyond themselves', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Stepper(
            steps: [
              CoreStepItem(label: 'One'),
              CoreStepItem(label: 'Two'),
              CoreStepItem(label: 'Three'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final circles = _indicatorRects(tester);
      final lines = _connectorRects(tester, halves: 4);

      expect(
        lines.any((line) => line.right <= circles.first.left),
        isFalse,
        reason: 'nothing leads into the first circle',
      );
      expect(
        lines.any((line) => line.left >= circles.last.right),
        isFalse,
        reason: 'nothing leaves the last circle',
      );
    });

    testWidgets('connectorMargin holds each half-line off its circle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Stepper(
            steps: _kSteps,
            stepperStyle: CoreStepperStyle(connectorMargin: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final circles = _indicatorRects(tester);
      final halves = _connectorRects(tester, halves: 2);

      expect(
        halves[0].left,
        moreOrLessEquals(circles[0].right + 6, epsilon: 0.01),
      );
      expect(
        halves[1].right,
        moreOrLessEquals(circles[1].left - 6, epsilon: 0.01),
      );
      // The seam between the two halves is still at the boundary.
      expect(halves[0].right, moreOrLessEquals(halves[1].left, epsilon: 0.01));
    });

    testWidgets('the vertical orientation still renders', (tester) async {
      // The vertical connector was already correct and is deliberately
      // untouched — this only pins that the change did not reach it.
      await tester.pumpWidget(
        _app(
          const Stepper(
            steps: _kSteps,
            orientation: CoreStepperOrientation.vertical,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
    });
  });
}
