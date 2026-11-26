/// The pointer, focus and scope life of one `SwipeActions` row on the Web,
/// without the DOM.
///
/// A browser hands out pointer events and a layout; it has no gesture arena
/// and no spring. So the Web seat does what Flutter's framework does for the
/// Flutter one: it decides when a press has become a swipe, follows it, and
/// says where the row rests. The decisions are Core's
/// ([CoreSwipeGesture] and the geometry it runs in); [SwipeActionsRow] is the
/// state around them — where the row is painted, which side it rests open on,
/// whether the scope has been told, and what a lift, a focus, `Escape` or a
/// pressed action does to all of it.
///
/// It knows nothing of events, element ids or capture: positions are physical
/// px, times are [Duration]s from any shared origin, and the geometry the DOM
/// measured is handed in with each press, so
/// `packages/coui_core/test/fixtures/swipe_actions_vectors.json` replays on
/// it with a manual clock exactly as it replays on the Flutter widget.
library;

import 'package:coui_core/coui_core.dart';

/// One row's state, driven by whatever feeds it pointer events.
///
/// The host (the component) owns the DOM: it measures the row and its
/// platters, translates events into the numbers this takes, applies
/// [offset] to the row, and calls [onChanged]'s `setState`.
final class SwipeActionsRow {
  /// Creates a row model.
  ///
  /// [onChanged] is called whenever something the host paints changed;
  /// [onExecute] is called with the side whose first action a full swipe ran.
  SwipeActionsRow({required this.onChanged, required this.onExecute});

  /// Called after any change to what the host paints.
  final void Function() onChanged;

  /// Called when a release ran the first action of a side — after [onChanged].
  final void Function(CoreSwipeSide side) onExecute;

  CoreSwipeExclusivity? _scope;
  CoreSwipeGeometry _geometry = const CoreSwipeGeometry(rowWidth: 0);
  CoreSwipeGesture? _gesture;
  CoreSwipeRelease? _lastRelease;
  CoreSwipeSide? _resting;
  double _offset = 0;
  bool _dragging = false;
  bool _enabled = true;
  bool _swallowClick = false;

  /// Where the row is painted (physical px, positive toward the right).
  ///
  /// While the row settles this is the rest position it is heading to — the
  /// host animates the way there with a transition.
  double get offset => _offset;

  /// Whether a pointer is moving the row. The host paints without a
  /// transition while it is.
  bool get dragging => _dragging;

  /// The side the row rests open on, or is settling open to; `null` when it
  /// rests (or heads) closed.
  CoreSwipeSide? get restingSide => _resting;

  /// Whether the row rests open on a side.
  bool get isOpen => _resting != null;

  /// The side the row has revealed at its current [offset], or `null` while
  /// it is within the rest tolerance of closed. This is the platter the host
  /// shows.
  CoreSwipeSide? get revealedSide => _geometry.sideOf(_offset);

  /// How much of [revealedSide]'s platter is uncovered (px) — the row's
  /// distance from closed.
  double get reveal => revealedSide == null ? 0 : _offset.abs();

  /// Whether the row is being pulled far enough that releasing now would run
  /// the first action — the cue the host scales the outer action for.
  bool get inFullSwipeZone => _dragging && _geometry.settle(_offset).executes;

  /// What the last lift (or cancel) decided; `null` before the first.
  CoreSwipeRelease? get lastRelease => _lastRelease;

  /// The geometry of the latest press, as the DOM measured it.
  CoreSwipeGeometry get geometry => _geometry;

