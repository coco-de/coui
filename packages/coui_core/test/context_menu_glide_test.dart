// A finger that opened a ContextMenu with a long press may keep moving and
// choose a row by lifting over it. Both seats run the one state machine in
// Core (`CoreContextMenuGlide`); what the seats supply is where the rows are
// and what highlighting, activating and closing look like. This file pins the
// Core half: the slop, the hit-test rule, every trace of the shared table
// replayed on the machine over a synthesized layout, and the order of effects
// the machine promises. The Flutter test replays the same traces on a real
// ContextMenu with pointer events, the Web test on the press tracker with a
// manual clock, and a real Chrome on the compiled component, so a change on
// one platform fails the others (see the table's own comment).
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter ContextMenu test, the Web press
/// tracker test and the Chrome probe.
const String kContextMenuGlideVectorsPath =
    'test/fixtures/context_menu_glide_vectors.json';

/// The long-press table: its `drift` rows state the same disc.
const String kContextMenuLongPressVectorsPath =
    'test/fixtures/context_menu_long_press_vectors.json';

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

CoreMenuBox _box(List<Object?> edges) {
  final e = edges.cast<num>().map((v) => v.toDouble()).toList();

  return CoreMenuBox(left: e[0], top: e[1], right: e[2], bottom: e[3]);
}

/// One interactive row of a synthesized menu.
class _Row {
  _Row({required this.kind, required this.enabled, required this.box});

  final String kind;
  final bool enabled;

  /// Where the list has the row, in view or not.
  final CoreMenuBox box;
}

