import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:meta/meta.dart';

/// What ended a drag session without a drop.
enum CoreDragCancelReason {
  /// The pointer interaction was aborted (OS gesture steal, lost capture).
  pointerCancelled,

  /// The user cancelled deliberately (Escape during a keyboard drag).
  dismissed,

  /// The dragged item left the scope while the session was live.
  itemRemoved;

  @override
  String toString() => 'CoreDragCancelReason.$name';
}

/// How a drag session was activated.
enum CoreDragInputKind {
  /// Mouse or trackpad.
  pointer,

  /// Touch contact.
  touch,

  /// Keyboard (pick up / arrow keys / drop).
  keyboard;

  @override
  String toString() => 'CoreDragInputKind.$name';
}

/// A live drag session.
///
/// [transform] is anchored at [origin], so consumers position the dragged
/// item as `positionAtDragStart + transform` — accumulating per-move deltas
/// would drift whenever move events are coalesced or dropped.
@immutable
class CoreDragSession {
  /// Creates a drag session.
  const CoreDragSession({
    required this.activeId,
    required this.origin,
    required this.pointer,
    required this.inputKind,
  });

  /// The item being dragged.
  final CoreDragId activeId;

  /// The pointer position when the session started.
  final CoreDragPoint origin;

  /// The latest pointer position.
  final CoreDragPoint pointer;

  /// What activated this session.
  final CoreDragInputKind inputKind;

  /// Movement from [origin] to [pointer].
  CoreDragOffset get transform =>
      .new(x: pointer.x - origin.x, y: pointer.y - origin.y);

  /// Returns a copy of this session at [pointer].
  CoreDragSession movedTo(CoreDragPoint pointer) => .new(
    activeId: activeId,
    origin: origin,
    pointer: pointer,
    inputKind: inputKind,
  );

  @override
  bool operator ==(Object other) =>
      other is CoreDragSession &&
      other.activeId == activeId &&
      other.origin == origin &&
      other.pointer == pointer &&
      other.inputKind == inputKind;

  @override
  int get hashCode =>
      Object.hash(CoreDragSession, activeId, origin, pointer, inputKind);

  @override
  String toString() =>
      'CoreDragSession(activeId: $activeId, origin: $origin, '
      'pointer: $pointer, inputKind: $inputKind)';
}

/// The engine's drag lifecycle state.
@immutable
sealed class CoreDragState {
  /// Creates a drag state.
  const CoreDragState();

  /// The item being dragged, when a session exists.
  CoreDragId? get activeId => null;
}

/// Nothing is being dragged.
@immutable
final class CoreDragIdle extends CoreDragState {
  /// Creates the idle state.
  const CoreDragIdle();

  @override
  bool operator ==(Object other) => other is CoreDragIdle;

  @override
  int get hashCode => Object.hash(CoreDragIdle, 0);

  @override
  String toString() => 'CoreDragIdle()';
}

/// A pointer is down but the activation constraint is not met yet.
///
/// This state exists so a tap can still resolve as a tap: nothing moves and
/// no drag callbacks fire until the pointer earns the session.
@immutable
final class CoreDragPending extends CoreDragState {
  /// Creates the pending state.
  const CoreDragPending({
    required this.pendingId,
    required this.origin,
    required this.inputKind,
  });

  /// The item that would be dragged.
  final CoreDragId pendingId;

  /// Where the pointer went down.
  final CoreDragPoint origin;

  /// What is holding the pointer.
  final CoreDragInputKind inputKind;

  @override
  bool operator ==(Object other) =>
      other is CoreDragPending &&
      other.pendingId == pendingId &&
      other.origin == origin &&
      other.inputKind == inputKind;

  @override
  int get hashCode =>
      Object.hash(CoreDragPending, pendingId, origin, inputKind);

  @override
  String toString() =>
      'CoreDragPending(pendingId: $pendingId, origin: $origin, '
      'inputKind: $inputKind)';
}

/// A drag session is live.
@immutable
final class CoreDragging extends CoreDragState {
  /// Creates the dragging state.
  const CoreDragging({required this.session, this.overId});

  /// The live session.
  final CoreDragSession session;

  /// The drop zone currently under the drag, when one is.
  final CoreDragId? overId;

  @override
  CoreDragId get activeId => session.activeId;

  @override
  bool operator ==(Object other) =>
      other is CoreDragging &&
      other.session == session &&
      other.overId == overId;

  @override
  int get hashCode => Object.hash(CoreDragging, session, overId);

  @override
  String toString() => 'CoreDragging(session: $session, overId: $overId)';
}
