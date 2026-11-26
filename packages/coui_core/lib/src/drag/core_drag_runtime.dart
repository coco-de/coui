import 'package:coui_core/src/drag/core_drag_activation.dart';
import 'package:coui_core/src/drag/core_drag_collision.dart';
import 'package:coui_core/src/drag/core_drag_event.dart';
import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:coui_core/src/drag/core_drag_modifier.dart';
import 'package:coui_core/src/drag/core_drag_registry.dart';
import 'package:coui_core/src/drag/core_drag_state.dart';

/// The platform-neutral drag state machine.
///
/// Platform adapters own input and painting; this owns *what a drag means*.
/// An adapter feeds raw pointer facts ([pointerDown] / [pointerMove] /
/// [pointerUp] / [cancel]) and receives lifecycle events — so Flutter and
/// Web run one implementation of activation, collision and session
/// bookkeeping instead of two that drift.
///
/// The runtime is deliberately not a listenable: `ChangeNotifier` is a
/// Flutter type and `InheritedComponent` a Jaspr one. Each adapter wraps
/// this in its own notification primitive.
class CoreDragRuntime {
  /// Creates a drag runtime.
  CoreDragRuntime({
    CoreDragRegistry? registry,
    CoreDragCollisionDetector collisionDetector =
        CoreDragCollisions.pointerWithin,
    this.onDragStart,
    this.onDragMove,
    this.onDragOver,
    this.onDragEnd,
    this.onDragCancel,
    this.onStateChanged,
    Iterable<CoreDragModifier> modifiers = const <CoreDragModifier>[],
  }) : registry = registry ?? CoreDragRegistry(),
       _collisionDetector = collisionDetector,
       _modifiers = List<CoreDragModifier>.unmodifiable(modifiers);

  /// Registered participants and their measured geometry.
  final CoreDragRegistry registry;

  /// Called once when a session earns activation.
  final CoreDragStartCallback? onDragStart;

  /// Called on every move of a live session.
  final CoreDragMoveCallback? onDragMove;

  /// Called when the drop zone under the drag changes.
  final CoreDragOverCallback? onDragOver;

  /// Called when a session is released.
  final CoreDragEndCallback? onDragEnd;

  /// Called when a session ends without a drop.
  final CoreDragCancelCallback? onDragCancel;

  /// Called after any state transition, so adapters can repaint.
  final void Function(CoreDragState state)? onStateChanged;

  final CoreDragCollisionDetector _collisionDetector;

  /// Constraints applied to every move, in declaration order.
  final List<CoreDragModifier> _modifiers;

  CoreDragState _state = const CoreDragIdle();
  CoreDragActivationConstraint _constraint = .immediate;

  /// The current lifecycle state.
  CoreDragState get state => _state;

  /// The item being dragged, when a session is live.
  CoreDragId? get activeId => _state.activeId;

  /// The drop zone under the drag, when there is one.
  CoreDragId? get overId =>
      _state is CoreDragging ? (_state as CoreDragging).overId : null;

  /// The live session, when one exists.
  CoreDragSession? get session =>
      _state is CoreDragging ? (_state as CoreDragging).session : null;

  /// Whether no session is live or pending.
  bool get isIdle => _state is CoreDragIdle;

  /// Records a pointer landing on [id] without starting a drag yet.
  ///
  /// The session stays [CoreDragPending] until [constraint] is satisfied,
  /// which is what lets the same element still resolve a tap.
  void pointerDown(
    CoreDragId id, {
    required CoreDragPoint position,
    CoreDragInputKind inputKind = .pointer,
    CoreDragActivationConstraint constraint = .immediate,
  }) {
    if (!isIdle) return;
    if (!registry.hasItem(id)) return;

    _constraint = constraint;
    _setState(
      CoreDragPending(pendingId: id, origin: position, inputKind: inputKind),
    );
  }

