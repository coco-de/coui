/// The arithmetic of swiping a row — where it is, where it rests, whether the
/// pull runs an action — decided once for both platforms.
///
/// Flutter's gesture arena and a browser's pointer events deliver the same
/// finger differently, but what the row does with it is not a platform
/// question: how far it follows, how it resists, which pull runs the first
/// action and where a released row settles. Those are numbers and
/// predicates, so they live here; the seats feed them a pointer and paint
/// what they answer. `test/fixtures/swipe_actions_vectors.json` states the
/// answers, pointer trace by pointer trace, and every layer is held to it.
///
/// ## Units and signs
///
/// * Positions and offsets are logical pixels (CSS pixels on the Web).
/// * Velocities are logical pixels per **second**.
/// * Thresholds written as a fraction are of the base their doc states.
/// * Everything a seat hands in or reads back is **physical**: positive is
///   toward the right. The reading direction is applied in exactly one place,
///   [CoreSwipeGeometry]'s private flip, so no seat negates anything.
///   Inside, the arithmetic is **logical**: positive reveals the leading
///   actions (the start edge), negative the trailing ones.
library;

import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/swipe_actions/swipe_actions_contract.dart';
import 'package:coui_core/src/component/contracts/swipe_actions/swipe_actions_outcome.dart';
import 'package:coui_core/src/drag/core_drag_velocity.dart';
import 'package:meta/meta.dart';

/// Which edge's actions a row is revealing.
enum CoreSwipeSide {
  /// The actions at the reading-start edge — left in a left-to-right locale.
  leading(1),

  /// The actions at the reading-end edge — right in a left-to-right locale.
  trailing(-1);

  const CoreSwipeSide(this.sign);

  /// The sign of the **logical** offset that reveals this side.
  final int sign;
}

/// What lifting the pointer (or the system taking it) decided.
@immutable
final class CoreSwipeRelease {
  /// Creates a [CoreSwipeRelease].
  const CoreSwipeRelease({
    required this.outcome,
    required this.offset,
    required this.target,
    required this.velocity,
  });

  /// Where the row will rest, and whether an action runs first.
  final CoreSwipeOutcome outcome;

  /// The row's physical offset at the moment of release (px).
  final double offset;

  /// The physical offset the row settles at (px): `0` closed, the platter's
  /// width toward the revealed side when open, `0` after an action ran.
  final double target;

  /// The pointer's physical velocity at release (px/s) — what a seat
  /// carries into its settle.
  final double velocity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwipeRelease &&
          outcome == other.outcome &&
          offset == other.offset &&
          target == other.target &&
          velocity == other.velocity;

  @override
  int get hashCode => Object.hash(outcome, offset, target, velocity);

  @override
  String toString() =>
      'CoreSwipeRelease($outcome, offset: $offset, target: $target, '
      'velocity: $velocity)';
}

/// The measures a row is swiped within, and the rules that read them.
///
/// Built once per gesture by a seat from what it knows — the row's measured
/// width, the platter widths (`CoreSwipeActionsStyle.extentFor`), the
/// widget's full-swipe parameters and the reading direction — and then
/// asked. It holds no state.
@immutable
final class CoreSwipeGeometry {
  /// Creates a [CoreSwipeGeometry].
  const CoreSwipeGeometry({
    required this.rowWidth,
    this.leadingExtent = 0,
    this.trailingExtent = 0,
    this.leadingFullSwipe = CoreSwipeActionsContract.defaultAllowsFullSwipe,
    this.trailingFullSwipe = CoreSwipeActionsContract.defaultAllowsFullSwipe,
    this.fullSwipeThreshold =
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
    this.rtl = false,
  }) : assert(rowWidth >= 0, 'The row cannot have a negative width.'),
       assert(leadingExtent >= 0, 'The platter cannot have a negative width.'),
       assert(trailingExtent >= 0, 'The platter cannot have a negative width.'),
       assert(
         fullSwipeThreshold > 0 && fullSwipeThreshold <= 1,
         'The full-swipe threshold is a fraction of the row, above 0 and at '
         'most 1.',
       );

  /// The row's width (px) — the farthest a full swipe can pull it, and the
  /// base of [fullSwipeThreshold].
  final double rowWidth;

  /// How far the row has to move to uncover every leading action (px); `0`
  /// when there are none. See `CoreSwipeActionsStyle.extentFor`.
  final double leadingExtent;

  /// How far the row has to move to uncover every trailing action (px); `0`
  /// when there are none.
  final double trailingExtent;

