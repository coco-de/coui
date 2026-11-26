import 'package:coui_flutter/coui_flutter.dart';

/// Builder signature for drag-over-aware [DropZone] rendering.
///
/// Receives the zone's live drag-over details from the engine
/// (`details.isOver`, `details.activeId`, `details.session`) and the zone's
/// [DropZone.child] to wrap.
typedef DropZoneBuilder =
    Widget Function(
      BuildContext context,
      CoreDropZoneDetails details,
      Widget child,
    );

/// A drop target inside the nearest [DragScope].
///
/// `DropZone` registers [child] as a landing area. Drop intent is reported
/// through the dragged [DragItem]'s lifecycle callbacks (its end event
/// carries the hovered zone id), while [builder] enables drag-over-aware
/// rendering of the zone itself.
///
/// The Web `DropZone` exposes the identical named-properties API, so
/// cross-platform call sites look the same.
///
/// ```dart
/// DropZone(
///   id: CoreDragId('bin'),
///   builder: (context, details, child) => Opacity(
///     opacity: details.isOver ? 1 : 0.6,
///     child: child,
///   ),
///   child: Icon(...),
/// )
/// ```
class DropZone extends StatefulWidget
    implements CoreDropZoneContract<Widget, DropZoneBuilder> {
  /// Creates a [DropZone].
  const DropZone({
    required this.id,
    required this.child,
    this.builder,
    this.enabled,
    this.data,
    super.key,
  });

  @override
  final CoreDragId id;

  @override
  final Widget child;

  @override
  final DropZoneBuilder? builder;

  @override
  final bool? enabled;

  @override
  final Object? data;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  final GlobalKey _boxKey = GlobalKey();

  DragScopeController? _scope;

  bool get _enabled => widget.enabled ?? true;

  /// A disabled zone deregisters rather than lingering unmeasured.
  ///
  /// The engine resolves collisions purely from what the registry holds, so
  /// dropping the registration is the whole of "this zone stops accepting".
  void _syncRegistration() {
    final scope = _scope;
    if (scope == null) return;

    if (!_enabled) {
      scope.registry.unregisterDropZone(widget.id);

      return;
    }

    scope.registry.registerDropZone(widget.id, data: widget.data, owner: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final scope = _scope;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = DragScope.renderBoxOf(context);
    if (scope == null || box == null || origin == null) return;
    if (!box.hasSize || !origin.hasSize) return;

    final topLeft = box.localToGlobal(.zero, ancestor: origin);
    scope.registry.measureDropZone(
      widget.id,
      CoreDragRect(
        left: topLeft.dx,
        top: topLeft.dy,
        width: box.size.width,
        height: box.size.height,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DragScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _scope?.registry.unregisterDropZone(widget.id);
      _scope = scope;
    }
    _syncRegistration();
  }

  @override
  void didUpdateWidget(DropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _scope?.registry.unregisterDropZone(oldWidget.id);
    }
    _syncRegistration();
  }

  @override
  void dispose() {
    _scope?.registry.unregisterDropZone(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = DragScope.maybeOf(context);
    final details = _enabled
        ? (scope?.detailsForZone(widget.id) ?? .idle)
        : CoreDropZoneDetails.idle;
    if (_enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }

    final builder = widget.builder;

    // Web twin exposes aria-disabled / aria-dropeffect on the drop target.
    return Semantics(
      container: true,
      child: KeyedSubtree(
        key: _boxKey,
        child: builder == null
            ? widget.child
            : builder(context, details, widget.child),
      ),
    );
  }
}