  /// Whether the row can be swiped at all.
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) close();
  }

  /// The scope this row shares with its neighbours, or `null` when there is
  /// none. Moving to another scope hands an open row's claim over.
  CoreSwipeExclusivity? get scope => _scope;
  set scope(CoreSwipeExclusivity? next) {
    if (identical(_scope, next)) return;
    _scope?.release(this);
    _scope = next;
    if (_resting != null || _dragging) _claim();
  }

  /// A pointer went down at ([x], [y]) at [time].
  ///
  /// [measured] is what the DOM reports now: the row's width, the platters'
  /// widths, the reading direction and the widget's full-swipe parameters.
  /// [paintedOffset], when the DOM can say, is where the row actually is — a
  /// row grabbed while it is still settling is somewhere short of its rest
  /// position, and the drag has to start there or it would jump.
  ///
  /// Returns `false` when the row is disabled and the press is not tracked.
  bool pointerDown(
    Duration time,
    double x,
    double y,
    CoreSwipeGeometry measured, {
    double? paintedOffset,
  }) {
    if (!_enabled) return false;
    _geometry = measured;
    final start =
        paintedOffset == null ||
            (paintedOffset - _offset).abs() <=
                CoreSwipeActionsContract.restTolerance
        ? _offset
        : paintedOffset;
    _swallowClick = false;
    _gesture = CoreSwipeGesture(measured, startOffset: start)..down(time, x, y);

    return true;
  }

  /// The pointer moved to ([x], [y]) at [time]. Returns the press's phase
  /// after the move; the move that turns it into [CoreSwipePhase.dragging] is
  /// the moment the host takes the pointer.
  CoreSwipePhase pointerMove(Duration time, double x, double y) {
    final gesture = _gesture;
    if (gesture == null) return CoreSwipePhase.idle;

    final before = gesture.phase;
    final after = gesture.move(time, x, y);
    if (after == CoreSwipePhase.rejected) {
      _gesture = null;
    } else if (after == CoreSwipePhase.dragging) {
      if (before != CoreSwipePhase.dragging) {
        _dragging = true;
        _claim();
      }
      _offset = gesture.offset;
      onChanged();
    }

    return after;
  }

  /// The pointer lifted at [time]. The release the lift decided, or `null`
  /// when the press was a tap, or went vertical and belongs to a scroller.
  CoreSwipeRelease? pointerUp(Duration time) {
    final gesture = _gesture;
    _gesture = null;
    final release = gesture?.up(time);
    if (release == null) return null;

    _swallowClick = true;
    _settle(release);

    return release;
  }

  /// The system took the pointer. The row goes back to where the press found
  /// it, and no action runs.
  CoreSwipeRelease? pointerCancel() {
    final gesture = _gesture;
    _gesture = null;
    final release = gesture?.cancel();
    if (release == null) return null;

    _swallowClick = false;
    _settle(release);

    return release;
  }

  /// Opens [side] without a pointer — focus reached one of its actions.
  /// [measured] is what the DOM reports now. A row already open on [side], or
  /// one with nothing on it, is left alone.
  void open(CoreSwipeSide side, CoreSwipeGeometry measured) {
    if (!_enabled || (_resting == side && !_dragging)) return;
    if (measured.extentOf(side) <= 0) return;

    _geometry = measured;
    _gesture = null;
    _dragging = false;
    _resting = side;
    _offset = measured.openOffsetOf(side);
    _claim();
    onChanged();
  }

  /// Closes the row. Returns whether there was anything to close.
  bool close() {
    final wasMoved = _resting != null || _dragging || _offset != 0;
    _gesture = null;
    _dragging = false;
    _resting = null;
    _offset = 0;
    _scope?.release(this);
    if (wasMoved) onChanged();

    return wasMoved;
  }

  /// `Escape` was pressed. Closes an open row; returns whether it did, so the
  /// host knows to take focus back from a platter it is about to hide.
  bool escape() => isOpen && close();

  /// An action was pressed: [run] it, then close the row.
  void press(void Function() run) {
    run();
    close();
  }

  /// Whether the click that follows a drag's release is the drag's own — the
  /// browser dispatches one to the element that held the pointer — and so
  /// must not reach whatever the caller listens on. Consumed by the first
  /// click that asks.
  bool takeSwallowedClick() {
    final swallow = _swallowClick;
    _swallowClick = false;

    return swallow;
  }

  /// Forgets a swallowed click that never came (a touch lift produces none).
  void forgetSwallowedClick() => _swallowClick = false;

  /// The row is going away: it no longer holds the scope.
  void dispose() {
    _gesture = null;
    _scope?.release(this);
  }

  void _settle(CoreSwipeRelease release) {
    _lastRelease = release;
    _dragging = false;
    _offset = release.target;
    _resting = release.outcome.isOpen ? release.outcome.side : null;
    if (_resting == null) {
      _scope?.release(this);
    } else {
      _claim();
    }
    onChanged();
    if (release.outcome.executes) onExecute(release.outcome.side!);
  }

  void _claim() => _scope?.claim(this, close);
}