  /// Whether pulling the row far enough runs the first leading action. Off
  /// when the caller turned full swipe off or the first action is disabled;
  /// then a pull past the platter resists instead.
  final bool leadingFullSwipe;

  /// Whether pulling the row far enough runs the first trailing action.
  final bool trailingFullSwipe;

  /// How far a pull runs the first action, as a fraction of [rowWidth].
  final double fullSwipeThreshold;

  /// Whether the reading direction is right-to-left.
  final bool rtl;

  /// The platter width of [side] (px).
  double extentOf(CoreSwipeSide side) =>
      side == CoreSwipeSide.leading ? leadingExtent : trailingExtent;

  /// Whether [side]'s first action runs on a full pull.
  bool fullSwipeOf(CoreSwipeSide side) =>
      side == CoreSwipeSide.leading ? leadingFullSwipe : trailingFullSwipe;

  /// How far [side] has to be pulled to run its first action (px): the
  /// threshold's share of the row.
  ///
  /// Where the platter itself already reaches that share, the pull has to go
  /// [CoreSwipeActionsContract.defaultFullSwipeOvershoot] beyond the platter
  /// — a row must be able to open before it runs an action, and a pull that
  /// has only just left the open pose is still an opening. A row cannot be
  /// pulled further than its own width, so a platter as wide as the row has
  /// no full swipe at all, as before.
  double fullSwipeDistanceOf(CoreSwipeSide side) {
    final share = fullSwipeThreshold * rowWidth;
    final extent = extentOf(side);

    return extent < share
        ? share
        : extent + CoreSwipeActionsContract.defaultFullSwipeOvershoot;
  }

  /// The side a **physical** [offset] has revealed, or `null` while the row
  /// is within [CoreSwipeActionsContract.restTolerance] of closed.
  CoreSwipeSide? sideOf(double offset) {
    final logical = _flip(offset);
    if (logical > CoreSwipeActionsContract.restTolerance) {
      return CoreSwipeSide.leading;
    }
    if (logical < -CoreSwipeActionsContract.restTolerance) {
      return CoreSwipeSide.trailing;
    }

    return null;
  }

  /// The **physical** offset the row takes when the pointer would carry it
  /// to [raw] (px) if nothing held it back.
  ///
  /// * A side with no actions does not move: `0`.
  /// * Within the platter the row follows exactly.
  /// * Past the platter it follows on — to at most the row's own width —
  ///   when that side's full swipe is on, and otherwise resists: the row
  ///   moves [CoreSwipeActionsContract.defaultResistance] of the excess.
  /// * A gesture that started with a side open ([lockedSide]) cannot carry
  ///   the row across closed to the other side: the other side is `0`.
  double constrain(double raw, {CoreSwipeSide? lockedSide}) {
    final logical = _flip(raw);
    if (logical == 0) return 0;

    final side = logical > 0 ? CoreSwipeSide.leading : CoreSwipeSide.trailing;
    if (lockedSide != null && side != lockedSide) return 0;

    final extent = extentOf(side);
    if (extent <= 0) return 0;

    final pull = logical.abs();
    if (pull <= extent) return raw;

    final beyond = fullSwipeOf(side)
        ? math.max(extent, math.min(pull, rowWidth))
        : extent + (pull - extent) * CoreSwipeActionsContract.defaultResistance;

    return _flip(side.sign * beyond);
  }

  /// What releasing the row at **physical** [offset], with the pointer
  /// moving at physical [velocity] (px/s), does.
  ///
  /// In order:
  ///
  /// 1. Within rest of closed, or on a side with no actions: closed.
  /// 2. Moving **away** from the actions at
  ///    [CoreSwipeActionsContract.defaultFlingVelocity] or faster: closed.
  ///    A flick back cancels even a pull that had gone past the full-swipe
  ///    distance, so an action that cannot be undone never runs on a gesture
  ///    that was being taken back.
  /// 3. Pulled past the platter and at least [fullSwipeDistanceOf] with that
  ///    side's full swipe on: that side's first action runs.
  /// 4. Moving **toward** the actions at flick speed or faster: open,
  ///    however short the pull.
  /// 5. Otherwise the nearer rest: open when the row is at least
  ///    [CoreSwipeActionsContract.defaultOpenThreshold] of the platter out,
  ///    closed when it is not.
  CoreSwipeOutcome settle(double offset, {double velocity = 0}) {
    final side = sideOf(offset);
    if (side == null) return CoreSwipeOutcome.closed;

    final extent = extentOf(side);
    if (extent <= 0) return CoreSwipeOutcome.closed;

    // Positive: the pointer is carrying the row further out.
    final toward = _flip(velocity) * side.sign;
    if (toward <= -CoreSwipeActionsContract.defaultFlingVelocity) {
      return CoreSwipeOutcome.closed;
    }

    final pull = _flip(offset).abs();
    if (fullSwipeOf(side) &&
        pull > extent &&
        pull >= fullSwipeDistanceOf(side)) {
      return side == CoreSwipeSide.leading
          ? CoreSwipeOutcome.executeLeading
          : CoreSwipeOutcome.executeTrailing;
    }

    final open = side == CoreSwipeSide.leading
        ? CoreSwipeOutcome.openLeading
        : CoreSwipeOutcome.openTrailing;
    if (toward >= CoreSwipeActionsContract.defaultFlingVelocity) return open;

    return pull >= CoreSwipeActionsContract.defaultOpenThreshold * extent
        ? open
        : CoreSwipeOutcome.closed;
  }