  /// Advances the interaction to [position].
  ///
  /// Activates a pending pointer once it satisfies the constraint, then
  /// tracks the live session.
  void pointerMove(CoreDragPoint position, {Duration elapsed = .zero}) {
    switch (_state) {
      case CoreDragPending(:final pendingId, :final origin, :final inputKind):
        final activated = _constraint.isSatisfiedBy(
          origin: origin,
          current: position,
          elapsed: elapsed,
        );
        if (!activated) return;

        // Anchor at the press point, not at the position that crossed the
        // threshold — otherwise the item jumps by the activation distance
        // the moment it starts moving.
        final started = CoreDragSession(
          activeId: pendingId,
          origin: origin,
          pointer: _constrain(
            activeId: pendingId,
            origin: origin,
            position: position,
          ),
          inputKind: inputKind,
        );
        final startedOver = _resolveOver(started);
        _setState(CoreDragging(session: started, overId: startedOver));
        onDragStart?.call(CoreDragStartEvent(session: started));
        // A drag can activate already inside a zone (a press that travels
        // straight onto a target). That is still an entry, so report it —
        // otherwise the zone never learns it is hovered until the pointer
        // happens to leave and re-enter.
        if (startedOver != null) {
          onDragOver?.call(
            CoreDragOverEvent(session: started, overId: startedOver),
          );
        }
        _emitMove(started);

      case CoreDragging(:final session, :final overId):
        final moved = session.movedTo(
          _constrain(
            activeId: session.activeId,
            origin: session.origin,
            position: position,
          ),
        );
        final nextOver = _resolveOver(moved);
        _setState(CoreDragging(session: moved, overId: nextOver));
        if (nextOver != overId) {
          onDragOver?.call(
            CoreDragOverEvent(session: moved, overId: nextOver),
          );
        }
        _emitMove(moved);

      case CoreDragIdle():
    }
  }

  /// Releases the interaction.
  ///
  /// A pending pointer that never activated resolves silently — it was a
  /// tap, and the caller's own tap handling owns it.
  void pointerUp() {
    switch (_state) {
      case CoreDragging(:final session, :final overId):
        _setState(const CoreDragIdle());
        onDragEnd?.call(CoreDragEndEvent(session: session, overId: overId));

      case CoreDragPending():
        _setState(const CoreDragIdle());

      case CoreDragIdle():
    }
  }

  /// Aborts the interaction.
  void cancel({
    CoreDragCancelReason reason = .pointerCancelled,
  }) {
    switch (_state) {
      case CoreDragging(:final session):
        _setState(const CoreDragIdle());
        onDragCancel?.call(
          CoreDragCancelEvent(session: session, reason: reason),
        );

      case CoreDragPending():
        _setState(const CoreDragIdle());

      case CoreDragIdle():
    }
  }

  /// Drops a live session whose item left the scope.
  ///
  /// Without this a list that removes the dragged row mid-drag would keep
  /// reporting movement for an item that no longer exists.
  void handleItemRemoved(CoreDragId id) {
    if (_state.activeId == id || _pendingId == id) {
      cancel(reason: .itemRemoved);
    }
  }

  CoreDragId? get _pendingId =>
      _state is CoreDragPending ? (_state as CoreDragPending).pendingId : null;

  void _emitMove(CoreDragSession session) {
    onDragMove?.call(
      CoreDragMoveEvent(session: session, overId: overId),
    );
  }

  /// Where the drag effectively is, once modifiers have had their say.
  ///
  /// Constraining the position itself — rather than only what gets painted
  /// — keeps one source of truth: movement, collision and the reorder
  /// maths all read the same, already-constrained point, so an axis-locked
  /// drag cannot resolve against a sideways position it never had.
  CoreDragPoint _constrain({
    required CoreDragId activeId,
    required CoreDragPoint origin,
    required CoreDragPoint position,
  }) {
    if (_modifiers.isEmpty) return position;

    final constrained = CoreDragModifiers.apply(
      _modifiers,
      CoreDragModifierInput(
        transform: CoreDragOffset(
          x: position.x - origin.x,
          y: position.y - origin.y,
        ),
        itemRect: registry.itemRects[activeId],
        containerRect: registry.containerRect,
      ),
    );

    return CoreDragPoint(origin.x + constrained.x, origin.y + constrained.y);
  }

  CoreDragId? _resolveOver(CoreDragSession session) => _collisionDetector(
    CoreDragCollisionInput(
      activeId: session.activeId,
      pointer: session.pointer,
      dropZoneRects: registry.dropZoneRects,
      activeRect: registry.itemRects[session.activeId],
    ),
  );

  void _setState(CoreDragState next) {
    if (_state == next) return;
    _state = next;
    onStateChanged?.call(next);
  }
}
