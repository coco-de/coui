// The Web `SwipeActions` row model — what a pointer, a focus, `Escape` and a
// pressed action do to a row — replayed without a browser.
//
// The decisions are Core's (`CoreSwipeGesture` and the geometry it runs in),
// pinned by `packages/coui_core/test/swipe_actions_engine_test.dart` against
// the shared table (`swipe_actions_vectors.json`). The Flutter widget replays
// the same table as real pointer events on the framework's recogniser; this
// file replays it on the model with the table's own clock, so a rule that
// changes on one platform fails the other. What a browser has to add — the
// listeners, `pointerType`, capture, the measured layout — is read off a live
// page by the Chrome probe in `tool/parity`.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/swipe_actions/swipe_actions_row.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// The vector table shared with the Core test and the Flutter widget test.
const String _kVectorsPath =
    '../coui_core/test/fixtures/swipe_actions_vectors.json';

typedef _Json = Map<String, Object?>;

_Json _loadVectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as _Json;

List<_Json> _list(Object? value) => (value! as List<Object?>).cast<_Json>();

double _num(Object? value) => (value! as num).toDouble();

Duration _ms(Object? value) => Duration(milliseconds: (value! as num).toInt());

/// The geometry a table row states, with the platter widths the table's
/// action counts make.
CoreSwipeGeometry _geometryOf(_Json vectors, _Json vector) {
  final style = vectors['style']! as _Json;
  final numbers = vectors['numbers']! as _Json;
  final rowBox = vectors['row']! as _Json;

  double extent(int count) => CoreSwipeActionsStyle.extentFor(
    count,
    actionWidth: _num(style['actionWidth']),
    actionSpacing: _num(style['actionSpacing']),
    platterInset: _num(style['platterInset']),
  );

  return CoreSwipeGeometry(
    rowWidth: _num(rowBox['width']),
    leadingExtent: extent((vector['leading'] as int?) ?? 0),
    trailingExtent: extent((vector['trailing'] as int?) ?? 0),
    leadingFullSwipe: (vector['leadingFullSwipe'] as bool?) ?? true,
    trailingFullSwipe: (vector['trailingFullSwipe'] as bool?) ?? true,
    fullSwipeThreshold: _num(numbers['fullSwipeThreshold']),
    rtl: (vector['rtl'] as bool?) ?? false,
  );
}

/// A row wired to a scope that counts what the host would be told.
final class _Harness {
  _Harness({CoreSwipeExclusivity? scope}) {
    row = SwipeActionsRow(
      onChanged: () => changes++,
      onExecute: executed.add,
    );
    if (scope != null) row.scope = scope;
  }

  late final SwipeActionsRow row;
  int changes = 0;
  final List<CoreSwipeSide> executed = [];
}

const CoreSwipeGeometry _twoTrailing = CoreSwipeGeometry(
  rowWidth: 400,
  trailingExtent: 132,
);

const CoreSwipeGeometry _oneLeadingOneTrailing = CoreSwipeGeometry(
  rowWidth: 400,
  leadingExtent: 72,
  trailingExtent: 72,
);

/// Presses at (`from`, 36), moves along the row to each of `xs` at `stepMs`
/// intervals, and returns the phase after the last move.
CoreSwipePhase _stroke(
  SwipeActionsRow row,
  CoreSwipeGeometry geometry,
  double from,
  List<double> xs, {
  int stepMs = 100,
  double? paintedOffset,
}) {
  row.pointerDown(
    Duration.zero,
    from,
    36,
    geometry,
    paintedOffset: paintedOffset,
  );
  var phase = CoreSwipePhase.pending;
  for (var i = 0; i < xs.length; i++) {
    phase = row.pointerMove(
      Duration(milliseconds: (i + 1) * stepMs),
      xs[i],
      36,
    );
  }

  return phase;
}

