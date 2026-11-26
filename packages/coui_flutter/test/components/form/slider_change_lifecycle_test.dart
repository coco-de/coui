// Pins the order the three slider callbacks fire in.
//
// `onChangeStart` used to fire *after* the drag's first `onChanged`, so a
// consumer that opened a transaction on start saw the first value arrive
// before the transaction existed. Nothing else in the kit reports in that
// order. The Web twin was worse — it declared both callbacks and fired
// neither, its drag registration passing a literal empty `onUp`.
//
// The order case is the load-bearing one: a build that fires all three
// with the right values in the wrong order passes a "was it called"
// assertion and still breaks the consumer.
//
// Deliberately not covered: firing on tap. The contract and `slider.md`
// both scope these two callbacks to dragging, so widening them is a
// documented behaviour change that needs its own decision — not a side
// effect of repairing the wiring.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kWidth = 300.0;
const _kStartValue = 50.0;

Widget _app(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kWidth,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  group('Slider change lifecycle', () {
    testWidgets('reports start before the first change, then end', (
      tester,
    ) async {
      final log = <String>[];

      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            max: 100,
            onChanged: (v) => log.add('changed'),
            onChangeStart: (v) => log.add('start:$v'),
            onChangeEnd: (v) => log.add('end:$v'),
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(log.first, equals('start:$_kStartValue'));
      expect(log.last, startsWith('end:'));
      expect(
        log.where((e) => e == 'changed'),
        isNotEmpty,
        reason: 'the drag must have moved the value at least once',
      );

      final startIndex = log.indexWhere((e) => e.startsWith('start:'));
      final firstChange = log.indexOf('changed');
      expect(
        startIndex,
        lessThan(firstChange),
        reason: 'start opens the episode — it cannot arrive mid-episode',
      );
    });

    testWidgets('start reports the pre-drag value, not zero', (tester) async {
      double? started;

      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            max: 100,
            onChanged: (_) {},
            onChangeStart: (v) => started = v,
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(
        started,
        equals(_kStartValue),
        reason: 'reporting the drag buffer here would leak a cold-start 0',
      );
    });

    testWidgets('end reports the value the drag finished on', (tester) async {
      double? ended;
      var latest = _kStartValue;

      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            max: 100,
            onChanged: (v) => latest = v,
            onChangeEnd: (v) => ended = v,
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(ended, isNotNull);
      expect(ended, equals(latest));
    });

    testWidgets('cancel closes the drag and restores the controlled value', (
      tester,
    ) async {
      final ended = <double>[];
      var latest = _kStartValue;
      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            onChanged: (value) => latest = value,
            onChangeEnd: ended.add,
          ),
        ),
      );
      final thumb = find
          .descendant(
            of: find.byType(Slider),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.constraints?.maxWidth ==
                      CoreSliderStyle.defaultThumbSize &&
                  widget.constraints?.maxHeight ==
                      CoreSliderStyle.defaultThumbSize,
            ),
          )
          .last;
      final restingCenter = tester.getCenter(thumb);
      final gesture = await tester.startGesture(restingCenter);
      await gesture.moveBy(const Offset(45, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(tester.getCenter(thumb).dx, greaterThan(restingCenter.dx));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(ended, [latest]);
      expect(tester.getCenter(thumb), restingCenter);
    });

    testWidgets('no change callback means no gesture lifecycle', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            onChangeStart: (_) => log.add('start'),
            onChangeEnd: (_) => log.add('end'),
          ),
        ),
      );
      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
    });

    testWidgets('a disabled slider reports nothing', (tester) async {
      final log = <String>[];

      await tester.pumpWidget(
        _app(
          Slider(
            value: _kStartValue,
            max: 100,
            enabled: false,
            onChanged: (_) => log.add('changed'),
            onChangeStart: (_) => log.add('start'),
            onChangeEnd: (_) => log.add('end'),
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
    });
  });
}
