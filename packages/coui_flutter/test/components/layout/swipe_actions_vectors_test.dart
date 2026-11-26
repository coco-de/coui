import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The vector table coui_core shares with the Web seat and the Chrome probe:
/// how a swiped row follows a pointer and where a released one comes to rest
/// (cwd is `packages/coui_flutter` under `flutter test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/swipe_actions_vectors.json';

const Key _kRowKey = Key('swipe-row');

typedef _Row = Map<String, Object?>;

double _n(Object? value) => (value! as num).toDouble();

int _count(_Row row, String side) => (row[side] as int?) ?? 0;

/// A display's frame: the pointer is reported once per frame.
Duration _ms(Object? value) => Duration(milliseconds: (value! as num).toInt());

/// The row of the table, hosted the way an app hosts it: in a list, so a
/// vertical stroke has a scroller to belong to.
Widget _host(
  _Row row, {
  required Size rowSize,
  required List<String> pressed,
}) {
  List<CoreSwipeAction<Widget>> actions(String side, String tag) => [
    for (var i = 0; i < _count(row, side); i++)
      CoreSwipeAction<Widget>(
        label: '$tag$i',
        icon: Icon(LucideIcons.x, key: ValueKey('$tag$i')),
        onPressed: () => pressed.add('$tag$i'),
      ),
  ];

  // The table states a side's full swipe; the widget has one switch for both.
  // No row states one side on and the other off.
  final fullSwipeOff =
      row['leadingFullSwipe'] == false || row['trailingFullSwipe'] == false;

  return SizedBox(
    width: rowSize.width,
    height: 300,
    child: ListView(
      children: [
        SizedBox(
          height: rowSize.height,
          child: SwipeActions(
            leadingActions: actions('leading', 'L'),
            trailingActions: actions('trailing', 'T'),
            allowsFullSwipe: !fullSwipeOff,
            child: const ColoredBox(
              key: _kRowKey,
              color: Color(0xFFEEEEEE),
              child: SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 900),
      ],
    ),
  );
}

/// How far the row has moved from its resting box (physical px, +right).
double _offsetOf(WidgetTester tester, Offset origin) =>
    tester.getTopLeft(find.byKey(_kRowKey)).dx - origin.dx;

/// Opens the row by a slow pull of [pull] px (signed, physical) and waits
/// for it to rest — the way a person opens it, not a back door.
Future<void> _openBySlowPull(
  WidgetTester tester,
  Offset origin,
  double pull,
) async {
  const step = Duration(milliseconds: 100);
  const steps = 5;
  final gesture = await tester.startGesture(origin + const Offset(200, 36));
  var clock = Duration.zero;
  for (var i = 1; i <= steps; i++) {
    clock += step;
    await tester.pump(step);
    await gesture.moveTo(
      origin + Offset(200 + pull * i / steps, 36),
      timeStamp: clock,
    );
  }
  await tester.pump(step);
  await gesture.up(timeStamp: clock + step);
  await tester.pumpAndSettle();
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final numbers = doc['numbers']! as _Row;
  final style = doc['style']! as _Row;
  final rowDoc = doc['row']! as _Row;
  final extents = (doc['extent']! as List).cast<_Row>();
  final opens = (doc['open']! as List).cast<_Row>();
  final gestures = (doc['gestures']! as List).cast<_Row>();
  final rowSize = Size(_n(rowDoc['width']), _n(rowDoc['height']));

  double extentOf(int count) => CoreSwipeActionsStyle.extentFor(
    count,
    actionWidth: _n(style['actionWidth']),
    actionSpacing: _n(style['actionSpacing']),
    platterInset: _n(style['platterInset']),
  );

  group('the table is stated for the figures the widget runs on', () {
    test('thresholds, fling speed, resistance, slop and rest', () {
      expect(
        _n(numbers['fullSwipeThreshold']),
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
      );
      expect(
        _n(numbers['openThreshold']),
        CoreSwipeActionsContract.defaultOpenThreshold,
      );
      expect(
        _n(numbers['flingVelocity']),
        CoreSwipeActionsContract.defaultFlingVelocity,
      );
      expect(
        _n(numbers['resistance']),
        CoreSwipeActionsContract.defaultResistance,
      );
      expect(
        _n(numbers['dragSlop']),
        CoreSwipeActionsContract.defaultDragSlop,
      );
      expect(
        _n(numbers['restTolerance']),
        CoreSwipeActionsContract.restTolerance,
      );
    });

    test('the framework arms a drag at the distance the table forgives', () {
      // The Flutter seat leaves arming to the recogniser, which reads the
      // device's slop; this is what makes that the same pull as the Web's.
      expect(kTouchSlop, CoreSwipeActionsContract.defaultDragSlop);
    });

    test('the style the extents are derived from is the default style', () {
      expect(
        _n(style['actionWidth']),
        CoreSwipeActionsStyle.defaultActionWidth,
      );
      expect(
        _n(style['actionSpacing']),
        CoreSwipeActionsStyle.defaultActionSpacing,
      );
      expect(
        _n(style['platterInset']),
        CoreSwipeActionsStyle.defaultPlatterInset,
      );
    });
  });

  group('the platter is as wide as the table says', () {
    // A row opened by hand rests at the width of its platter: the extent the
    // widget resolves is the extent the table derives, at every count.
    for (final row in extents.where((r) => r['actionWidth'] == null)) {
      final count = (row['count']! as num).toInt();
      if (count == 0) continue;

      testWidgets('${row['name']} (${row['extent']} px)', (tester) async {
        final expected = _n(row['extent']);
        expect(extentOf(count), expected);

        await pumpTestApp(
          tester,
          _host(
            {'trailing': count},
            rowSize: rowSize,
            pressed: [],
          ),
        );
        final origin = tester.getTopLeft(find.byType(SwipeActions));
        await _openBySlowPull(tester, origin, -(expected + 40));

        expect(_offsetOf(tester, origin), closeTo(-expected, 1e-6));
      });
    }
  });

  group('a side opened by focus rests where the table says', () {
    // Keyboard focus reaching one of a side's actions opens that side without
    // a pointer: the row rests where a pull that opened it would.
    for (final row in opens) {
      testWidgets('${row['name']}', (tester) async {
        final rtl = (row['rtl'] as bool?) ?? false;
        await pumpTestApp(
          tester,
          _host(row, rowSize: rowSize, pressed: []),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        final origin = tester.getTopLeft(find.byType(SwipeActions));
        final tag = row['side'] == 'leading' ? 'L0' : 'T0';

        Focus.maybeOf(
          tester.element(find.byKey(ValueKey(tag))),
          createDependency: false,
        )!.requestFocus();
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), closeTo(_n(row['offset']), 1e-6));
      });
    }
  });

  group('every pointer trace in the table', () {
    for (final row in gestures) {
      testWidgets('${row['name']}', (tester) async {
        final pressed = <String>[];
        final rtl = (row['rtl'] as bool?) ?? false;
        await pumpTestApp(
          tester,
          _host(row, rowSize: rowSize, pressed: pressed),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        final origin = tester.getTopLeft(find.byType(SwipeActions));

        // A row that starts open is opened first, by hand, to the platter the
        // table names; the trace then starts from there.
        final startOffset = _n(row['startOffset'] ?? 0);
        if (startOffset != 0) {
          await _openBySlowPull(tester, origin, startOffset.sign * 200);
          expect(
            _offsetOf(tester, origin),
            closeTo(startOffset, 1e-6),
            reason: 'the row did not rest open where the trace expects it',
          );
        }

        final events = (row['events']! as List).cast<_Row>();
        final expectedOffsets = (row['offsets']! as List)
            .map<double>(_n)
            .toList();
        final offsets = <double>[];
        TestGesture? gesture;
        var clock = Duration.zero;

        for (final event in events) {
          // The tester's clock moves with the stamps: Flutter's velocity
          // tracker asks the clock, not only the stamps, whether the pointer
          // has stopped.
          final at = _ms(event['at']);
          if (at > clock) await tester.pump(at - clock);
          clock = at;

          switch (event['kind']) {
            case 'down':
              gesture = await tester.startGesture(
                origin + Offset(_n(event['x']), _n(event['y'])),
              );
            case 'move':
              await gesture!.moveTo(
                origin + Offset(_n(event['x']), _n(event['y'])),
                timeStamp: at,
              );
              await tester.pump();
              offsets.add(_offsetOf(tester, origin));
            case 'up':
              await gesture!.up(timeStamp: at);
              await tester.pump();
            case 'cancel':
              await gesture!.cancel();
              await tester.pump();
            default:
              fail(
                'the table gave the widget an event it cannot replay: $event',
              );
          }
        }

        expect(
          offsets,
          pairwiseCompare<double, double>(
            expectedOffsets,
            (actual, expected) => (actual - expected).abs() < 1e-6,
            'the row followed the pointer, move by move',
          ),
        );

        await tester.pumpAndSettle();

        final release = row['release'] as _Row?;
        if (release == null) {
          // A tap, or a stroke the scroller took: the row never moved and
          // nothing ran.
          expect(_offsetOf(tester, origin), closeTo(startOffset, 1e-6));
          expect(pressed, isEmpty);

          return;
        }

        final outcome = release['outcome']! as String;
        expect(
          _offsetOf(tester, origin),
          closeTo(_n(release['target']), 1e-6),
          reason: 'the row came to rest where the release sent it ($outcome)',
        );
        expect(
          pressed,
          switch (outcome) {
            'executeLeading' => ['L0'],
            'executeTrailing' => ['T0'],
            _ => isEmpty,
          },
          reason: 'only a full swipe runs an action, and only the first',
        );
      });
    }
  });
}
