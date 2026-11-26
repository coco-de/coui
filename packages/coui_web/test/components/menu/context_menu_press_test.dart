// The Web times the touch / pen long press of a ContextMenu itself —
// `ContextMenuPress` — because a browser may send its own `contextmenu` event
// for a long touch, or none at all. What a press has to do to open the menu,
// and what the browser's event around it means, is the shared table's
// (`context_menu_long_press_vectors.json`): the Core test pins the table to
// the Core constants, the Flutter test replays it as real pointer events on
// the framework's recognizer, and this file replays it on the tracker with a
// manual clock — so a change on one platform fails the other.
//
// The same finger can go on to choose a row (`glideToSelect`). The judgements
// of that glide are Core's (`CoreContextMenuGlide`) and the shared table
// (`context_menu_glide_vectors.json`) pins them: the Core test replays it on
// the state machine over a synthesized layout, the Flutter test as real
// pointer events on a real menu, and this file replays every trace the Web is
// named in on the tracker — from the first `down`, through the hold, to the
// lift — over the same layout, with a manual clock.
//
// What can be pinned without a browser is the tracker and the anchor rule; the
// DOM half (the listeners, `pointerType`, the cancelable `touchend`, the rows
// measured off the page) is read off a live page by a real Chrome
// (`tool/parity`).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_press.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:universal_web/web.dart' as web;

import '../../helpers/pump_with_theme.dart';

/// The vector table shared with the Core test and the Flutter ContextMenu
/// test.
const String _kVectorsPath =
    '../coui_core/test/fixtures/context_menu_long_press_vectors.json';

/// The glide table, shared with the Core test, the Flutter ContextMenu test
/// and the Chrome probe.
const String _kGlideVectorsPath =
    '../coui_core/test/fixtures/context_menu_glide_vectors.json';

/// A clock wound by hand: a timer fires when the clock is advanced to it, in
/// the order they fall due.
final class _ManualClock {
  int _now = 0;
  final List<_ManualTimer> _timers = [];

  /// The clock a [ContextMenuPress] is given.
  Timer start(Duration delay, void Function() callback) {
    final timer = _ManualTimer(_now + delay.inMilliseconds, callback);
    _timers.add(timer);

    return timer;
  }

  /// How many timers are waiting to fire.
  int get pending => _timers.where((timer) => timer.isActive).length;

  void advanceTo(int target) {
    while (true) {
      final due =
          _timers
              .where((timer) => timer.isActive && timer.dueAt <= target)
              .toList()
            ..sort((left, right) => left.dueAt.compareTo(right.dueAt));
      if (due.isEmpty) break;
      _now = due.first.dueAt;
      due.first.fire();
    }
    _now = target;
  }
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.dueAt, this._callback);

  final int dueAt;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

/// What a replay left behind.
typedef _Outcome = ({
  List<({double x, double y})> opens,
  List<bool> claims,
  List<bool> consumes,
});

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

/// Replays [events] on a fresh tracker, winding the clock to each event's
/// time first and to [until] after the last, and records what it opened and,
/// for each `contextmenu` / `touchend`, what it said about that event.
_Outcome _replay(List<Map<String, Object?>> events, int until) {
  final clock = _ManualClock();
  final opens = <({double x, double y})>[];
  final claims = <bool>[];
  final consumes = <bool>[];
  final press = ContextMenuPress(
    onOpen: (x, y) => opens.add((x: x, y: y)),
    timer: clock.start,
  );
  for (final event in events) {
    clock.advanceTo(event['at']! as int);
    switch (event['kind']) {
      case 'down':
        press.down(_n(event, 'x'), _n(event, 'y'));
      case 'move':
        press.move(_n(event, 'x'), _n(event, 'y'));
      case 'up' || 'cancel':
        press.end();
      case 'scroll':
        press.scrolled();
      case 'contextmenu':
        claims.add(press.ownsContextMenu);
      case 'touchend':
        consumes.add(press.consumesRelease);
      default:
        fail('the table gave the Web an event it cannot replay: $event');
    }
  }
  clock.advanceTo(until);
  press.dispose();

  return (opens: opens, claims: claims, consumes: consumes);
}

List<Map<String, Object?>> _eventsOf(Map<String, Object?> press) =>
    (press['events']! as List).cast<Map<String, Object?>>();

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

/// One interactive row of a synthesized menu.
class _Row {
  _Row({required this.kind, required this.enabled, required this.box});

