/// Platform-independent contract for the drag-and-drop scope component.
///
/// `DragScope` is the ambient entry point of the CoUI drag engine: one
/// `DragScope` hosts a single [CoreDragRuntime] shared by every `DragItem`
/// and `DropZone` in its subtree. The runtime is pure Dart — activation,
/// collision and session bookkeeping live in `coui_core`, and each platform
/// adapter only supplies input and measurement, so Flutter and Web run one
/// implementation of what a drag *means*.
library;

import 'package:coui_core/src/drag/core_drag_runtime.dart';

/// Contract for the drag-and-drop scope component.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
///
/// Implementations wrap [child] with one shared drag runtime. Both platform
/// widgets additionally expose a `controller` parameter typed as their
/// adapter's runtime controller — a framework-runtime type (like Flutter
/// `FocusNode` / Web DOM ids) that is intentionally outside this contract
/// while the capability itself exists symmetrically on both platforms.
abstract interface class CoreDragScopeContract<W> {
  /// The subtree in which drag-and-drop is enabled.
  W get child;
}
