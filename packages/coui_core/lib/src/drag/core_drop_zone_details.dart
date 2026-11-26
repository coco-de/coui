import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:coui_core/src/drag/core_drag_state.dart';
import 'package:meta/meta.dart';

/// What a drop zone knows about the drag currently passing over it.
///
/// Shared by both adapters even though the builder that consumes it is
/// platform-typed: `isOver` has to mean the same thing on Flutter and Web,
/// and it only does if one type defines it.
@immutable
class CoreDropZoneDetails {
  /// Creates drop zone details.
  const CoreDropZoneDetails({this.session, this.isOver = false});

  /// Nothing is being dragged.
  static const CoreDropZoneDetails idle = CoreDropZoneDetails();

  /// The live drag session, when one exists.
  final CoreDragSession? session;

  /// Whether the live drag currently resolves to this zone.
  final bool isOver;

  /// The item being dragged, when one is.
  CoreDragId? get activeId => session?.activeId;

  @override
  bool operator ==(Object other) =>
      other is CoreDropZoneDetails &&
      other.session == session &&
      other.isOver == isOver;

  @override
  int get hashCode => Object.hash(CoreDropZoneDetails, session, isOver);

  @override
  String toString() =>
      'CoreDropZoneDetails(session: $session, isOver: $isOver)';
}