  /// The **physical** offset a row settles at for [outcome] (px).
  double targetOf(CoreSwipeOutcome outcome) => switch (outcome) {
    CoreSwipeOutcome.openLeading => _flip(leadingExtent),
    CoreSwipeOutcome.openTrailing => _flip(-trailingExtent),
    _ => 0,
  };

  /// The **physical** offset a row rests at with [side]'s actions uncovered
  /// (px); `0` for a side with none.
  ///
  /// Where a row goes when something other than a pointer opens a side —
  /// keyboard focus reaching one of its actions. It is the target of the
  /// side's open outcome, so a row opened by focus rests exactly where one
  /// opened by a pull does.
  double openOffsetOf(CoreSwipeSide side) => targetOf(switch (side) {
    CoreSwipeSide.leading => CoreSwipeOutcome.openLeading,
    CoreSwipeSide.trailing => CoreSwipeOutcome.openTrailing,
  });

  /// The single place the reading direction is applied: physical ↔ logical
  /// is the same flip both ways. Never `-0`.
  double _flip(num value) {
    final flipped = rtl ? -value.toDouble() : value.toDouble();

    return flipped == 0 ? 0 : flipped;
  }
}

/// One drag, from the moment it is recognised to the release.
///
/// A seat creates it when its own recogniser has decided the pointer is
/// dragging the row (Flutter's gesture arena; on the Web
/// [CoreSwipeGesture]), at the pointer's position then — the slop travelled
/// before that is forgiven, so the row does not jump. It then asks [update]
/// for the row's offset at each pointer position and [release] for what the
/// lift decides.
final class CoreSwipeDrag {
  /// Starts a drag from a row at **physical** [startOffset] (px), with the
  /// pointer at physical [anchor] (px).
  CoreSwipeDrag(this.geometry, {required this.anchor, this.startOffset = 0})
    : _lockedSide = geometry.sideOf(startOffset),
      _offset = startOffset;

  /// The measures the drag runs in.
  final CoreSwipeGeometry geometry;

  /// The row's physical offset when the drag began (px).
  final double startOffset;

  /// The pointer's physical position when the drag began (px).
  final double anchor;

  final CoreSwipeSide? _lockedSide;
  double _offset;

  /// The row's physical offset now (px).
  double get offset => _offset;

  /// The row's offset when the pointer is at physical [x] (px).
  double update(double x) {
    return _offset = geometry.constrain(
      startOffset + (x - anchor),
      lockedSide: _lockedSide,
    );
  }

  /// The pointer lifted at physical [velocity] (px/s): where the row goes.
  CoreSwipeRelease release(double velocity) {
    final outcome = geometry.settle(_offset, velocity: velocity);

    return CoreSwipeRelease(
      outcome: outcome,
      offset: _offset,
      target: geometry.targetOf(outcome),
      velocity: velocity,
    );
  }

  /// The system took the pointer: the row goes back to where the drag found
  /// it. A cancelled pull never runs an action, however far it had got.
  CoreSwipeRelease cancel() {
    final outcome = switch (_lockedSide) {
      null => CoreSwipeOutcome.closed,
      CoreSwipeSide.leading => CoreSwipeOutcome.openLeading,
      CoreSwipeSide.trailing => CoreSwipeOutcome.openTrailing,
    };

    return CoreSwipeRelease(
      outcome: outcome,
      offset: _offset,
      target: geometry.targetOf(outcome),
      velocity: 0,
    );
  }
}

/// Where a pointer is in the life of a press on the row.
enum CoreSwipePhase {
  /// No press.
  idle,

  /// Pressed, not yet moved far enough to say which way it is going.
  pending,

  /// Recognised as a horizontal drag: the row follows the pointer.
  dragging,