/// The menu a trace is replayed against, laid out the way the table's
/// `layout` says. The numbers are the Core test's alone — the seats measure
/// their own menus — and exist so that symbolic positions have pixels.
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
    viewport = CoreMenuBox(
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
  late final CoreMenuBox viewport;

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

  /// What the seat would measure: every row, clipped to the list's view.
  List<CoreGlideTarget> measure() => [
    for (final row in rows)
      CoreGlideTarget(
        box:
            _placed(row).intersect(viewport) ??
            CoreMenuBox(
              left: viewport.left,
              top: viewport.top,
              right: viewport.left,
              bottom: viewport.top,
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

/// What a replay left behind — the same observables the seats read off their
/// menus.
class _Observed {
  int? highlight;
  int cues = 0;
  bool open = true;
  final List<int> activated = [];
}

void main() {
  final doc =
      jsonDecode(File(kContextMenuGlideVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final longPress =
      jsonDecode(File(kContextMenuLongPressVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final traces = _list(doc['traces']);
  final hits = _list(doc['hits']);
  final menus = doc['menus']! as Map<String, Object?>;
  final layoutSpec = doc['layout']! as Map<String, Object?>;

  group('the glide slop', () {
    test('is the disc the hold had to stay inside', () {
      expect(
        CoreContextMenuContract.defaultGlideSlop,
        CoreContextMenuContract.defaultLongPressSlop,
      );
      expect(CoreContextMenuContract.defaultGlideSlop, 18);
    });

    test('the table states the number it was written against', () {
      expect(
        (doc['slop']! as num).toDouble(),
        CoreContextMenuContract.defaultGlideSlop,
      );
    });

    // The long-press table already says, case by case, whether a point is
    // inside the 18 px disc round another. A glide is judged by the same
    // disc, so it has to answer every one of those rows the same way.
    for (final vector in _list(longPress['drift'])) {
      test('exceedsGlideSlop: ${vector['name']}', () {
        final origin = (vector['origin']! as List).cast<num>();
        final point = (vector['point']! as List).cast<num>();
        expect(
          CoreContextMenuContract.exceedsGlideSlop(
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

  group('CoreMenuBox', () {
    const box = CoreMenuBox(left: 10, top: 20, right: 110, bottom: 60);

    test('contains its left and top edges and not its right and bottom', () {
      expect(box.containsPoint(10, 20), isTrue);
      expect(box.containsPoint(109.99, 59.99), isTrue);
      expect(box.containsPoint(110, 40), isFalse);
      expect(box.containsPoint(50, 60), isFalse);
      expect(box.containsPoint(9.99, 40), isFalse);
      expect(box.containsPoint(50, 19.99), isFalse);
    });

    test('knows its size and when it has no area', () {
      expect(box.width, 100);
      expect(box.height, 40);
      expect(box.isEmpty, isFalse);
      expect(
        const CoreMenuBox(left: 5, top: 5, right: 5, bottom: 9).isEmpty,
        isTrue,
      );
      expect(
        const CoreMenuBox(left: 5, top: 5, right: 9, bottom: 5).isEmpty,
        isTrue,
      );
      expect(
        const CoreMenuBox(left: 9, top: 5, right: 5, bottom: 9).isEmpty,
        isTrue,
      );
    });

    test('an empty box contains no point', () {
      const empty = CoreMenuBox(left: 5, top: 5, right: 5, bottom: 50);
      expect(empty.containsPoint(5, 20), isFalse);
    });

    test(
      'intersects to the part both cover, and to null when only touching',
      () {
        const other = CoreMenuBox(left: 60, top: 0, right: 200, bottom: 40);
        expect(
          box.intersect(other),
          const CoreMenuBox(left: 60, top: 20, right: 110, bottom: 40),
        );
        const touching = CoreMenuBox(
          left: 110,
          top: 20,
          right: 200,
          bottom: 60,
        );
        expect(box.intersect(touching), isNull);
        const apart = CoreMenuBox(left: 300, top: 20, right: 400, bottom: 60);
        expect(box.intersect(apart), isNull);
      },
    );

    test('fromLTWH is the same box as its edges', () {
      expect(
        CoreMenuBox.fromLTWH(10, 20, 100, 40),
        const CoreMenuBox(left: 10, top: 20, right: 110, bottom: 60),
      );
    });

    test('is a value', () {
      expect(
        const CoreMenuBox(left: 1, top: 2, right: 3, bottom: 4),
        const CoreMenuBox(left: 1, top: 2, right: 3, bottom: 4),
      );
      expect(
        const CoreMenuBox(left: 1, top: 2, right: 3, bottom: 4).hashCode,
        const CoreMenuBox(left: 1, top: 2, right: 3, bottom: 4).hashCode,
      );
    });
  });

  group('CoreContextMenuGlide.targetAt against the hit vectors', () {
    test('the table is not empty', () {
      expect(hits, isNotEmpty);
      expect(traces, isNotEmpty);
    });

    for (final vector in hits) {
      test(vector['name']! as String, () {
        final targets = [
          for (final t in _list(vector['targets']))
            CoreGlideTarget(
              box: _box((t['box']! as List).cast<Object?>()),
              enabled: t['enabled']! as bool,
            ),
        ];
        final point = (vector['point']! as List).cast<num>();
        expect(
          CoreContextMenuGlide.targetAt(
            point[0].toDouble(),
            point[1].toDouble(),
            targets,
          ),
          vector['index'],
        );
      });
    }
  });

  group('every trace in the table, replayed on the machine', () {
    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('core')) continue;

      test(trace['name']! as String, () {
        final events = _list(trace['events']);
        final down = events.first;
        final originX = _n(down, 'x');
        final originY = _n(down, 'y');
        final menu =
            menus[(trace['menu'] as String?) ?? 'basic']!
                as Map<String, Object?>;
        final items = _list(menu['items']);
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
        final observed = _Observed();
        final glideOn = trace['glide'] != false;
        final haptics = trace['haptics'] == true;

        // The seat's wiring, in the table's terms: activating an action row
        // closes the menu (the Menu's `onActivate`), a toggle row does not.
        final glide = CoreContextMenuGlide(
          originX: originX,
          originY: originY,
          measure: layout.measure,
          onHighlight: (index) => observed.highlight = index,
          onActivate: (index) {
            observed.activated.add(index);
            if (interactive[index]['kind'] == 'action') observed.open = false;
          },
          onClose: () => observed.open = false,
          onCue: haptics ? (_) => observed.cues++ : null,
        );

        var at = (x: originX, y: originY);
        for (final event in events.skip(1)) {
          final kind = event['kind']! as String;
          final to = event['to'] as Map<String, Object?>?;
          if (to != null && kind != 'scroll') at = layout.resolve(to, at);
          // The hold (500 ms) belongs to the long-press table; a glide begins
          // when the menu is open, so events before it are the hold's.
          final held = (event['at']! as int) < 500;
          switch (kind) {
            case 'move' when !held && glideOn:
              glide.move(at.x, at.y);
            case 'up' when glideOn:
              glide.release(at.x, at.y);
            case 'cancel' when glideOn:
              glide.cancel();
            case 'scroll':
              layout.scrollToFirst((to!['firstRow']! as num).toInt());
          }

          final expect_ = event['expect'] as Map<String, Object?>?;
          if (expect_ == null) continue;
          final where = 'after ${event['kind']} at ${event['at']} ms';
          if (expect_.containsKey('highlight')) {
            expect(
              observed.highlight,
              expect_['highlight'],
              reason: '$where: highlight',
            );
          }
          if (expect_.containsKey('cues')) {
            expect(observed.cues, expect_['cues'], reason: '$where: cues');
          }
          if (expect_.containsKey('open')) {
            expect(observed.open, expect_['open'], reason: '$where: open');
          }
          if (expect_.containsKey('activated')) {
            expect(
              observed.activated,
              (expect_['activated']! as List).cast<int>(),
              reason: '$where: activated',
            );
          }
        }
      });
    }
  });

  group('the table is well formed', () {
    const kinds = {'down', 'move', 'up', 'cancel', 'scroll'};
    const expectKeys = {'highlight', 'cues', 'open', 'activated'};

    test('every trace starts with a down and its events move forward', () {
      for (final trace in traces) {
        final events = _list(trace['events']);
        final name = trace['name']! as String;
        expect(events.first['kind'], 'down', reason: name);
        expect(events.first['at'], 0, reason: name);
        for (var i = 1; i < events.length; i++) {
          expect(
            events[i]['at']! as int,
            greaterThan(events[i - 1]['at']! as int),
            reason: '$name: order',
          );
          expect(kinds, contains(events[i]['kind']), reason: name);
        }
      }
    });

    test('the menu has opened by the first event that follows the hold', () {
      // The glide begins at 500 ms; an event between 500 and the clearance a
      // seat needs to finish mounting would race the panel.
      for (final trace in traces) {
        final events = _list(trace['events']);
        for (final event in events.skip(1)) {
          final at = event['at']! as int;
          if (at < 500) {
            expect(
              event['kind'],
              'move',
              reason: '${trace['name']}: hold phase',
            );
          } else {
            expect(
              at,
              greaterThanOrEqualTo(600),
              reason: trace['name']! as String,
            );
          }
        }
      }
    });

    test('every expectation says something the replayers can read', () {
      for (final trace in traces) {
        for (final event in _list(trace['events'])) {
          final expected = event['expect'] as Map<String, Object?>?;
          if (expected == null) continue;
          expect(
            expectKeys.containsAll(expected.keys),
            isTrue,
            reason: trace['name']! as String,
          );
        }
      }
    });

    test('rows named by a trace exist in its menu', () {
      for (final trace in traces) {
        final menu =
            menus[(trace['menu'] as String?) ?? 'basic']!
                as Map<String, Object?>;
        final rows = _list(
          menu['items'],
        ).where((i) => i['kind'] != 'divider').length;
        for (final event in _list(trace['events'])) {
          final to = event['to'] as Map<String, Object?>?;
          if (to == null) continue;
          final named = [
            if (to['row'] != null) to['row']! as int,
            if (to['between'] != null) ...(to['between']! as List).cast<int>(),
            if (to['firstRow'] != null) to['firstRow']! as int,
          ];
          for (final row in named) {
            expect(
              row,
              inInclusiveRange(0, rows - 1),
              reason: trace['name']! as String,
            );
          }
        }
      }
    });

    test('a trace that sets haptics says what it expects them to do', () {
      for (final trace in traces) {
        if (trace['haptics'] != true) continue;
        final events = _list(trace['events']);
        final hasCues = events.any(
          (e) =>
              (e['expect'] as Map<String, Object?>?)?.containsKey('cues') ??
              false,
        );
        expect(hasCues, isTrue, reason: trace['name']! as String);
      }
    });
  });

  group('the machine', () {
    // Two stacked rows and a third that is disabled, at known places.
    List<CoreGlideTarget> targets() => const [
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 0, right: 100, bottom: 40),
        enabled: true,
      ),
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 40, right: 100, bottom: 80),
        enabled: true,
      ),
      CoreGlideTarget(
        box: CoreMenuBox(left: 0, top: 80, right: 100, bottom: 120),
        enabled: false,
      ),
    ];

    late List<String> log;
    late CoreContextMenuGlide glide;

    CoreContextMenuGlide build({
      List<CoreGlideTarget> Function()? measure,
      bool cues = true,
      double originX = 50,
      double originY = 5,
    }) => CoreContextMenuGlide(
      originX: originX,
      originY: originY,
      measure: measure ?? targets,
      onHighlight: (index) => log.add('highlight:${index ?? 'none'}'),
      onActivate: (index) => log.add('activate:$index'),
      onClose: () => log.add('close'),
      onCue: cues ? (cue) => log.add('cue:${cue.name}') : null,
    );

    setUp(() {
      log = [];
      glide = build();
    });

    test('is armed, with nothing lit, until the finger leaves the disc', () {
      expect(glide.gliding, isFalse);
      glide.move(60, 10);
      expect(glide.gliding, isFalse);
      expect(glide.highlighted, isNull);
      expect(log, isEmpty);
    });

    test('measures nothing while armed', () {
      var measured = 0;
      glide =
          build(
              measure: () {
                measured++;

                return targets();
              },
            )
            ..move(55, 8)
            ..move(60, 10);
      expect(measured, 0);
      glide.move(50, 60);
      expect(measured, 1);
    });

    test('lighting a row ticks after it lights it', () {
      glide.move(50, 60);
      expect(log, ['highlight:1', 'cue:selectionTick']);
    });

    test('leaving a row for nothing is silent', () {
      glide
        ..move(50, 60)
        ..move(500, 60);
      expect(log, ['highlight:1', 'cue:selectionTick', 'highlight:none']);
    });

    test('moving within a row says nothing', () {
      glide.move(50, 60);
      log.clear();
      glide.move(70, 70);
      expect(log, isEmpty);
    });

    test(
      'a release that chooses clears the lit row, ticks, then activates',
      () {
        glide
          ..move(50, 60)
          ..release(50, 60);
        log.removeRange(0, 2);
        expect(log, ['highlight:none', 'cue:selectionTick', 'activate:1']);
      },
    );

    test('a release over nothing clears the lit row and closes', () {
      glide
        ..move(50, 60)
        ..release(500, 60);
      log.removeRange(0, 2);
      expect(log, ['highlight:none', 'close']);
    });

    test('a release over a disabled row closes without a cue', () {
      glide.release(50, 100);
      expect(log, ['close']);
    });

    test('a release is judged where it lands, not where the last move was', () {
      glide
        ..move(50, 20)
        ..release(50, 60);
      expect(log.last, 'activate:1');
    });

    test('a release that never left the disc leaves the menu alone', () {
      glide.release(55, 8);
      expect(log, isEmpty);
      expect(glide.finished, isTrue);
    });

    test('a release past the slop with no earlier move still glides', () {
      glide.release(50, 60);
      expect(log, ['cue:selectionTick', 'activate:1']);
    });

    test('with nothing measurable a release leaves the menu open', () {
      glide = build(measure: () => const [])..release(500, 500);
      expect(log, isEmpty);
    });

    test('a cancel clears the lit row and chooses nothing', () {
      glide
        ..move(50, 60)
        ..cancel();
      log.removeRange(0, 2);
      expect(log, ['highlight:none']);
      expect(glide.finished, isTrue);
    });

    test('a finished glide ignores everything', () {
      glide
        ..release(50, 60)
        ..move(50, 20)
        ..release(50, 20)
        ..cancel();
      expect(log, ['cue:selectionTick', 'activate:1']);
    });

    test('without an onCue it plays nothing and the rest is the same', () {
      glide = build(cues: false)
        ..move(50, 60)
        ..release(50, 60);
      expect(log, ['highlight:1', 'highlight:none', 'activate:1']);
    });

    test(
      'measures again for every event — rows that moved are read as they are',
      () {
        var shifted = false;
        glide = build(
          measure: () => shifted
              ? const [
                  CoreGlideTarget(
                    box: CoreMenuBox(
                      left: 0,
                      top: 100,
                      right: 100,
                      bottom: 140,
                    ),
                    enabled: true,
                  ),
                ]
              : targets(),
        )..move(50, 30);
        expect(glide.highlighted, 0);
        shifted = true;
        glide.release(50, 30);
        expect(log.last, 'close');
      },
    );
  });

  group('the haptic cue', () {
    test('is one tick, with a pulse the Web can be told', () {
      expect(CoreHapticCue.values, [CoreHapticCue.selectionTick]);
      expect(CoreHapticCue.selectionTick.pulseMilliseconds, 10);
    });
  });
}
