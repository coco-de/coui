import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:coui_core/src/drag/core_drag_state.dart';
import 'package:meta/meta.dart';

/// Base type for drag lifecycle events.
///
/// Named for the *lifecycle* rather than plain `CoreDragEvent` because that
/// name already belongs to long-press move details on `Clickable`; the two
/// describe different things and both stay public.
@immutable
sealed class CoreDragLifecycleEvent {
  /// Creates a drag lifecycle event.
  const CoreDragLifecycleEvent({required this.session});

  /// The session this event describes.
  final CoreDragSession session;

  /// The item being dragged.
  CoreDragId get activeId => session.activeId;
}

/// Emitted once, when a session earns activation.
@immutable
final class CoreDragStartEvent extends CoreDragLifecycleEvent {
  /// Creates a drag start event.
  const CoreDragStartEvent({required super.session});

  @override
  bool operator ==(Object other) =>
      other is CoreDragStartEvent && other.session == session;

  @override
  int get hashCode => Object.hash(CoreDragStartEvent, session);

  @override
  String toString() => 'CoreDragStartEvent(session: $session)';
}

/// Emitted on every pointer move of a live session.
@immutable
final class CoreDragMoveEvent extends CoreDragLifecycleEvent {
  /// Creates a drag move event.
  const CoreDragMoveEvent({required super.session, this.overId});

  /// The drop zone currently under the drag.
  final CoreDragId? overId;

  @override
  bool operator ==(Object other) =>
      other is CoreDragMoveEvent &&
      other.session == session &&
      other.overId == overId;

  @override
  int get hashCode => Object.hash(CoreDragMoveEvent, session, overId);

  @override
  String toString() => 'CoreDragMoveEvent(session: $session, overId: $overId)';
}

/// Emitted when the drop zone under the drag changes.
@immutable
final class CoreDragOverEvent extends CoreDragLifecycleEvent {
  /// Creates a drag over event.
  const CoreDragOverEvent({required super.session, this.overId});

  /// The drop zone now under the drag, or `null` when it left one.
  final CoreDragId? overId;

  @override
  bool operator ==(Object other) =>
      other is CoreDragOverEvent &&
      other.session == session &&
      other.overId == overId;

  @override
  int get hashCode => Object.hash(CoreDragOverEvent, session, overId);

  @override
  String toString() => 'CoreDragOverEvent(session: $session, overId: $overId)';
}

/// Emitted when a session is released.
@immutable
final class CoreDragEndEvent extends CoreDragLifecycleEvent {
  /// Creates a drag end event.
  const CoreDragEndEvent({required super.session, this.overId});

  /// The drop zone the drag ended over, when there was one.
  final CoreDragId? overId;

  @override
  bool operator ==(Object other) =>
      other is CoreDragEndEvent &&
      other.session == session &&
      other.overId == overId;

  @override
  int get hashCode => Object.hash(CoreDragEndEvent, session, overId);

  @override
  String toString() => 'CoreDragEndEvent(session: $session, overId: $overId)';
}

/// Emitted when a session ends without a drop.
@immutable
final class CoreDragCancelEvent extends CoreDragLifecycleEvent {
  /// Creates a drag cancel event.
  const CoreDragCancelEvent({required super.session, required this.reason});

  /// Why the session ended.
  final CoreDragCancelReason reason;

  @override
  bool operator ==(Object other) =>
      other is CoreDragCancelEvent &&
      other.session == session &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(CoreDragCancelEvent, session, reason);

  @override
  String toString() =>
      'CoreDragCancelEvent(session: $session, reason: $reason)';
}

/// Called when a drag session starts.
typedef CoreDragStartCallback = void Function(CoreDragStartEvent event);

/// Called on every move of a live drag session.
typedef CoreDragMoveCallback = void Function(CoreDragMoveEvent event);

/// Called when the drop zone under the drag changes.
typedef CoreDragOverCallback = void Function(CoreDragOverEvent event);

/// Called when a drag session is released.
typedef CoreDragEndCallback = void Function(CoreDragEndEvent event);

/// Called when a drag session ends without a drop.
typedef CoreDragCancelCallback = void Function(CoreDragCancelEvent event);
