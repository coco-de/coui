import 'package:coui_flutter/coui_flutter.dart';

/// Builds the floating copy of a live drag.
///
/// Receives the session so the copy can render whatever the application
/// considers "the thing being dragged" — looked up from its own data by
/// `session.activeId`.
typedef DragOverlayBuilder =
    Widget Function(BuildContext context, CoreDragSession session);

/// Paints a copy of the dragged item above everything else.
///
/// A dragged item normally stays in its layout slot, so an ancestor that
/// clips (`ClipRect`, a scroll viewport) cuts it off at the boundary.
/// `DragOverlay` renders the copy in the enclosing [Overlay] instead,
/// which no ancestor of the list can clip.
///
/// It renders nothing while no drag is live, so it costs nothing to leave
/// mounted. Place it anywhere inside the [DragScope] whose drags it should
/// follow.
///
/// The Web `DragOverlay` exposes the identical named-properties API.
///
/// ```dart
/// DragScope(
///   child: Stack(
///     children: [
///       myList,
///       DragOverlay(
///         builder: (context, session) => Card(child: Text('${session.activeId}')),
///       ),
///     ],
///   ),
/// )
/// ```
class DragOverlay extends StatefulWidget
    implements CoreDragOverlayContract<Widget, DragOverlayBuilder> {
  /// Creates a [DragOverlay].
  const DragOverlay({required this.builder, super.key});

  @override
  final DragOverlayBuilder builder;

  @override
  State<DragOverlay> createState() => _DragOverlayState();
}

class _DragOverlayState extends State<DragOverlay> {
  OverlayEntry? _entry;
  DragScopeController? _scope;

  bool _syncScheduled = false;

  /// Defers entry work to after the frame.
  ///
  /// Inserting into or rebuilding an [Overlay] marks it dirty, which is
  /// illegal while the tree is building — and the drag state that triggers
  /// this arrives during exactly that phase.
  void _scheduleSync() {
    if (_syncScheduled) return;

    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _syncEntry();
    });
  }

  /// Mounts the entry exactly while a session is live.
  ///
  /// Inserting into the ambient [Overlay] rather than into this subtree is
  /// the whole point — it also means the list's own widget tree never
  /// changes shape mid-drag, which would remount the `DragItem` and cancel
  /// the very session being drawn.
  void _syncEntry() {
    final live = _scope?.session != null;
    if (live == (_entry != null)) {
      _entry?.markNeedsBuild();

      return;
    }

    if (!live) {
      _entry?.remove();
      _entry = null;

      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(builder: handleOverlayBuild);
    _entry = entry;
    overlay.insert(entry);
  }

  Widget handleOverlayBuild(BuildContext overlayContext) {
    final session = _scope?.session;
    if (session == null) return const SizedBox.shrink();

    final anchor = _anchorOf(session);

    return Position(
      top: anchor.dy,
      left: anchor.dx,
      // The copy is a picture of the drag, not a target for it — letting
      // it swallow pointers would starve the engine of the very moves it
      // is drawing.
      child: IgnorePointer(child: widget.builder(overlayContext, session)),
    );
  }

  /// Where the copy sits in global coordinates.
  ///
  /// The item's measured slot plus how far the drag has travelled: the
  /// session reports movement from the press point, so anchoring at the
  /// slot keeps the copy under the cursor without it jumping on grab.
  Offset _anchorOf(CoreDragSession session) {
    final scopeBox = DragScope.renderBoxOf(context);
    final rect = _scope?.registry.itemRects[session.activeId];
    if (scopeBox == null || rect == null || !scopeBox.hasSize) {
      return .zero;
    }

    final scopeOrigin = scopeBox.localToGlobal(.zero);

    return Offset(
      scopeOrigin.dx + rect.left + session.transform.x,
      scopeOrigin.dy + rect.top + session.transform.y,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = DragScope.maybeOf(context);
    _scheduleSync();
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Depend on the scope so a drag state change rebuilds this, which is
    // what drives the entry in and out — didChangeDependencies already
    // stored this same value, so the assignment only consumes the lookup.
    _scope = DragScope.maybeOf(context);
    _scheduleSync();

    return const SizedBox.shrink();
  }
}
