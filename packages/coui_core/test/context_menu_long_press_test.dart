// The touch / pen long press that opens a ContextMenu is timed and judged by
// each seat itself — Flutter by the framework's LongPressGestureRecognizer,
// the Web by its own pointer-events tracker — so what the two have to agree on
// lives here as one hold, one slop and one predicate, pinned by a table that
// the Flutter and Web tests replay too (see the table's own comment for what
// is in it). This file pins the Core half: the constants, the predicate, and
// that the table says what the rules say, so changing a constant fails here
// before it fails anywhere else.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter ContextMenu test and the Web
/// press-tracker test.
const String kContextMenuLongPressVectorsPath =
    'test/fixtures/context_menu_long_press_vectors.json';

/// The event kinds both seats can replay; the rest are the Web's alone.
const Set<String> _kSharedKinds = {'down', 'move', 'up', 'cancel'};

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

List<Map<String, Object?>> _eventsOf(Map<String, Object?> press) =>
    (press['events']! as List).cast<Map<String, Object?>>();

/// Where [press] leaves the menu open, read straight off the rules:
///
/// * the press starts at its first `down` and opens at that point once
///   [holdMs] has passed;
/// * it stops counting if, before then, the pointer is released or taken
///   (`up`, `cancel`), the page moves under it (`scroll`) or it drifts past
///   the slop (`move`) — and it does not come back if the pointer does;
/// * once it has opened, nothing that follows closes it;
/// * a list that does not start with a pointer going down has no press in it.
({double x, double y})? _opensByTheRules(
  Map<String, Object?> press, {
  required int holdMs,
}) {
  final events = _eventsOf(press);
  final first = events.first;
  if (first['kind'] != 'down') return null;
  final originX = _n(first, 'x');
  final originY = _n(first, 'y');
  final opensAt = (first['at']! as int) + holdMs;
  if ((press['until']! as int) < opensAt) return null;
  for (final event in events.skip(1)) {
    if ((event['at']! as int) >= opensAt) break;
    switch (event['kind']) {
      case 'up' || 'cancel' || 'scroll':
        return null;
      case 'move'
          when CoreContextMenuContract.exceedsLongPressSlop(
            originX: originX,
            originY: originY,
            x: _n(event, 'x'),
            y: _n(event, 'y'),
          ):
        return null;
    }
  }

  return (x: originX, y: originY);
}

void main() {
  final doc =
      jsonDecode(File(kContextMenuLongPressVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final drift = (doc['drift']! as List).cast<Map<String, Object?>>();
  final presses = (doc['presses']! as List).cast<Map<String, Object?>>();

  group('the long-press constants', () {
    test('the hold is the 500 ms Flutter times a long press at', () {
      expect(
        CoreContextMenuContract.defaultLongPressDuration,
        const Duration(milliseconds: 500),
      );
      expect(
        CoreContextMenuContract.defaultLongPressDuration,
        const Duration(milliseconds: CoreDuration.slow),
      );
    });

    test('the slop is the 18 px Flutter calls kTouchSlop', () {
      expect(CoreContextMenuContract.defaultLongPressSlop, 18);
    });

    test('the table states the constants it was written against', () {
      expect(
        doc['durationMs'],
        CoreContextMenuContract.defaultLongPressDuration.inMilliseconds,
      );
      expect(
        (doc['slop']! as num).toDouble(),
        CoreContextMenuContract.defaultLongPressSlop,
      );
    });
  });

  group('CoreContextMenuContract.exceedsLongPressSlop against the vectors', () {
    test('the table is not empty', () {
      expect(drift, isNotEmpty);
      expect(presses, isNotEmpty);
    });

    for (final vector in drift) {
      test(vector['name']! as String, () {
        final origin = (vector['origin']! as List).cast<num>();
        final point = (vector['point']! as List).cast<num>();
        expect(
          CoreContextMenuContract.exceedsLongPressSlop(
            originX: origin[0].toDouble(),
            originY: origin[1].toDouble(),
            x: point[0].toDouble(),
            y: point[1].toDouble(),
          ),
          vector['exceeds'],
        );
      });
    }
  });

  group('every press in the table says what the rules say', () {
    final holdMs =
        CoreContextMenuContract.defaultLongPressDuration.inMilliseconds;

    for (final press in presses) {
      test(press['name']! as String, () {
        final expected = press['opens'] as Map<String, Object?>?;
        final byTheRules = _opensByTheRules(press, holdMs: holdMs);
        if (expected == null) {
          expect(
            byTheRules,
            isNull,
            reason: 'the rules open it, the table not',
          );
        } else {
          expect(
            byTheRules,
            isNotNull,
            reason: 'the table opens it, the rules not',
          );
          expect(byTheRules!.x, _n(expected, 'x'));
          expect(byTheRules.y, _n(expected, 'y'));
        }
      });
    }
  });

  group('the table is well formed', () {
    test('every press starts with a down and its events move forward', () {
      for (final press in presses) {
        final events = _eventsOf(press);
        final name = press['name']! as String;
        final times = [for (final e in events) e['at']! as int];
        if (events.first['kind'] != 'down') {
          // A press without a pointer: only the Web's own events can stand
          // alone (a right-click that no touch is behind).
          expect(
            events.every((e) => e['kind'] == 'contextmenu'),
            isTrue,
            reason: '$name: starts with something other than a down',
          );
        }
        for (var i = 1; i < times.length; i++) {
          expect(times[i], greaterThan(times[i - 1]), reason: '$name: order');
        }
        expect(
          press['until']! as int,
          greaterThanOrEqualTo(times.last),
          reason: '$name: the clock is read after the last event',
        );
      }
    });

    test('presses both seats replay use only the events both seats have', () {
      for (final press in presses) {
        final platforms = (press['platforms'] as List?)?.cast<String>();
        final kinds = {for (final e in _eventsOf(press)) e['kind']! as String};
        if (platforms == null) {
          expect(
            _kSharedKinds.containsAll(kinds),
            isTrue,
            reason: '${press['name']}: uses $kinds but names no platform',
          );
        } else {
          expect(
            platforms.toSet().difference({'flutter', 'web'}),
            isEmpty,
            reason: '${press['name']}: names a platform that does not exist',
          );
        }
      }
    });

    test('a press states one answer per event it is asked about', () {
      for (final press in presses) {
        final kinds = [for (final e in _eventsOf(press)) e['kind']! as String];
        expect(
          (press['claims'] as List?)?.length ?? 0,
          kinds.where((k) => k == 'contextmenu').length,
          reason: '${press['name']}: claims per contextmenu',
        );
        expect(
          (press['consumes'] as List?)?.length ?? 0,
          kinds.where((k) => k == 'touchend').length,
          reason: '${press['name']}: consumes per touchend',
        );
      }
    });
  });
}
