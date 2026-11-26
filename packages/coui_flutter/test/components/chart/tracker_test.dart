import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Tracker', () {
    testWidgets('renders with empty segments', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(segments: []),
      );

      expect(find.byType(Tracker), findsOneWidget);
    });

    testWidgets('renders with segments', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(
          segments: [
            CoreTrackerSegment(status: CoreTrackerStatus.fine),
            CoreTrackerSegment(
              status: CoreTrackerStatus.warning,
              tooltip: 'High load',
            ),
          ],
        ),
      );

      expect(find.byType(Tracker), findsOneWidget);
    });
  });

  // Reads the painted `BoxDecoration` of every segment fill — the radius
  // the widget actually hands to the engine, not the resolver's number.
  group('Tracker corner radius', () {
    const segments = [
      CoreTrackerSegment(status: CoreTrackerStatus.fine),
      CoreTrackerSegment(status: CoreTrackerStatus.warning),
      CoreTrackerSegment(status: CoreTrackerStatus.critical),
    ];

    List<BorderRadius?> paintedRadii(WidgetTester tester) => [
      for (final box in tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Tracker),
          matching: find.byType(Container),
        ),
      ))
        if (box.decoration case final BoxDecoration decoration
            when decoration.color != null)
          decoration.borderRadius as BorderRadius?,
    ];

    const rounded2 = Radius.circular(2);

    testWidgets('only the outer ends of the row round, by 2', (tester) async {
      await pumpTestApp(tester, const Tracker(segments: segments));

      expect(paintedRadii(tester), const [
        BorderRadius.horizontal(left: rounded2),
        BorderRadius.zero,
        BorderRadius.horizontal(right: rounded2),
      ]);
    });

    testWidgets('a single segment rounds both of its ends', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(
          segments: [CoreTrackerSegment(status: CoreTrackerStatus.fine)],
        ),
      );

      expect(paintedRadii(tester), const [BorderRadius.all(rounded2)]);
    });

    testWidgets('rounded: false paints no radius at all', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(segments: segments, rounded: false),
      );

      expect(paintedRadii(tester), everyElement(isNull));
    });

    testWidgets('a caller endRadius wins over the default', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(
          segments: segments,
          trackerStyle: CoreTrackerStyle(endRadius: CoreRadius.radius8),
        ),
      );

      expect(paintedRadii(tester), const [
        BorderRadius.horizontal(left: Radius.circular(8)),
        BorderRadius.zero,
        BorderRadius.horizontal(right: Radius.circular(8)),
      ]);
    });

    // 2 sits below the control-radius band (6…16) the density axis moves,
    // so a denser or looser app must not change the bar corners.
    for (final density in [CoreDensity.compact, CoreDensity.spacious]) {
      testWidgets('the corner stays 2 under ${density.name} density', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          const Tracker(segments: segments),
          density: density,
        );

        expect(paintedRadii(tester), const [
          BorderRadius.horizontal(left: rounded2),
          BorderRadius.zero,
          BorderRadius.horizontal(right: rounded2),
        ]);
      });
    }
  });

  group('CoreTrackerStatus', () {
    test('has the expected values', () {
      expect(
        CoreTrackerStatus.values,
        containsAll([
          CoreTrackerStatus.fine,
          CoreTrackerStatus.warning,
          CoreTrackerStatus.critical,
          CoreTrackerStatus.unknown,
        ]),
      );
    });
  });

  group('CoreTrackerSegment', () {
    test('stores status and tooltip', () {
      const segment = CoreTrackerSegment(
        status: CoreTrackerStatus.fine,
        tooltip: 'Healthy',
      );

      expect(segment.status, equals(CoreTrackerStatus.fine));
      expect(segment.tooltip, equals('Healthy'));
    });
  });

  // #6467: a healthy segment recedes to 40 % of the success colour so the
  // warning and critical ones carry the row, and the segments sit 4 apart.
  group('Tracker redesign (#6467)', () {
    testWidgets('fine paints success at 40 %, warning at full colour', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Tracker(
          segments: [
            CoreTrackerSegment(status: CoreTrackerStatus.fine),
            CoreTrackerSegment(status: CoreTrackerStatus.warning),
          ],
        ),
      );
      final colors = [
        for (final box in tester.widgetList<Container>(
          find.descendant(
            of: find.byType(Tracker),
            matching: find.byType(Container),
          ),
        ))
          if (box.decoration case final BoxDecoration d when d.color != null)
            d.color!,
      ];
      expect(colors, hasLength(2));
      expect(colors[0].a, closeTo(CoreOpacity.opacity40, 0.01));
      expect(colors[1].a, closeTo(1, 0.01));
    });

    testWidgets('segments sit 4 apart', (tester) async {
      await pumpTestApp(
        tester,
        const Tracker(
          segments: [
            CoreTrackerSegment(status: CoreTrackerStatus.fine),
            CoreTrackerSegment(status: CoreTrackerStatus.fine),
          ],
        ),
      );
      final row = tester.widget<Row>(
        find
            .descendant(of: find.byType(Tracker), matching: find.byType(Row))
            .first,
      );
      expect(row.spacing, CoreSpace.space4);
    });
  });
}
