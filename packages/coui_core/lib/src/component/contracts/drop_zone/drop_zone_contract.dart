/// Platform-independent contract for the drop target component.
///
/// `DropZone` registers a subtree as a landing area inside the nearest
/// `DragScope`. Drop intent is reported through the dragged `DragItem`'s
/// lifecycle callbacks (its end event carries the hovered zone), while the
/// zone itself exposes a `builder` for drag-over-aware rendering.
library;

import 'package:coui_core/src/drag/core_drag_id.dart';

/// Contract for a drop target inside a `DragScope`.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
/// - [ZoneBuilder] - builder function for drag-over-aware rendering
///   (platform-typed, like `CoreSortableContract`'s `ItemBuilder`).
abstract interface class CoreDropZoneContract<W, ZoneBuilder> {
  /// The stable identity of this zone within its `DragScope`.
  CoreDragId get id;

  /// The content users can drop over.
  W get child;

  /// Optional builder for drag-over state-aware rendering.
  ///
  /// When provided, it wraps [child] and receives the zone's live drag-over
  /// details from the engine.
  ZoneBuilder? get builder;

  /// Whether this zone accepts drops.
  ///
  /// `null` resolves to `true` — zones accept drops unless explicitly
  /// disabled.
  bool? get enabled;

  /// Optional application-owned metadata registered with the engine.
  Object? get data;
}
