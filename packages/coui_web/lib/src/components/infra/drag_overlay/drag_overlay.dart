import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Builds the floating copy of a live drag.
///
/// Receives the session so the copy can render whatever the application
/// considers "the thing being dragged" — looked up from its own data by
/// `session.activeId`.
typedef DragOverlayBuilder =
    Component Function(BuildContext context, CoreDragSession session);

/// Paints a copy of the dragged item above everything else.
///
/// A dragged item normally stays in its layout slot, so an ancestor with
/// `overflow: hidden` or a `transform` containing block cuts it off at the
/// boundary. `DragOverlay` renders the copy as a fixed-position layer
/// instead, which no ancestor of the list can clip.
///
/// It renders nothing while no drag is live, so it costs nothing to leave
/// mounted. Place it anywhere inside the `DragScope` whose drags it should
/// follow.
///
/// The Flutter `DragOverlay` exposes the identical named-properties API.
///
/// ```dart
/// DragScope(
///   child: div([
///     myList,
///     DragOverlay(
///       builder: (context, session) =>
///           Card(child: Text(session.activeId.value)),
///     ),
///   ]),
/// )
/// ```
class DragOverlay extends StatefulComponent
    implements CoreDragOverlayContract<Component, DragOverlayBuilder> {
  /// Creates a [DragOverlay].
  const DragOverlay({required this.builder, super.key});

  @override
  final DragOverlayBuilder builder;

  @override
  State<DragOverlay> createState() => _DragOverlayState();
}

class _DragOverlayState extends State<DragOverlay> {
  /// Where the copy sits in viewport coordinates.
  ///
  /// The item's measured slot plus how far the drag has travelled: the
  /// session reports movement from the press point, so anchoring at the
  /// slot keeps the copy under the cursor without it jumping on grab.
  CoreDragPoint _anchorOf(DragScopeController scope, CoreDragSession session) {
    final rect = scope.registry.itemRects[session.activeId];
    if (rect == null) return .zero;

    return scope.toViewportPoint(
      CoreDragPoint(
        rect.left + session.transform.x,
        rect.top + session.transform.y,
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    final scope = DragScope.maybeOf(context);
    final session = scope?.session;
    if (scope == null || session == null) {
      // Nothing is being dragged, so there is nothing to lift. The Flutter
      // twin renders a zero-size box here, and that box is a real child of
      // its parent: a `Column(spacing: …)` or a flex `gap` puts the gap in
      // front of it, and a slot that appears and disappears would shift its
      // siblings. `display: none` takes no part in layout at all, so the
      // placeholder is a 0×0 box instead.
      return const div(
        [],
        styles: Styles(raw: {'width': '0', 'height': '0'}),
      );
    }

    final anchor = _anchorOf(scope, session);

    return div(
      [component.builder(context, session)],
      styles: Styles(
        raw: {
          // Fixed rather than absolute: an ancestor `transform` makes an
          // absolutely-positioned child resolve against *it* rather than
          // the viewport, which is the very clipping this exists to escape.
          'position': 'fixed',
          // Viewport pixels, not rem: the anchor is a measured DOM rect
          // plus the pointer's travel, so it already lives in the same
          // space the cursor does. Scaling it by the root font-size would
          // slide the copy away from the finger holding it.
          'left': '${anchor.x}px', // design-token: viewport-pixel
          'top': '${anchor.y}px', // design-token: viewport-pixel
          'z-index': '${CoreZIndex.z80}',
          // The copy is a picture of the drag, not a target for it —
          // swallowing pointers would starve the engine of the very moves
          // it is drawing.
          'pointer-events': 'none',
        },
      ),
    );
  }
}