  final String kind;
  final bool enabled;

  /// Where the list has the row, in view or not.
  final CoreMenuBox box;
}

/// The menu a glide trace is replayed against, laid out the way the table's
/// `layout` says, opened flush at the point the finger went down. The numbers
/// exist so that the table's symbolic positions have pixels; the browser
/// measures its own menus, and the Chrome probe reads these same traces off
/// them.
class _Layout {
  _Layout(
    List<Map<String, Object?>> items,
    Map<String, Object?> spec, {
    required this.originX,
    required this.originY,
  }) {
    final padding = _n(spec, 'padding');
    final rowHeight = _n(spec, 'rowHeight');
    final spacing = _n(spec, 'spacing');
    final dividerHeight = _n(spec, 'dividerHeight');
    final width = _n(spec, 'panelWidth');
    final visibleRows = (spec['visibleRows']! as num).toInt();

    var cursor = 0.0;
    for (final item in items) {
      final kind = item['kind']! as String;
      if (kind == 'divider') {
        cursor += dividerHeight + spacing;
        continue;
      }
      rows.add(
        _Row(
          kind: kind,
          enabled: item['disabled'] != true,
          box: CoreMenuBox(
            left: originX + padding,
            top: originY + padding + cursor,
            right: originX + width - padding,
            bottom: originY + padding + cursor + rowHeight,
          ),
        ),
      );
      cursor += rowHeight + spacing;
    }
    final content = cursor - spacing;
    final room = visibleRows * rowHeight + (visibleRows - 1) * spacing;
    final shown = content > room ? room : content;
    panel = CoreMenuBox(
      left: originX,
      top: originY,
      right: originX + width,
      bottom: originY + shown + 2 * padding,
    );
    list = CoreMenuBox(
      left: originX + padding,
      top: originY + padding,
      right: originX + width - padding,
      bottom: originY + padding + shown,
    );
  }

  final double originX;
  final double originY;
  final List<_Row> rows = [];
  late final CoreMenuBox panel;

  /// The part of the panel the list shows its rows in.
  late final CoreMenuBox list;

  /// How far the list is scrolled, px.
  double scroll = 0;

  CoreMenuBox _placed(_Row row) => CoreMenuBox(
    left: row.box.left,
    top: row.box.top - scroll,
    right: row.box.right,
    bottom: row.box.bottom - scroll,
  );

  /// Scrolls the list so that interactive row [index] is the first in view.
  void scrollToFirst(int index) {
    scroll = rows[index].box.top - rows[0].box.top;
  }

  /// What the host measures: every row, clipped to what the list shows, a row
  /// out of view keeping its place with an empty box.
  List<CoreGlideTarget> measure() => [
    for (final row in rows)
      CoreGlideTarget(
        box:
            _placed(row).intersect(list) ??
            CoreMenuBox(
              left: list.left,
              top: list.top,
              right: list.left,
              bottom: list.top,
            ),
        enabled: row.enabled,
      ),
  ];

  /// The pixel a symbolic position names.
  ({double x, double y}) resolve(
    Map<String, Object?> to,
    ({double x, double y}) previous,
  ) {
    if (to['same'] == true) return previous;
    if (to.containsKey('offset')) {
      final offset = (to['offset']! as List).cast<num>();

      return (x: originX + offset[0], y: originY + offset[1]);
    }
    if (to.containsKey('row')) {
      final box = _placed(rows[(to['row']! as num).toInt()]);
      final at = (to['at']! as List).cast<num>();

      return (
        x: box.left + box.width * at[0],
        y: box.top + box.height * at[1],
      );
    }
    if (to.containsKey('between')) {
      final pair = (to['between']! as List).cast<num>();
      final upper = _placed(rows[pair[0].toInt()]);
      final lower = _placed(rows[pair[1].toInt()]);

      return (
        x: panel.left + panel.width / 2,
        y: (upper.bottom + lower.top) / 2,
      );
    }
    final by = _n(to, 'by');

    return switch (to['outside']) {
      'below' => (x: panel.left + panel.width / 2, y: panel.bottom + by),
      'above' => (x: panel.left + panel.width / 2, y: panel.top - by),
      'left' => (x: panel.left - by, y: panel.top + panel.height / 2),
      'right' => (x: panel.right + by, y: panel.top + panel.height / 2),
      final side => throw StateError('unknown side $side'),
    };
  }
}