void main() {
  final vectors = _loadVectors();
  final gestures = _list(vectors['gestures']);

  group('replays every row of the shared gestures table', () {
    test('the table is the 20 rows the Flutter widget replays', () {
      expect(gestures, hasLength(20));
    });

    for (final vector in gestures) {
      test(vector['name']! as String, () {
        final geometry = _geometryOf(vectors, vector);
        final scope = CoreSwipeExclusivity();
        final startOffset = vector['startOffset'] == null
            ? 0.0
            : _num(vector['startOffset']);

        // A neighbour that is open before the press: it is the one a moving
        // row has to close. A row that starts open takes the scope itself, so
        // the neighbour only exists for the rows that start closed.
        final neighbour = _Harness(scope: scope);
        final harness = _Harness(scope: scope);
        final row = harness.row;
        if (startOffset != 0) {
          row.open(geometry.sideOf(startOffset)!, geometry);
          expect(row.offset, closeTo(startOffset, 1e-9), reason: 'start');
        } else {
          neighbour.row.open(CoreSwipeSide.trailing, _twoTrailing);
          expect(scope.holds(neighbour.row), isTrue);
        }
        neighbour.changes = 0;
        harness.changes = 0;

        final expectedOffsets = (vector['offsets']! as List<Object?>)
            .map(_num)
            .toList();
        final released = vector['release'] as _Json?;
        var move = 0;
        CoreSwipeRelease? release;
        var cancelled = false;
        for (final event in _list(vector['events'])) {
          final at = _ms(event['at']);
          switch (event['kind']! as String) {
            case 'down':
              expect(
                row.pointerDown(
                  at,
                  _num(event['x']),
                  _num(event['y']),
                  geometry,
                ),
                isTrue,
              );
            case 'move':
              row.pointerMove(at, _num(event['x']), _num(event['y']));
              expect(
                row.offset,
                closeTo(expectedOffsets[move], 1e-9),
                reason: 'offset after move ${move + 1}',
              );
              move++;
            case 'up':
              release = row.pointerUp(at);
            case 'cancel':
              cancelled = true;
              release = row.pointerCancel();
          }
        }

        expect(move, expectedOffsets.length, reason: 'every move checked');
        if (released == null) {
          expect(release, isNull, reason: 'a tap or a vertical stroke');
          expect(row.dragging, isFalse);
          expect(row.offset, closeTo(startOffset, 1e-9));
          expect(harness.executed, isEmpty);
          expect(row.takeSwallowedClick(), isFalse);
          if (startOffset == 0) {
            expect(
              scope.holds(neighbour.row),
              isTrue,
              reason: 'a press that never became a swipe leaves the open row',
            );
            expect(neighbour.row.isOpen, isTrue);
          }

          return;
        }

        expect(release, isNotNull);
        expect(release!.outcome.name, released['outcome']);
        expect(release.target, closeTo(_num(released['target']), 1e-9));
        expect(row.offset, closeTo(release.target, 1e-9));
        expect(row.dragging, isFalse);
        expect(row.isOpen, release.outcome.isOpen);
        expect(
          row.restingSide,
          release.outcome.isOpen ? release.outcome.side : null,
        );
        expect(row.lastRelease, same(release));

        // An action runs only on a full swipe, and then only the side's
        // first one, once.
        expect(
          harness.executed,
          release.outcome.executes ? [release.outcome.side] : isEmpty,
        );
        // The click that follows a drag's release is the drag's own; a
        // cancel is not a release and has none.
        expect(row.takeSwallowedClick(), !cancelled);
        expect(row.takeSwallowedClick(), isFalse, reason: 'consumed once');

        // The scope: a row holds it exactly while it rests open.
        expect(scope.holds(row), release.outcome.isOpen);
        if (startOffset == 0) {
          expect(
            neighbour.row.isOpen,
            isFalse,
            reason: 'the moving row closed the open neighbour',
          );
          expect(neighbour.changes, greaterThan(0));
        }
        expect(harness.changes, greaterThan(0));
      });
    }
  });

  group('replays the open rows of the shared table', () {
    // Focus reaching an action opens its side without a pointer: the model
    // rests where the table says, in either reading direction.
    for (final vector in _list(vectors['open'])) {
      test(vector['name']! as String, () {
        final harness = _Harness();
        final side = vector['side'] == 'leading'
            ? CoreSwipeSide.leading
            : CoreSwipeSide.trailing;

        harness.row.open(side, _geometryOf(vectors, vector));

        expect(harness.row.offset, closeTo(_num(vector['offset']), 1e-9));
        expect(harness.row.restingSide, side);
      });
    }
  });

  group('following the pointer', () {
    test('the row does not move until the pointer has left the slop', () {
      final row = _Harness().row;
      final phase = _stroke(row, _twoTrailing, 300, [290, 282]);

      // Exactly the slop (18 px) is still a press.
      expect(phase, CoreSwipePhase.pending);
      expect(row.offset, 0);
      expect(row.dragging, isFalse);
      expect(row.revealedSide, isNull);
      expect(row.reveal, 0);

      // A pixel more arms the drag — and the move that arms it is forgiven.
      expect(
        row.pointerMove(const Duration(milliseconds: 300), 281, 36),
        CoreSwipePhase.dragging,
      );
      expect(row.dragging, isTrue);
      expect(row.offset, 0);
    });

    test('once armed the row follows, to the platter, then resists', () {
      final row = _Harness().row;
      _stroke(row, _twoTrailing, 300, [270, 200]);

      // Armed at 270 (30 px of travel): the next move is 70 px further.
      expect(row.dragging, isTrue);
      expect(row.offset, -70);
      expect(row.revealedSide, CoreSwipeSide.trailing);
      expect(row.reveal, 70);

      // Past the platter (132 px) the row follows a quarter of the excess.
      final resisting = _Harness().row;
      const geometry = CoreSwipeGeometry(
        rowWidth: 400,
        trailingExtent: 132,
        trailingFullSwipe: false,
      );
      _stroke(resisting, geometry, 300, [270, 60]);
      expect(resisting.offset, closeTo(-(132 + 0.25 * (210 - 132)), 1e-9));
    });

    test(
      'the full-swipe cue is on from the threshold, only while dragging',
      () {
        // 0.65 × 400 = 260 px.
        final at260 = _Harness().row;
        _stroke(at260, _twoTrailing, 350, [330, 70]);
        expect(at260.offset, -260);
        expect(at260.inFullSwipeZone, isTrue);

        final short = _Harness().row;
        _stroke(short, _twoTrailing, 350, [330, 71]);
        expect(short.offset, -259);
        expect(short.inFullSwipeZone, isFalse);

        at260.pointerCancel();
        expect(at260.inFullSwipeZone, isFalse, reason: 'not dragging any more');
      },
    );

    test('a row grabbed mid-settle starts from where it is painted', () {
      // Painted at -40 on its way closed to -132's opposite end: the drag
      // starts there, not at the rest position it was heading to.
      final grabbed = _Harness().row
        ..open(CoreSwipeSide.trailing, _twoTrailing);
      _stroke(grabbed, _twoTrailing, 300, [320, 340], paintedOffset: -40);
      expect(grabbed.offset, -20, reason: '-40 and 20 px of travel');

      // Within the rest tolerance of where it is resting: no jump.
      final settled = _Harness().row
        ..open(CoreSwipeSide.trailing, _twoTrailing);
      _stroke(settled, _twoTrailing, 300, [320, 340], paintedOffset: -131.5);
      expect(settled.offset, -112, reason: '-132 and 20 px of travel');

      // No reading at all: the row starts from its own offset.
      final unread = _Harness().row..open(CoreSwipeSide.trailing, _twoTrailing);
      _stroke(unread, _twoTrailing, 300, [320, 340]);
      expect(unread.offset, -112);
    });

    test('a disabled row tracks nothing', () {
      final harness = _Harness();
      harness.row.enabled = false;

      expect(
        harness.row.pointerDown(Duration.zero, 300, 36, _twoTrailing),
        isFalse,
      );
      expect(
        harness.row.pointerMove(const Duration(milliseconds: 50), 200, 36),
        CoreSwipePhase.idle,
      );
      expect(harness.row.pointerUp(const Duration(milliseconds: 100)), isNull);
      expect(harness.row.offset, 0);
      expect(harness.changes, 0);
    });

    test('a tap swallows nothing; a drag swallows its own click once', () {
      final tap = _Harness().row;
      _stroke(tap, _twoTrailing, 300, [298]);
      expect(tap.pointerUp(const Duration(milliseconds: 200)), isNull);
      expect(tap.takeSwallowedClick(), isFalse);

      final drag = _Harness().row;
      _stroke(drag, _twoTrailing, 300, [270, 200]);
      drag.pointerUp(const Duration(milliseconds: 300));
      expect(drag.takeSwallowedClick(), isTrue);
      expect(drag.takeSwallowedClick(), isFalse);

      // A swallowed click that never came is forgotten by the host.
      final touch = _Harness().row;
      _stroke(touch, _twoTrailing, 300, [270, 200]);
      touch
        ..pointerUp(const Duration(milliseconds: 300))
        ..forgetSwallowedClick();
      expect(touch.takeSwallowedClick(), isFalse);
    });

    test('the next press forgets a click that never came', () {
      final row = _Harness().row;
      _stroke(row, _twoTrailing, 300, [270, 200]);
      row
        ..pointerUp(const Duration(milliseconds: 300))
        ..pointerDown(const Duration(milliseconds: 900), 300, 36, _twoTrailing);

      expect(row.takeSwallowedClick(), isFalse);
    });
  });

  group('keyboard and focus', () {
    test('focus on an action opens its side to the measured extent', () {
      final harness = _Harness();
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);

      expect(harness.row.offset, -132);
      expect(harness.row.isOpen, isTrue);
      expect(harness.row.restingSide, CoreSwipeSide.trailing);
      expect(harness.row.revealedSide, CoreSwipeSide.trailing);
      expect(harness.changes, 1);

      // A leading platter opens toward the right.
      final leading = _Harness().row
        ..open(CoreSwipeSide.leading, _oneLeadingOneTrailing);
      expect(leading.offset, 72);
    });

    test('in a right-to-left row the leading platter is on the right', () {
      const rtl = CoreSwipeGeometry(
        rowWidth: 400,
        leadingExtent: 72,
        rtl: true,
      );
      final row = _Harness().row..open(CoreSwipeSide.leading, rtl);

      expect(row.offset, -72, reason: 'physical: toward the left');
      expect(row.revealedSide, CoreSwipeSide.leading);
    });

    test(
      'focus on a side already open, or with nothing on it, changes nothing',
      () {
        final harness = _Harness();
        harness.row.open(CoreSwipeSide.trailing, _twoTrailing);
        harness.changes = 0;

        harness.row.open(CoreSwipeSide.trailing, _twoTrailing);
        expect(harness.changes, 0, reason: 'already open there');

        final bare = _Harness();
        bare.row.open(CoreSwipeSide.leading, _twoTrailing);
        expect(bare.row.isOpen, isFalse, reason: 'no leading actions');
        expect(bare.row.offset, 0);
        expect(bare.changes, 0);
      },
    );

    test('a disabled row is not opened by focus', () {
      final harness = _Harness();
      harness.row.enabled = false;
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);

      expect(harness.row.isOpen, isFalse);
      expect(harness.changes, 0);
    });

    test('focus can move an open row to the other side', () {
      final row = _Harness().row
        ..open(CoreSwipeSide.leading, _oneLeadingOneTrailing)
        ..open(CoreSwipeSide.trailing, _oneLeadingOneTrailing);

      expect(row.restingSide, CoreSwipeSide.trailing);
      expect(row.offset, -72);
    });

    test('Escape closes an open row and says it did', () {
      final harness = _Harness();
      expect(harness.row.escape(), isFalse, reason: 'closed: nothing to do');
      expect(harness.changes, 0);

      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);
      harness.changes = 0;

      expect(harness.row.escape(), isTrue);
      expect(harness.row.isOpen, isFalse);
      expect(harness.row.offset, 0);
      expect(harness.changes, 1);
    });

    test('a pressed action runs first, then the row closes', () {
      final order = <String>[];
      final row = SwipeActionsRow(
        onChanged: () => order.add('changed'),
        onExecute: (_) {},
      )..open(CoreSwipeSide.trailing, _twoTrailing);
      order.clear();

      row.press(() => order.add('run'));

      expect(order, ['run', 'changed']);
      expect(row.isOpen, isFalse);
      expect(row.offset, 0);
    });

    test('a row that is already closed closes nothing', () {
      final harness = _Harness();

      expect(harness.row.close(), isFalse);
      expect(harness.changes, 0);
    });

    test('disabling an open row closes it', () {
      final harness = _Harness();
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);
      harness.changes = 0;

      harness.row.enabled = false;

      expect(harness.row.isOpen, isFalse);
      expect(harness.row.offset, 0);
      expect(harness.changes, 1);
    });
  });

  group('the shared scope', () {
    test('opening a row closes the one that was open', () {
      final scope = CoreSwipeExclusivity();
      final first = _Harness(scope: scope);
      final second = _Harness(scope: scope);

      first.row.open(CoreSwipeSide.trailing, _twoTrailing);
      expect(scope.holds(first.row), isTrue);

      second.row.open(CoreSwipeSide.trailing, _twoTrailing);
      expect(first.row.isOpen, isFalse);
      expect(first.row.offset, 0);
      expect(first.changes, 2, reason: 'opened, then closed by the scope');
      expect(scope.holds(second.row), isTrue);
    });

    test('rows outside a scope are independent', () {
      final first = _Harness();
      final second = _Harness();

      first.row.open(CoreSwipeSide.trailing, _twoTrailing);
      second.row.open(CoreSwipeSide.trailing, _twoTrailing);

      expect(first.row.isOpen, isTrue);
      expect(second.row.isOpen, isTrue);
    });

    test('a row that settles closed lets go of the scope', () {
      final scope = CoreSwipeExclusivity();
      final harness = _Harness(scope: scope);
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);

      harness.row.close();

      expect(scope.holder, isNull);
    });

    test('a row going away lets go of the scope', () {
      final scope = CoreSwipeExclusivity();
      final harness = _Harness(scope: scope);
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);

      harness.row.dispose();

      expect(scope.holder, isNull);
    });

    test('a row moved to another scope hands its claim over', () {
      final before = CoreSwipeExclusivity();
      final after = CoreSwipeExclusivity();
      final harness = _Harness(scope: before);
      harness.row.open(CoreSwipeSide.trailing, _twoTrailing);

      harness.row.scope = after;

      expect(before.holder, isNull);
      expect(after.holds(harness.row), isTrue);
      expect(harness.row.scope, same(after));
    });

    test('a row that is closed does not claim the scope it is moved to', () {
      final scope = CoreSwipeExclusivity();
      final harness = _Harness();

      harness.row.scope = scope;

      expect(scope.holder, isNull);
    });
  });
}