  /// Went vertical first: the press belongs to a scroller, not to the row.
  rejected,
}

/// The pointer-level life of one press, for a seat that gets raw pointer
/// events — the Web.
///
/// A press is **pending** until the pointer has travelled more than the slop
/// ([CoreSwipeActionsContract.defaultDragSlop]) from where it went down. If
/// the pull is then at least as much along the row as across it the press is
/// **dragging** — it hands [CoreSwipeDrag] the pointer's position at that
/// moment — and otherwise it is **rejected**, left to whatever scrolls. The
/// lift asks the tracker how fast the pointer was going, as of the lift, and
/// the release rules decide the rest.
///
/// It knows nothing of events, element ids or capture: positions are
/// physical px and times are [Duration]s from any shared origin, so a vector
/// table can drive it with a manual clock.
final class CoreSwipeGesture {
  /// Creates a gesture for a row at physical [startOffset] (px).
  CoreSwipeGesture(
    this.geometry, {
    this.startOffset = 0,
    this.slop = CoreSwipeActionsContract.defaultDragSlop,
  });

  /// The measures the press runs in.
  final CoreSwipeGeometry geometry;

  /// The row's physical offset when the press began (px).
  final double startOffset;

  /// How far the pointer must travel before the press means anything (px).
  final double slop;

  final CoreDragVelocityTracker _velocity = CoreDragVelocityTracker();
  CoreSwipePhase _phase = CoreSwipePhase.idle;
  CoreSwipeDrag? _drag;
  double _downX = 0;
  double _downY = 0;

  /// Where the press is.
  CoreSwipePhase get phase => _phase;

  /// The row's physical offset now (px): where it began until the press is a
  /// drag.
  double get offset => _drag?.offset ?? startOffset;

  /// The pointer went down at ([x], [y]) at [time].
  void down(Duration time, double x, double y) {
    _velocity
      ..reset()
      ..addSample(time, x);
    _downX = x;
    _downY = y;
    _drag = null;
    _phase = CoreSwipePhase.pending;
  }

  /// The pointer moved to ([x], [y]) at [time]; returns the phase after it.
  CoreSwipePhase move(Duration time, double x, double y) {
    if (_phase == CoreSwipePhase.idle || _phase == CoreSwipePhase.rejected) {
      return _phase;
    }
    _velocity.addSample(time, x);

    if (_phase == CoreSwipePhase.pending) {
      final across = (x - _downX).abs();
      final along = (y - _downY).abs();
      if (across > slop && across >= along) {
        _drag = CoreSwipeDrag(geometry, startOffset: startOffset, anchor: x);
        _phase = CoreSwipePhase.dragging;
      } else if (along > slop && along > across) {
        _phase = CoreSwipePhase.rejected;
      }

      return _phase;
    }

    _drag!.update(x);

    return _phase;
  }

  /// The pointer lifted at [time]. A release when the press was a drag;
  /// `null` for a tap or a press a scroller took.
  CoreSwipeRelease? up(Duration time) {
    final drag = _drag;
    final release = drag?.release(_velocity.velocityAt(time));
    _finish();

    return release;
  }

  /// The system took the pointer. The row goes back to where the press found
  /// it; `null` when the press had not become a drag.
  CoreSwipeRelease? cancel() {
    final release = _drag?.cancel();
    _finish();

    return release;
  }

  void _finish() {
    _drag = null;
    _phase = CoreSwipePhase.idle;
    _velocity.reset();
  }
}

/// Which row of a scope is open, so opening another closes it.
///
/// A scope holds one of these. A row [claim]s it when it starts to move or
/// opens, handing over what closes it; the previous holder is closed. A row
/// [release]s it when it has come to rest closed or goes away.
final class CoreSwipeExclusivity {
  Object? _holder;
  void Function()? _close;

  /// The row that holds the claim, if any.
  Object? get holder => _holder;

  /// Whether [row] holds the claim.
  bool holds(Object row) => identical(_holder, row);

  /// [row] has started to move or opened; [close] closes it. Any other
  /// holder is closed first.
  void claim(Object row, void Function() close) {
    final previous = identical(_holder, row) ? null : _close;
    _holder = row;
    _close = close;
    previous?.call();
  }

  /// [row] is closed again, or gone. A no-op for a row that does not hold
  /// the claim.
  void release(Object row) {
    if (!identical(_holder, row)) return;
    _holder = null;
    _close = null;
  }

  /// Closes the holder, if there is one.
  void closeHolder() {
    final close = _close;
    _holder = null;
    _close = null;
    close?.call();
  }
}