/// What a glide replay left behind — the observables the table speaks of.
class _Observed {
  bool open = false;
  int? highlight;
  int cues = 0;
  final List<int> activated = [];
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final drift = (doc['drift']! as List).cast<Map<String, Object?>>();
  final presses = (doc['presses']! as List).cast<Map<String, Object?>>();
  final glideDoc =
      jsonDecode(File(_kGlideVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final traces = _list(glideDoc['traces']);
  final menus = glideDoc['menus']! as Map<String, Object?>;
  final layoutSpec = glideDoc['layout']! as Map<String, Object?>;

  group('the shared table, replayed on the press tracker', () {
    test('the table is not empty', () {
      expect(drift, isNotEmpty);
      expect(presses, isNotEmpty);
    });

    for (final press in presses) {
      final platforms = (press['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      test(press['name']! as String, () {
        final outcome = _replay(_eventsOf(press), press['until']! as int);

        final expected = press['opens'] as Map<String, Object?>?;
        if (expected == null) {
          expect(outcome.opens, isEmpty, reason: 'it must open nothing');
        } else {
          expect(outcome.opens, hasLength(1), reason: 'it opens once');
          expect(outcome.opens.single.x, _n(expected, 'x'));
          expect(outcome.opens.single.y, _n(expected, 'y'));
        }
        expect(
          outcome.claims,
          (press['claims'] as List?)?.cast<bool>() ?? isEmpty,
          reason: 'which contextmenu events the press owns',
        );
        expect(
          outcome.consumes,
          (press['consumes'] as List?)?.cast<bool>() ?? isEmpty,
          reason: 'which releases the press consumes',
        );
      });
    }

    for (final vector in drift) {
      test('drift: ${vector['name']}', () {
        final origin = (vector['origin']! as List).cast<num>();
        final point = (vector['point']! as List).cast<num>();
        final outcome = _replay([
          {'at': 0, 'kind': 'down', 'x': origin[0], 'y': origin[1]},
          {'at': 100, 'kind': 'move', 'x': point[0], 'y': point[1]},
        ], 700);

        expect(
          outcome.opens,
          vector['exceeds']! as bool ? isEmpty : hasLength(1),
        );
      });
    }
  });

  group('ContextMenuPress', () {
    late _ManualClock clock;
    late List<({double x, double y})> opens;
    late ContextMenuPress press;

    setUp(() {
      clock = _ManualClock();
      opens = [];
      press = ContextMenuPress(
        onOpen: (x, y) => opens.add((x: x, y: y)),
        timer: clock.start,
      );
    });

    tearDown(() => press.dispose());

    final holdMs =
        CoreContextMenuContract.defaultLongPressDuration.inMilliseconds;

    test('the hold is the Core duration, to the millisecond', () {
      press.down(60, 50);
      clock.advanceTo(holdMs - 1);
      expect(opens, isEmpty);
      clock.advanceTo(holdMs);
      expect(opens, [(x: 60.0, y: 50.0)]);
    });

    test('a press opens once, however long the pointer stays down', () {
      press.down(60, 50);
      clock.advanceTo(holdMs * 10);
      expect(opens, hasLength(1));
    });

    test('a second finger neither restarts the press nor takes it over', () {
      expect(press.down(60, 50), isTrue);
      clock.advanceTo(200);
      expect(press.down(300, 300), isFalse, reason: 'a press is tracked');
      clock.advanceTo(holdMs);
      expect(opens, [(x: 60.0, y: 50.0)], reason: 'the first one opened it');
    });

    test("a press that starts inside the previous one's window is a new "
        'press', () {
      press
        ..down(60, 50)
        ..end();
      clock.advanceTo(50);
      expect(press.ownsContextMenu, isTrue, reason: "still the old one's");

      expect(press.down(200, 120), isTrue);
      expect(press.consumesRelease, isFalse, reason: 'this one has not opened');
      clock.advanceTo(50 + holdMs);
      expect(opens, [(x: 200.0, y: 120.0)]);
      expect(press.consumesRelease, isTrue);
    });

    test('the window after a press is the fast tier, to the millisecond', () {
      expect(
        kContextMenuPressReleaseWindow,
        const Duration(milliseconds: CoreDuration.fast),
      );
      final window = kContextMenuPressReleaseWindow.inMilliseconds;
      press.down(60, 50);
      clock.advanceTo(200);
      press.end();

      clock.advanceTo(200 + window - 1);
      expect(press.ownsContextMenu, isTrue);
      clock.advanceTo(200 + window);
      expect(press.ownsContextMenu, isFalse);
      expect(press.consumesRelease, isFalse);
    });

    test('a press that opened the menu stops consuming with its window', () {
      press.down(60, 50);
      clock.advanceTo(holdMs + 100);
      press.end();
      expect(press.consumesRelease, isTrue);

      clock.advanceTo(
        holdMs + 100 + kContextMenuPressReleaseWindow.inMilliseconds,
      );
      expect(press.consumesRelease, isFalse);
    });

    test('cancel forgets the press and everything it owns', () {
      press.down(60, 50);
      clock.advanceTo(holdMs + 10);
      press.cancel();

      expect(press.ownsContextMenu, isFalse);
      expect(press.consumesRelease, isFalse);
      expect(clock.pending, 0);

      // …and is not a poison: the next press works.
      expect(press.down(10, 10), isTrue);
    });

    test('a press disabled before its hold is up never opens', () {
      press.down(60, 50);
      clock.advanceTo(100);
      press.cancel();
      clock.advanceTo(holdMs * 2);

      expect(opens, isEmpty);
    });

    test('dispose leaves no timer behind', () {
      press
        ..down(60, 50)
        ..dispose();
      expect(clock.pending, 0);

      press
        ..down(60, 50)
        ..end();
      expect(clock.pending, 1, reason: 'the window after a press');
      press.dispose();
      expect(clock.pending, 0);
    });

    test('a press that is only down holds one timer, then none', () {
      press.down(60, 50);
      expect(clock.pending, 1, reason: 'the hold');
      clock.advanceTo(holdMs);
      expect(clock.pending, 0, reason: 'the hold fired; nothing is waiting');
    });
  });

  group('every glide trace the table names the Web in, replayed on the '
      'tracker', () {
    test('the table is not empty and names the Web in most of it', () {
      final named = traces.where((trace) {
        final platforms = (trace['platforms'] as List?)?.cast<String>();

        return platforms == null || platforms.contains('web');
      });
      expect(named, isNotEmpty);
      expect(named.length, greaterThan(traces.length ~/ 2));
    });

    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      test(trace['name']! as String, () {
        final events = _list(trace['events']);
        final down = events.first;
        final originX = _n(down, 'x');
        final originY = _n(down, 'y');
        final items = _list(
          (menus[(trace['menu'] as String?) ?? 'basic']!
              as Map<String, Object?>)['items'],
        );
        final layout = _Layout(
          items,
          layoutSpec,
          originX: originX,
          originY: originY,
        );
        final interactive = [
          for (final item in items)
            if (item['kind'] != 'divider') item,
        ];
        final glideOn = trace['glide'] != false;
        final haptics = trace['haptics'] == true;
        final clock = _ManualClock();
        final observed = _Observed();

        // The host's wiring, in the table's terms: the press opens the menu
        // and asks for the glide; activating an action row closes the menu
        // (the Menu's `onActivate`), a toggle row does not.
        final press = ContextMenuPress(
          timer: clock.start,
          onOpen: (x, y) => observed.open = true,
          glide: glideOn
              ? (x, y) => CoreContextMenuGlide(
                  originX: x,
                  originY: y,
                  measure: layout.measure,
                  onHighlight: (index) => observed.highlight = index,
                  onActivate: (index) {
                    observed.activated.add(index);
                    if (interactive[index]['kind'] == 'action') {
                      observed.open = false;
                    }
                  },
                  onClose: () => observed.open = false,
                  onCue: haptics ? (_) => observed.cues++ : null,
                )
              : null,
        );

        var at = (x: originX, y: originY);
        for (final event in events) {
          clock.advanceTo(event['at']! as int);
          final kind = event['kind']! as String;
          final to = event['to'] as Map<String, Object?>?;
          if (to != null && kind != 'scroll') at = layout.resolve(to, at);
          switch (kind) {
            case 'down':
              expect(press.down(originX, originY), isTrue);
            case 'move':
              press.move(at.x, at.y);
            case 'up':
              press.up(at.x, at.y);
            case 'cancel':
              press.end();
            case 'scroll':
              // The page hears every element's scroll, the list's included.
              layout.scrollToFirst((to!['firstRow']! as num).toInt());
              press.scrolled();
            default:
              fail('the table gave the Web an event it cannot replay: $event');
          }

          final expected = event['expect'] as Map<String, Object?>?;
          if (expected == null) continue;
          final where = 'after ${event['kind']} at ${event['at']} ms';
          if (expected.containsKey('highlight')) {
            expect(
              observed.highlight,
              expected['highlight'],
              reason: '$where: highlight',
            );
          }
          if (expected.containsKey('cues')) {
            expect(observed.cues, expected['cues'], reason: '$where: cues');
          }
          if (expected.containsKey('open')) {
            expect(observed.open, expected['open'], reason: '$where: open');
          }
          if (expected.containsKey('activated')) {
            expect(
              observed.activated,
              (expected['activated']! as List).cast<int>(),
              reason: '$where: activated',
            );
          }
        }
        press.dispose();
        expect(clock.pending, 0, reason: 'nothing is left waiting');
      });
    }
  });

  group('a glide on the press tracker', () {
    late _ManualClock clock;
    late List<String> log;
    late List<({double x, double y})> asked;
    late List<CoreGlideTarget> targets;
    late ContextMenuPress press;

    final holdMs =
        CoreContextMenuContract.defaultLongPressDuration.inMilliseconds;

    // Two stacked rows and a third that is disabled, at known places.
    List<CoreGlideTarget> rows() => const [
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 100, right: 200, bottom: 140),
        enabled: true,
      ),
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 140, right: 200, bottom: 180),
        enabled: true,
      ),
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 180, right: 200, bottom: 220),
        enabled: false,
      ),
    ];

    CoreContextMenuGlide? glideAt(double x, double y) {
      asked.add((x: x, y: y));

      return CoreContextMenuGlide(
        originX: x,
        originY: y,
        measure: () => targets,
        onHighlight: (index) => log.add('highlight:${index ?? 'none'}'),
        onActivate: (index) => log.add('activate:$index'),
        onClose: () => log.add('close'),
        onCue: (cue) => log.add('cue:${cue.name}'),
      );
    }

    setUp(() {
      clock = _ManualClock();
      log = [];
      asked = [];
      targets = rows();
      press = ContextMenuPress(
        onOpen: (x, y) => log.add('open'),
        timer: clock.start,
        glide: glideAt,
      );
    });

    tearDown(() => press.dispose());

    test(
      'is asked for once, when the hold is up, at the point of the down',
      () {
        press.down(60, 50);
        clock.advanceTo(100);
        press.move(70, 55);
        expect(asked, isEmpty, reason: 'nothing is gliding while it is held');
        clock.advanceTo(holdMs);

        expect(asked, [(x: 60.0, y: 50.0)], reason: 'not where it had drifted');
        expect(log, ['open']);
      },
    );

    test('is never asked for by a press that is dropped before the hold', () {
      press.down(60, 50);
      clock.advanceTo(100);
      press.move(60, 50 + 100);
      clock.advanceTo(holdMs * 2);

      expect(asked, isEmpty);
      expect(log, isEmpty, reason: 'and the menu never opened');
    });

    test('is not asked for by a press without a glide factory', () {
      press = ContextMenuPress(
        onOpen: (x, y) => log.add('open'),
        timer: clock.start,
      )..down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..up(60, 150);

      expect(log, ['open'], reason: 'only the hold; the lift chose nothing');
      expect(press.gliding, isFalse);
    });

    test('a factory that declines leaves a plain long press', () {
      press = ContextMenuPress(
        onOpen: (x, y) => log.add('open'),
        timer: clock.start,
        glide: (x, y) => null,
      )..down(60, 50);
      clock.advanceTo(holdMs);

      expect(press.gliding, isFalse);
      expect(press.consumesRelease, isTrue, reason: 'the press still owns it');
    });

    test('gliding is true from the hold until the pointer lifts', () {
      press.down(60, 50);
      expect(press.gliding, isFalse, reason: 'held, not yet open');
      clock.advanceTo(holdMs);
      expect(press.gliding, isTrue);
      press.move(70, 150);
      expect(press.gliding, isTrue);
      press.up(70, 150);
      expect(press.gliding, isFalse);
    });

    test('gliding is false once the system takes the pointer', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press.end();

      expect(press.gliding, isFalse);
    });

    test('moves after the hold go to the glide', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press.move(60, 150);

      expect(log, ['open', 'highlight:1', 'cue:selectionTick']);
    });

    test('a lift chooses where it lifted', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 110)
        ..up(60, 150);

      expect(log.skip(1), [
        'highlight:0',
        'cue:selectionTick',
        'highlight:none',
        'cue:selectionTick',
        'activate:1',
      ]);
    });

    test('a lift with no position chooses where the pointer last was', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..up();

      expect(log.last, 'activate:1');
    });

    test('a lift with one coordinate takes the other from the last move', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 110)
        ..up(null, 150);

      expect(log.last, 'activate:1');
    });

    test('a lift before the hold is up chooses nothing and opens nothing', () {
      press.down(60, 50);
      clock.advanceTo(100);
      press.up(60, 150);
      clock.advanceTo(holdMs * 2);

      expect(log, isEmpty);
    });

    test('an end is a cancel: the lit row goes out and nothing is chosen', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..end();

      expect(log.skip(1), [
        'highlight:1',
        'cue:selectionTick',
        'highlight:none',
      ]);
    });

    test('a lift after an end chooses nothing: the glide is already over', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..end();
      log.clear();
      press.up(60, 150);

      expect(log, isEmpty);
    });

    test('cancel and dispose cancel a glide in flight', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..cancel();
      expect(log.last, 'highlight:none');

      log.clear();
      press
        ..down(60, 50)
        ..move(61, 51);
      clock.advanceTo(clock._now + holdMs);
      press
        ..move(60, 150)
        ..dispose();
      expect(log.last, 'highlight:none');
      press.move(60, 110);
      expect(log.last, 'highlight:none', reason: 'a disposed press is inert');
    });

    test(
      'the release of a glide is still taken off the page, for its window',
      () {
        press.down(60, 50);
        clock.advanceTo(holdMs);
        press
          ..move(60, 150)
          ..up(60, 150);
        expect(press.consumesRelease, isTrue);

        clock.advanceTo(holdMs + kContextMenuPressReleaseWindow.inMilliseconds);
        expect(press.consumesRelease, isFalse);
        expect(press.ownsContextMenu, isFalse);
      },
    );

    test('the lift is judged with the release already owned', () {
      // A row activated by the lift runs its handler inside the pointerup;
      // the touchend that follows must still be consumed, and the press must
      // already be a finished one when the handler runs.
      bool? consumed;
      bool? gliding;
      press = ContextMenuPress(
        onOpen: (x, y) {},
        timer: clock.start,
        glide: (x, y) => CoreContextMenuGlide(
          originX: x,
          originY: y,
          measure: rows,
          onHighlight: (_) {},
          onActivate: (_) {
            consumed = press.consumesRelease;
            gliding = press.gliding;
          },
          onClose: () {},
        ),
      );
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..up(60, 150);

      expect(consumed, isTrue);
      expect(gliding, isFalse);
    });

    test('a new press after a glide gets a glide of its own', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..up(60, 150);
      log.clear();

      press.down(30, 20);
      clock.advanceTo(clock._now + holdMs);
      expect(asked.last, (x: 30.0, y: 20.0));
      press.move(30, 110);
      expect(log, ['open', 'highlight:0', 'cue:selectionTick']);
    });

    test('a glide leaves no timer behind', () {
      press.down(60, 50);
      clock.advanceTo(holdMs);
      press
        ..move(60, 150)
        ..up(60, 150);
      expect(clock.pending, 1, reason: 'the window after a press');
      press.dispose();
      expect(clock.pending, 0);
    });
  });

  group('contextMenuAnchor', () {
    const target = (left: 100.0, top: 40.0, width: 80.0, height: 30.0);

    test("a pointer's event anchors where the pointer is", () {
      expect(
        contextMenuAnchor(clientX: 312.5, clientY: 77.25, target: target),
        (x: 312.5, y: 77.25),
      );
    });

    test("a contextmenu with no position anchors at the target's centre", () {
      // The context-menu key and Shift+F10 send the event at (0, 0).
      expect(
        contextMenuAnchor(clientX: 0, clientY: 0, target: target),
        (x: 140.0, y: 55.0),
      );
    });

    test('the centre is exact for a target at a fraction of a pixel', () {
      expect(
        contextMenuAnchor(
          clientX: 0,
          clientY: 0,
          target: (left: 10.5, top: 20.25, width: 100.0, height: 51.0),
        ),
        (x: 60.5, y: 45.75),
      );
    });

    test('a pointer on one edge of the viewport is still a pointer', () {
      // Only both coordinates at 0 mean "no position": a click on the left
      // edge (x 0) or the top edge (y 0) has one.
      expect(
        contextMenuAnchor(clientX: 0, clientY: 90, target: target),
        (x: 0.0, y: 90.0),
      );
      expect(
        contextMenuAnchor(clientX: 90, clientY: 0, target: target),
        (x: 90.0, y: 0.0),
      );
    });
  });

  group('the host', () {
    testComponents(
      'listens for the contextmenu, pointerdown and touchend of its region',
      (tester) async {
        pumpWithTheme(
          tester,
          ContextMenu(
            items: [CoreMenuItem.action('Copy', onPressed: () {})],
            child: const div([Text('Area')]),
          ),
        );
        final root =
            find.byType(DomComponent).evaluate().first.component
                as DomComponent;

        expect(
          root.events?.keys,
          containsAll(['contextmenu', 'pointerdown', 'touchend']),
        );
      },
    );

    /// The listeners of the root of a [ContextMenu] built with the given
    /// opt-ins, and its other markup.
    DomComponent rootOf(
      ComponentTester tester, {
      Component? preview,
      bool glideToSelect = false,
      bool haptics = false,
      Map<String, List<UiEventHandler>>? eventHandlers,
    }) {
      pumpWithTheme(
        tester,
        ContextMenu(
          items: [CoreMenuItem.action('Copy', onPressed: () {})],
          preview: preview,
          glideToSelect: glideToSelect,
          haptics: haptics,
          eventHandlers: eventHandlers,
          child: const div([Text('Area')]),
        ),
      );

      return find.byType(DomComponent).evaluate().first.component
          as DomComponent;
    }

    testComponents('a menu that does not glide listens for no touchmove', (
      tester,
    ) async {
      expect(rootOf(tester).events?.keys, isNot(contains('touchmove')));
    });

    testComponents('a preview or haptics alone add no listener', (
      tester,
    ) async {
      final plain = rootOf(tester).events!.keys.toSet();
      final withPreview = rootOf(
        tester,
        preview: const Text('Preview'),
      ).events!.keys.toSet();
      final withHaptics = rootOf(tester, haptics: true).events!.keys.toSet();

      expect(withPreview, plain);
      expect(withHaptics, plain);
    });

    testComponents('a menu that glides listens for touchmove, and only that '
        'more', (tester) async {
      final plain = rootOf(tester).events!.keys.toSet();
      final gliding = rootOf(
        tester,
        glideToSelect: true,
        haptics: true,
        preview: const Text('Preview'),
      ).events!.keys.toSet();

      expect(gliding.difference(plain), {'touchmove'});
      expect(plain.difference(gliding), isEmpty);
    });

    testComponents("a caller's touchmove handler keeps running", (
      tester,
    ) async {
      final calls = <String>[];
      final root = rootOf(
        tester,
        glideToSelect: true,
        eventHandlers: {
          'touchmove': [(_) => calls.add('touchmove')],
        },
      );

      // Nothing is gliding, so the menu's own handler lets the move be.
      root.events!['touchmove']!(web.Event('touchmove'));

      expect(calls, ['touchmove']);
    });

    testComponents('markup carries nothing of a glide before one starts', (
      tester,
    ) async {
      final plain = rootOf(tester);
      final gliding = rootOf(tester, glideToSelect: true, haptics: true);

      expect(gliding.attributes, plain.attributes);
      expect(gliding.classes, plain.classes);
      expect(gliding.attributes?.keys, isNot(contains('data-coui-glide')));
    });

    testComponents(
      "a caller's pointerdown and touchend handlers keep running",
      (
        tester,
      ) async {
        // Chained, not replaced: the long press listens to events a caller may
        // listen to as well, and a handler that silently stopped running would
        // be a regression nobody asked for.
        final calls = <String>[];
        pumpWithTheme(
          tester,
          ContextMenu(
            items: [CoreMenuItem.action('Copy', onPressed: () {})],
            eventHandlers: {
              'pointerdown': [(_) => calls.add('pointerdown')],
              'touchend': [(_) => calls.add('touchend')],
            },
            child: const div([Text('Area')]),
          ),
        );
        final root =
            find.byType(DomComponent).evaluate().first.component
                as DomComponent;

        // A plain event: the tracker ignores it (it has no pointer type), the
        // caller's handler does not.
        root.events!['pointerdown']!(web.Event('pointerdown'));
        root.events!['touchend']!(web.Event('touchend'));

        expect(calls, ['pointerdown', 'touchend']);
      },
    );
  });
}
