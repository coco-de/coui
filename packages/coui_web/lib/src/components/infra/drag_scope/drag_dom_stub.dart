import 'package:coui_core/coui_core.dart';

/// Server-side no-op: there are no pointer events to read.
CoreDragPoint viewportPointOf(Object event) => .zero;

/// Server-side no-op: there is no document to listen to.
void Function() registerDragPointerListeners({
  required void Function(CoreDragPoint position) onMove,
  required void Function() onUp,
  required void Function() onCancel,
}) => () {};

/// Server-side no-op: nothing has been laid out yet, so nothing measures.
CoreDragRect? measureRectWithin(String elementId, String originId) => null;

/// Server-side no-op: nothing is on screen, so nothing has a viewport rect.
CoreDragRect? measureViewportRect(String elementId) => null;

/// Server-side no-op: nothing scrolls during a render pass.
CoreDragRect? scrollViewportRect(String elementId) => null;

/// Server-side no-op: nothing scrolls during a render pass.
CoreDragOffset scrollContainerBy(String elementId, CoreDragOffset delta) =>
    .zero;

/// Server-side no-op: there are no animation frames.
void Function() registerFrameLoop(void Function(Duration delta) onFrame) =>
    () {};

/// Server-side no-op: layout never changes during a render pass.
void Function()? observeLayoutChanges(
  String elementId,
  void Function() onChange,
) => null;
