// How a SwipeActions row follows a pointer and where it rests: the engine
// (`CoreSwipeGeometry`, `CoreSwipeDrag`, `CoreSwipeGesture`), the platter
// width (`CoreSwipeActionsStyle.extentFor`) and the exclusivity registry a
// scope shares. The shared vector table states the answers, pointer trace by
// pointer trace: this file holds the engine to every section of it, and the
// Flutter widget, the Web row model and the Chrome probe replay the same
// gesture rows, so a rule that changes on one platform fails the other.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter widget test, the Web row-model
/// test and the Chrome probe.
const String kSwipeActionsVectorsPath =
    'test/fixtures/swipe_actions_vectors.json';

double _n(Map<String, Object?> map, String key, [double fallback = 0]) =>
    (map[key] as num?)?.toDouble() ?? fallback;

Duration _ms(num ms) => Duration(microseconds: (ms * 1000).round());

/// The geometry a `constrain` / `settle` row states in px.
CoreSwipeGeometry _geometryOf(Map<String, Object?> row) => CoreSwipeGeometry(
  rowWidth: _n(row, 'rowWidth'),
  leadingExtent: _n(row, 'leading'),
  trailingExtent: _n(row, 'trailing'),
  leadingFullSwipe: (row['leadingFullSwipe'] as bool?) ?? true,
  trailingFullSwipe: (row['trailingFullSwipe'] as bool?) ?? true,
  rtl: (row['rtl'] as bool?) ?? false,
);

/// The platter width of [count] cells in the table's style.
double _extent(Map<String, Object?> style, int count) =>
    CoreSwipeActionsStyle.extentFor(
      count,
      actionWidth: _n(style, 'actionWidth'),
      actionSpacing: _n(style, 'actionSpacing'),
      platterInset: _n(style, 'platterInset'),
    );

/// The geometry a `gestures` row states in action counts.
CoreSwipeGeometry _gestureGeometry(
  Map<String, Object?> row,
  Map<String, Object?> style,
  double rowWidth,
) => CoreSwipeGeometry(
  rowWidth: rowWidth,
  leadingExtent: _extent(style, (row['leading'] as int?) ?? 0),
  trailingExtent: _extent(style, (row['trailing'] as int?) ?? 0),
  leadingFullSwipe: (row['leadingFullSwipe'] as bool?) ?? true,
  trailingFullSwipe: (row['trailingFullSwipe'] as bool?) ?? true,
  rtl: (row['rtl'] as bool?) ?? false,
);

CoreSwipeSide? _side(Object? name) => switch (name) {
  'leading' => CoreSwipeSide.leading,
  'trailing' => CoreSwipeSide.trailing,
  _ => null,
};

/// What replaying a trace on the engine left behind.
typedef _Replay = ({List<double> offsets, CoreSwipeRelease? release});

/// Replays [events] on a [CoreSwipeGesture] — one move, one offset.
_Replay _replay(CoreSwipeGesture gesture, List<Map<String, Object?>> events) {
  final offsets = <double>[];
  CoreSwipeRelease? release;
  for (final event in events) {
    final at = _ms(event['at']! as num);
    switch (event['kind']) {
      case 'down':
        gesture.down(at, _n(event, 'x'), _n(event, 'y'));
      case 'move':
        gesture.move(at, _n(event, 'x'), _n(event, 'y'));
        offsets.add(gesture.offset);
      case 'up':
        release = gesture.up(at);
      case 'cancel':
        release = gesture.cancel();
      default:
        fail('the table gave the engine an event it cannot replay: $event');
    }
  }

  return (offsets: offsets, release: release);
}

