/// Platform-independent contract for the draggable item component.
///
/// `DragItem` marks a subtree as grabbable inside the nearest `DragScope`.
/// The engine reports drag intent through the lifecycle callbacks;
/// applications own their data and update their own state in response.
library;

import 'package:coui_core/src/drag/core_drag_activation.dart';
import 'package:coui_core/src/drag/core_drag_event.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';

/// Contract for a draggable item inside a `DragScope`.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreDragItemContract<W> {
  /// Keyboard drag movement per arrow-key press, in logical pixels.
  ///
  /// Shared behaviour default for both platform widgets (single source).
  static const double defaultKeyboardDragStep = 25;

  /// Whether an item takes keyboard focus and walks its own keyboard drag
  /// unless told otherwise.
  ///
  /// Shared behaviour default for both platform widgets (single source).
  static const bool defaultKeyboardDraggable = true;

  /// Default pointer activation constraint (no distance / delay required).
  ///
  /// Shared behaviour default for both platform widgets (single source).
  static const CoreDragActivationConstraint defaultActivationConstraint =
      .immediate;

  /// The stable identity of this item within its `DragScope`.
  CoreDragId get id;

  /// The visual content of the draggable item.
  W get child;

  /// Whether this item can be dragged.
  ///
  /// `null` resolves to `true` — items are draggable unless explicitly
  /// disabled.
  bool? get enabled;

  /// Optional application-owned data carried with the drag session.
  Object? get data;

  /// Pointer activation constraint applied before a drag session starts.
  CoreDragActivationConstraint get activationConstraint;

  /// Keyboard drag movement per arrow-key press, in logical pixels.
  double get keyboardDragStep;

  /// Whether the item itself takes keyboard focus and runs a keyboard drag.
  ///
  /// Off when a consumer puts its own keyboard affordance on a descendant —
  /// a sortable list steps its handle one slot per key, and a second tab
  /// stop on the row walking in pixels would be two controls for one job.
  /// Pointer dragging is unaffected.
  bool get keyboardDraggable;

  /// Accessibility label announced for this item.
  String? get label;

  /// Accessibility hint describing how to interact with this item.
  String? get hint;

  /// Callback when a drag session starts on this item.
  CoreDragStartCallback? get onDragStart;

  /// Callback while this item's drag session moves.
  CoreDragMoveCallback? get onDragMove;

  /// Callback when this item's drag session ends.
  CoreDragEndCallback? get onDragEnd;

  /// Callback when this item's drag session is cancelled.
  CoreDragCancelCallback? get onDragCancel;
}