void main() {
  final doc =
      jsonDecode(File(kSwipeActionsVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  List<Map<String, Object?>> section(String name) =>
      (doc[name]! as List).cast<Map<String, Object?>>();

  final numbers = doc['numbers']! as Map<String, Object?>;
  final style = doc['style']! as Map<String, Object?>;
  final extentRows = section('extent');
  final constrainRows = section('constrain');
  final settleRows = section('settle');
  final openRows = section('open');
  final gestureRows = section('gestures');
  final rowWidth = _n(doc['row']! as Map<String, Object?>, 'width');

  test('the vector tables are not empty', () {
    expect(extentRows, isNotEmpty);
    expect(constrainRows, isNotEmpty);
    expect(settleRows, isNotEmpty);
    expect(openRows, isNotEmpty);
    expect(gestureRows, isNotEmpty);
  });

  group('the table is stated for the Contract figures', () {
    test('thresholds, fling speed, resistance, slop and rest', () {
      expect(
        _n(numbers, 'fullSwipeThreshold'),
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
      );
      expect(
        _n(numbers, 'fullSwipeOvershoot'),
        CoreSwipeActionsContract.defaultFullSwipeOvershoot,
      );
      expect(
        _n(numbers, 'openThreshold'),
        CoreSwipeActionsContract.defaultOpenThreshold,
      );
      expect(
        _n(numbers, 'flingVelocity'),
        CoreSwipeActionsContract.defaultFlingVelocity,
      );
      expect(
        _n(numbers, 'resistance'),
        CoreSwipeActionsContract.defaultResistance,
      );
      expect(
        _n(numbers, 'dragSlop'),
        CoreSwipeActionsContract.defaultDragSlop,
      );
      expect(
        _n(numbers, 'restTolerance'),
        CoreSwipeActionsContract.restTolerance,
      );
    });

    test('the cell, spacing and inset the extents are derived from', () {
      expect(
        _n(style, 'actionWidth'),
        CoreSwipeActionsStyle.defaultActionWidth,
      );
      expect(
        _n(style, 'actionSpacing'),
        CoreSwipeActionsStyle.defaultActionSpacing,
      );
      expect(
        _n(style, 'platterInset'),
        CoreSwipeActionsStyle.defaultPlatterInset,
      );
    });

    test('the fling is the speed the drawer calls a flick', () {
      expect(
        CoreSwipeActionsContract.defaultFlingVelocity,
        CoreDrawerContract.defaultDismissVelocity,
      );
    });

    test("the slop is Flutter's touch slop, 18", () {
      expect(CoreSwipeActionsContract.defaultDragSlop, 18);
    });

    test(
      'a settle is a transition-tier duration, so reduced motion reaches it',
      () {
        expect(
          CoreSwipeActionsContract.defaultSettleDuration,
          const Duration(milliseconds: CoreDuration.normal),
        );
        expect(
          CoreReducedMotion.isTransitionMotion(
            CoreSwipeActionsContract.defaultSettleDuration,
          ),
          isTrue,
        );
      },
    );

    test('the cell is the rung of the button inside it', () {
      expect(
        CoreSwipeActionsContract.actionButtonSize,
        CoreComponentSize.lg,
      );
      expect(
        CoreSwipeActionsStyle.defaultActionWidth,
        CoreControlSize.heightLg,
      );
    });
  });

  group('the platter width against the shared vectors', () {
    for (final row in extentRows) {
      test(row['name']! as String, () {
        final cell = {
          'actionWidth': row['actionWidth'] ?? style['actionWidth'],
          'actionSpacing': row['actionSpacing'] ?? style['actionSpacing'],
          'platterInset': row['platterInset'] ?? style['platterInset'],
        };

        expect(_extent(cell, row['count']! as int), _n(row, 'extent'));
      });
    }

    test(
      'a platter is the cells and the spacings and an inset at each end',
      () {
        expect(
          CoreSwipeActionsStyle.extentFor(
            3,
            actionWidth: 10,
            actionSpacing: 1,
            platterInset: 100,
          ),
          3 * 10 + 2 * 1 + 2 * 100,
        );
      },
    );

    test('no cells, no platter — whatever the style says', () {
      expect(
        CoreSwipeActionsStyle.extentFor(
          0,
          actionWidth: 48,
          actionSpacing: 12,
          platterInset: 12,
        ),
        0,
      );
      expect(
        CoreSwipeActionsStyle.extentFor(
          -1,
          actionWidth: 48,
          actionSpacing: 12,
          platterInset: 12,
        ),
        0,
      );
    });
  });

  group('constrain against the shared vectors', () {
    for (final row in constrainRows) {
      test(row['name']! as String, () {
        final geometry = _geometryOf(row);

        expect(
          geometry.constrain(
            _n(row, 'raw'),
            lockedSide: _side(row['lockedSide']),
          ),
          closeTo(_n(row, 'offset'), 1e-9),
        );
      });
    }
  });

  group('settle against the shared vectors', () {
    for (final row in settleRows) {
      test(row['name']! as String, () {
        final geometry = _geometryOf(row);
        final outcome = geometry.settle(
          _n(row, 'offset'),
          velocity: _n(row, 'velocity'),
        );

        expect(outcome.name, row['outcome']);
        expect(geometry.targetOf(outcome), closeTo(_n(row, 'target'), 1e-9));
      });
    }
  });

  group('the offset that opens a side against the shared vectors', () {
    // Focus reaching an action opens its side without a pointer: the row has
    // to rest where the table says, in either reading direction.
    for (final row in openRows) {
      test(row['name']! as String, () {
        final geometry = _gestureGeometry(row, style, rowWidth);

        expect(
          geometry.openOffsetOf(_side(row['side'])!),
          closeTo(_n(row, 'offset'), 1e-9),
        );
      });
    }

    test('a side with no actions has nowhere to open, in either direction', () {
      for (final rtl in [false, true]) {
        final geometry = CoreSwipeGeometry(
          rowWidth: 400,
          trailingExtent: 72,
          rtl: rtl,
        );

        expect(geometry.openOffsetOf(CoreSwipeSide.leading), 0);
        expect(
          geometry.openOffsetOf(CoreSwipeSide.leading).isNegative,
          isFalse,
        );
        expect(geometry.openOffsetOf(CoreSwipeSide.trailing), rtl ? 72 : -72);
      }
    });
  });

  group('a pointer trace against the shared vectors', () {
    for (final row in gestureRows) {
      test(row['name']! as String, () {
        final geometry = _gestureGeometry(row, style, rowWidth);
        final gesture = CoreSwipeGesture(
          geometry,
          startOffset: _n(row, 'startOffset'),
        );
        final events = (row['events']! as List).cast<Map<String, Object?>>();

        final replay = _replay(gesture, events);

        final expected = (row['offsets']! as List).cast<num>();
        expect(replay.offsets, hasLength(expected.length));
        for (var i = 0; i < expected.length; i++) {
          expect(
            replay.offsets[i],
            closeTo(expected[i].toDouble(), 1e-9),
            reason: 'after move ${i + 1}',
          );
        }
        final release = row['release'] as Map<String, Object?>?;
        if (release == null) {
          expect(replay.release, isNull);
        } else {
          expect(replay.release, isNotNull);
          expect(replay.release!.outcome.name, release['outcome']);
          expect(
            replay.release!.target,
            closeTo(_n(release, 'target'), 1e-9),
          );
        }
        expect(gesture.phase, CoreSwipePhase.idle, reason: 'a lift ends it');
      });
    }

    test(
      'flicks and slow strokes keep a wide margin around the fling speed',
      () {
        // Flutter's recogniser measures its own velocity, so a row only pins
        // both platforms if the two estimates agree about which side of the
        // threshold it is on. That holds when no stroke is near the threshold.
        const fling = CoreSwipeActionsContract.defaultFlingVelocity;
        for (final row in gestureRows) {
          // A press that never became a drag has no release to be near it.
          if (row['release'] == null) continue;

          final tracker = CoreDragVelocityTracker();
          Duration? liftedAt;
          var moved = false;
          for (final event
              in (row['events']! as List).cast<Map<String, Object?>>()) {
            final at = _ms(event['at']! as num);
            switch (event['kind']) {
              case 'down' || 'move':
                tracker.addSample(at, _n(event, 'x'));
                moved = true;
              case 'up':
                liftedAt = at;
            }
          }
          if (!moved || liftedAt == null) continue;

          final speed = tracker.velocityAt(liftedAt).abs();
          expect(
            speed >= 2.5 * fling || speed <= 0.25 * fling,
            isTrue,
            reason: '${row['name']}: $speed px/s is too near $fling',
          );
        }
      },
    );
  });

  group('the reading direction is applied in one place', () {
    // Mirroring the physical axis and the reading direction together must
    // mirror every answer — and it can only do so if nothing but the engine's
    // single flip knows which way is "leading".
    for (final row in constrainRows.where((r) => r['rtl'] != true)) {
      test('constrain: ${row['name']}', () {
        final ltr = _geometryOf(row);
        final rtl = _geometryOf({...row, 'rtl': true});
        final locked = _side(row['lockedSide']);

        expect(
          rtl.constrain(-_n(row, 'raw'), lockedSide: locked),
          closeTo(-ltr.constrain(_n(row, 'raw'), lockedSide: locked), 1e-9),
        );
      });
    }

    for (final row in settleRows.where((r) => r['rtl'] != true)) {
      test('settle: ${row['name']}', () {
        final ltr = _geometryOf(row);
        final rtl = _geometryOf({...row, 'rtl': true});
        final offset = _n(row, 'offset');
        final velocity = _n(row, 'velocity');

        final mirrored = rtl.settle(-offset, velocity: -velocity);
        final outcome = ltr.settle(offset, velocity: velocity);

        expect(mirrored, outcome);
        expect(rtl.targetOf(mirrored), closeTo(-ltr.targetOf(outcome), 1e-9));
      });
    }

    test('nothing the engine returns is a negative zero', () {
      // `-0` as a literal is an int zero; parsing keeps the sign bit.
      final negativeZero = -double.parse('0');
      expect(negativeZero.isNegative, isTrue);

      for (final rtl in [false, true]) {
        final geometry = CoreSwipeGeometry(
          rowWidth: 400,
          leadingExtent: 72,
          trailingExtent: 72,
          rtl: rtl,
        );

        expect(geometry.constrain(0).isNegative, isFalse);
        expect(geometry.constrain(negativeZero).isNegative, isFalse);
        expect(
          geometry.targetOf(CoreSwipeOutcome.closed).isNegative,
          isFalse,
        );
        expect(
          geometry.targetOf(CoreSwipeOutcome.executeTrailing).isNegative,
          isFalse,
        );
      }
    });
  });

  group('CoreSwipeGeometry', () {
    const geometry = CoreSwipeGeometry(
      rowWidth: 400,
      leadingExtent: 132,
      trailingExtent: 72,
    );

    test('a side is revealed once the row is past the rest tolerance', () {
      expect(geometry.sideOf(0), isNull);
      expect(geometry.sideOf(1), isNull);
      expect(geometry.sideOf(-1), isNull);
      expect(geometry.sideOf(1.01), CoreSwipeSide.leading);
      expect(geometry.sideOf(-1.01), CoreSwipeSide.trailing);
    });

    test('right to left swaps which way each side is revealed', () {
      const rtl = CoreSwipeGeometry(
        rowWidth: 400,
        leadingExtent: 132,
        trailingExtent: 72,
        rtl: true,
      );

      expect(rtl.sideOf(50), CoreSwipeSide.trailing);
      expect(rtl.sideOf(-50), CoreSwipeSide.leading);
    });

    test('the full-swipe distance is the share of the row, and a deliberate '
        'pull past the platter once the platter reaches it', () {
      expect(geometry.fullSwipeDistanceOf(CoreSwipeSide.leading), 260);

      const overshoot = CoreSwipeActionsContract.defaultFullSwipeOvershoot;
      const narrow = CoreSwipeGeometry(rowWidth: 100, leadingExtent: 132);
      expect(
        narrow.fullSwipeDistanceOf(CoreSwipeSide.leading),
        132 + overshoot,
      );

      // The platter sits exactly on the share: that already counts as
      // reaching it, so the pixel that crosses the open pose does not run an
      // action.
      const flush = CoreSwipeGeometry(rowWidth: 400, leadingExtent: 260);
      expect(
        flush.fullSwipeDistanceOf(CoreSwipeSide.leading),
        260 + overshoot,
      );
    });

    test('a platter short of the share never reads the overshoot', () {
      const short = CoreSwipeGeometry(rowWidth: 400, leadingExtent: 259);
      expect(short.fullSwipeDistanceOf(CoreSwipeSide.leading), 260);
    });

    test('the outcome knows its side', () {
      expect(CoreSwipeOutcome.closed.side, isNull);
      expect(CoreSwipeOutcome.openLeading.side, CoreSwipeSide.leading);
      expect(CoreSwipeOutcome.executeTrailing.side, CoreSwipeSide.trailing);
      expect(CoreSwipeOutcome.openTrailing.isOpen, isTrue);
      expect(CoreSwipeOutcome.executeLeading.isOpen, isFalse);
      expect(CoreSwipeOutcome.executeLeading.executes, isTrue);
      expect(CoreSwipeOutcome.closed.executes, isFalse);
    });

    test('a full-swipe threshold outside (0, 1] is refused', () {
      expect(
        () => CoreSwipeGeometry(rowWidth: 400, fullSwipeThreshold: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CoreSwipeGeometry(rowWidth: 400, fullSwipeThreshold: 1.01),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => const CoreSwipeGeometry(rowWidth: 400, fullSwipeThreshold: 1),
        returnsNormally,
      );
    });
  });

  group('CoreSwipeDrag', () {
    const geometry = CoreSwipeGeometry(
      rowWidth: 400,
      leadingExtent: 132,
      trailingExtent: 72,
    );

    test('follows the pointer from where it was grabbed, not from zero', () {
      final drag = CoreSwipeDrag(geometry, anchor: 200, startOffset: 132);

      expect(drag.update(190), 122);
      expect(drag.update(150), 82);
      expect(drag.offset, 82);
    });

    test('a release reports where it was, where it goes and how fast', () {
      final drag = CoreSwipeDrag(geometry, anchor: 100)..update(190);

      final release = drag.release(900);

      expect(release.outcome, CoreSwipeOutcome.openLeading);
      expect(release.offset, 90);
      expect(release.target, 132);
      expect(release.velocity, 900);
    });

    test('a cancel returns to the start and never runs an action', () {
      final drag = CoreSwipeDrag(geometry, anchor: 100)..update(390);

      expect(drag.offset, 290, reason: 'past the full-swipe distance');
      final release = drag.cancel();

      expect(release.outcome, CoreSwipeOutcome.closed);
      expect(release.target, 0);
      expect(release.velocity, 0);
    });

    test('a cancel on an open row goes back to open, on either side and in '
        'either reading direction', () {
      for (final rtl in const [false, true]) {
        final open = CoreSwipeGeometry(
          rowWidth: 400,
          leadingExtent: 132,
          trailingExtent: 72,
          rtl: rtl,
        );
        for (final outcome in const [
          CoreSwipeOutcome.openLeading,
          CoreSwipeOutcome.openTrailing,
        ]) {
          final start = open.targetOf(outcome);
          final drag = CoreSwipeDrag(open, anchor: 100, startOffset: start)
            ..update(60);

          final release = drag.cancel();

          expect(release.outcome, outcome, reason: '$outcome, rtl: $rtl');
          expect(release.target, start, reason: '$outcome, rtl: $rtl');
          expect(release.velocity, 0);
        }
      }
    });

    test('an equal release is an equal value', () {
      const a = CoreSwipeRelease(
        outcome: CoreSwipeOutcome.closed,
        offset: 1,
        target: 0,
        velocity: 2,
      );
      const b = CoreSwipeRelease(
        outcome: CoreSwipeOutcome.closed,
        offset: 1,
        target: 0,
        velocity: 2,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('closed'));
    });
  });

  group('CoreSwipeGesture', () {
    const geometry = CoreSwipeGeometry(
      rowWidth: 400,
      leadingExtent: 132,
      trailingExtent: 72,
    );

    test('is idle until a press, pending until it has gone past the slop', () {
      final gesture = CoreSwipeGesture(geometry);
      expect(gesture.phase, CoreSwipePhase.idle);

      gesture.down(Duration.zero, 100, 40);
      expect(gesture.phase, CoreSwipePhase.pending);

      expect(
        gesture.move(_ms(16), 118, 40),
        CoreSwipePhase.pending,
        reason: 'exactly the slop is still a press',
      );
      expect(gesture.move(_ms(32), 119, 40), CoreSwipePhase.dragging);
    });

    test('a move or a lift with no press does nothing', () {
      final gesture = CoreSwipeGesture(geometry);

      expect(gesture.move(_ms(16), 118, 40), CoreSwipePhase.idle);
      expect(gesture.up(_ms(32)), isNull);
      expect(gesture.cancel(), isNull);
    });

    test('a rejected press ignores the rest of the stroke', () {
      final gesture = CoreSwipeGesture(geometry)..down(Duration.zero, 100, 40);

      expect(gesture.move(_ms(16), 102, 80), CoreSwipePhase.rejected);
      expect(gesture.move(_ms(32), 400, 80), CoreSwipePhase.rejected);
      expect(gesture.offset, 0);
      expect(gesture.up(_ms(48)), isNull);
      expect(gesture.phase, CoreSwipePhase.idle);
    });

    test('a diagonal stroke goes to the axis it travelled further on', () {
      final across = CoreSwipeGesture(geometry)..down(Duration.zero, 100, 40);
      expect(across.move(_ms(16), 140, 70), CoreSwipePhase.dragging);

      final along = CoreSwipeGesture(geometry)..down(Duration.zero, 100, 40);
      expect(along.move(_ms(16), 130, 90), CoreSwipePhase.rejected);
    });

    test('the row stays where it was found until the drag arms', () {
      final gesture = CoreSwipeGesture(geometry, startOffset: -72)
        ..down(Duration.zero, 200, 40);

      expect(gesture.offset, -72);
      gesture.move(_ms(16), 210, 40);
      expect(gesture.offset, -72);
    });

    test("the slop is the caller's to change", () {
      final gesture = CoreSwipeGesture(geometry, slop: 4)
        ..down(Duration.zero, 100, 40);

      expect(gesture.move(_ms(16), 105, 40), CoreSwipePhase.dragging);
    });

    test('forgets one press when the next goes down', () {
      final gesture = CoreSwipeGesture(geometry)
        ..down(Duration.zero, 100, 40)
        ..move(_ms(16), 140, 40);
      expect(gesture.phase, CoreSwipePhase.dragging);

      gesture.down(_ms(100), 300, 40);

      expect(gesture.phase, CoreSwipePhase.pending);
    });

    test('a lift reads the velocity as of the lift, not the last move', () {
      CoreSwipeRelease? liftAfter(int holdMs) {
        final gesture = CoreSwipeGesture(geometry)
          ..down(Duration.zero, 300, 40)
          ..move(_ms(16), 285, 40)
          ..move(_ms(32), 265, 40)
          ..move(_ms(48), 245, 40)
          ..move(_ms(64), 225, 40);

        return gesture.up(_ms(64 + holdMs));
      }

      expect(liftAfter(6)!.velocity, lessThan(-1000));
      expect(liftAfter(236)!.velocity, 0);
    });
  });

  group('CoreSwipeExclusivity', () {
    test('a row that claims it holds it', () {
      final scope = CoreSwipeExclusivity();
      final row = Object();

      scope.claim(row, () {});

      expect(scope.holds(row), isTrue);
      expect(scope.holder, same(row));
    });

    test('the next row to claim it closes the first', () {
      final scope = CoreSwipeExclusivity();
      final first = Object();
      final second = Object();
      final closed = <String>[];

      scope
        ..claim(first, () => closed.add('first'))
        ..claim(second, () => closed.add('second'));

      expect(closed, ['first']);
      expect(scope.holds(second), isTrue);
      expect(scope.holds(first), isFalse);
    });

    test('a row claiming again does not close itself', () {
      final scope = CoreSwipeExclusivity();
      final row = Object();
      var closed = 0;

      scope
        ..claim(row, () => closed++)
        ..claim(row, () => closed++);

      expect(closed, 0);
      expect(scope.holds(row), isTrue);
    });

    test('a closing row that releases while it is being closed is fine', () {
      final scope = CoreSwipeExclusivity();
      final first = Object();
      final second = Object();

      scope
        ..claim(first, () => scope.release(first))
        ..claim(second, () {});

      expect(scope.holds(second), isTrue, reason: 'the late release is void');
    });

    test('releasing a row that does not hold it changes nothing', () {
      final scope = CoreSwipeExclusivity();
      final holder = Object();

      scope
        ..claim(holder, () {})
        ..release(Object());

      expect(scope.holds(holder), isTrue);
    });

    test('a released claim leaves nobody to close', () {
      final scope = CoreSwipeExclusivity();
      final first = Object();
      var closed = 0;

      scope
        ..claim(first, () => closed++)
        ..release(first)
        ..claim(Object(), () {});

      expect(closed, 0);
      expect(scope.holder, isNotNull);
    });

    test('closeHolder closes whoever holds it, once', () {
      final scope = CoreSwipeExclusivity();
      final row = Object();
      var closed = 0;

      scope
        ..claim(row, () => closed++)
        ..closeHolder()
        ..closeHolder();

      expect(closed, 1);
      expect(scope.holder, isNull);
    });
  });

  group('CoreSwipeActionVariant', () {
    test('an ordinary action is a tonal button, a destructive one the error '
        'button', () {
      expect(
        CoreSwipeActionVariant.defaultVariant.toButtonVariant(),
        CoreButtonVariant.secondary,
      );
      expect(
        CoreSwipeActionVariant.destructive.toButtonVariant(),
        CoreButtonVariant.destructive,
      );
    });

    test('an action states its intent and defaults to an ordinary one', () {
      final action = CoreSwipeAction<Object>(label: 'Pin', onPressed: () {});

      expect(action.variant, CoreSwipeActionVariant.defaultSwipeActionVariant);
      expect(action.enabled, isTrue);
      expect(action.icon, isNull);
    });
  });

  group('CoreSwipeActionsStyle', () {
    test('the defaults are the design the docs state', () {
      expect(CoreSwipeActionsStyle.defaultActionWidth, 48);
      expect(CoreSwipeActionsStyle.defaultActionSpacing, 12);
      expect(CoreSwipeActionsStyle.defaultPlatterInset, 12);
      expect(CoreSwipeActionsStyle.defaultPlatterColor, CoreColor.transparent);
      expect(CoreSwipeActionsStyle.defaultLabelGapStyle.size, 4);
      expect(
        CoreSwipeActionsStyle.defaultLabelStyle.token,
        CoreTextStyles.labelSmall,
      );
      expect(CoreSwipeActionsStyle.defaultFullSwipeScale, 1);
    });

    test('merge lets the later style win field by field', () {
      const base = CoreSwipeActionsStyle(actionWidth: 40, actionSpacing: 8);
      const patch = CoreSwipeActionsStyle(
        actionSpacing: 16,
        platterInset: 4,
        fullSwipeScale: 1.08,
      );

      final merged = base.merge(patch);

      expect(merged.actionWidth, 40);
      expect(merged.actionSpacing, 16);
      expect(merged.platterInset, 4);
      expect(merged.fullSwipeScale, 1.08);
      expect(base.merge(null), same(base));
    });

    test("a style that states a field replaces the base's, and only that "
        'field', () {
      const base = CoreSwipeActionsStyle(actionWidth: 40, actionSpacing: 8);
      const loud = CoreSwipeActionsStyle(
        actionWidth: 44,
        platterColor: CoreColor(0xFF112233),
      );

      final merged = base.merge(loud);

      expect(merged.actionWidth, 44);
      expect(merged.actionSpacing, 8);
      expect(merged.platterColor, const CoreColor(0xFF112233));
    });

    test('merge folds the nested slots recursively', () {
      const base = CoreSwipeActionsStyle(
        labelGapStyle: CoreGapStyle(size: 2),
        actionButtonStyle: CoreButtonStyle(borderWidth: 2),
      );
      const patch = CoreSwipeActionsStyle(
        actionButtonStyle: CoreButtonStyle(borderRadius: CoreBorderRadius.zero),
      );

      final merged = base.merge(patch);

      expect(merged.labelGapStyle!.size, 2);
      expect(merged.actionButtonStyle!.borderWidth, 2);
      expect(merged.actionButtonStyle!.borderRadius, CoreBorderRadius.zero);
    });

    test('copyWith replaces only what it is given', () {
      const base = CoreSwipeActionsStyle(
        actionWidth: 40,
        platterColor: CoreColor.transparent,
      );

      final copy = base.copyWith(actionWidth: 56);

      expect(copy.actionWidth, 56);
      expect(copy.platterColor, CoreColor.transparent);
    });

    test('equality and hashing see every field', () {
      const a = CoreSwipeActionsStyle(
        actionWidth: 40,
        actionSpacing: 8,
        platterInset: 4,
        platterColor: CoreColor.transparent,
        labelGapStyle: CoreGapStyle(size: 2),
        labelStyle: CoreSwipeActionsStyle.defaultLabelStyle,
        fullSwipeScale: 1.08,
        actionButtonStyle: CoreButtonStyle(borderWidth: 2),
      );
      expect(a, a.copyWith());
      expect(a.hashCode, a.copyWith().hashCode);

      for (final changed in [
        a.copyWith(actionWidth: 41),
        a.copyWith(actionSpacing: 9),
        a.copyWith(platterInset: 5),
        a.copyWith(platterColor: const CoreColor(0xFF000000)),
        a.copyWith(labelGapStyle: const CoreGapStyle(size: 3)),
        a.copyWith(labelStyle: const CoreTextStyle(fontSize: 9)),
        a.copyWith(fullSwipeScale: 1.1),
        a.copyWith(actionButtonStyle: const CoreButtonStyle(borderWidth: 3)),
      ]) {
        expect(changed, isNot(a));
      }
    });
  });

  group('CoreSwipeActionsTheme', () {
    test('compares by its style', () {
      const style = CoreSwipeActionsStyle(actionWidth: 40);

      expect(
        const CoreSwipeActionsTheme(style: style),
        const CoreSwipeActionsTheme(style: style),
      );
      expect(
        const CoreSwipeActionsTheme(style: style).hashCode,
        const CoreSwipeActionsTheme(style: style).hashCode,
      );
      expect(
        const CoreSwipeActionsTheme(style: style),
        isNot(const CoreSwipeActionsTheme()),
      );
    });

    test('is a slot of the component theme', () {
      const theme = CoreComponentTheme(
        swipeActions: CoreSwipeActionsTheme(
          style: CoreSwipeActionsStyle(actionWidth: 40),
        ),
      );

      expect(theme.swipeActions?.style?.actionWidth, 40);
      expect(theme.copyWith().swipeActions, theme.swipeActions);
      expect(
        theme.copyWith(swipeActions: const CoreSwipeActionsTheme()),
        isNot(theme),
      );
    });
  });
}
