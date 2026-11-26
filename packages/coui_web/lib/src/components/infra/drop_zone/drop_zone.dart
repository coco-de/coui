import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_dom.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Builder signature for drag-over-aware `DropZone` rendering.
///
/// Receives the zone's live drag-over details from the engine
/// (`details.isOver`, `details.activeId`, `details.session`) and the zone's
/// [DropZone.child] to wrap.
typedef DropZoneBuilder =
    Component Function(
      BuildContext context,
      CoreDropZoneDetails details,
      Component child,
    );

/// Per-instance suffix for drop zone element ids.
int _dropZoneSeq = 0;

/// A drop target inside the nearest `DragScope`.
///
/// `DropZone` registers [child] as a landing area. Drop intent is reported
/// through the dragged `DragItem`'s lifecycle callbacks (its end event
/// carries the hovered zone id), while [builder] enables drag-over-aware
/// rendering of the zone itself.
///
/// The Flutter `DropZone` exposes the identical named-properties API, so
/// cross-platform call sites look the same.
///
/// ```dart
/// DropZone(
///   id: CoreDragId('bin'),
///   builder: (context, details, child) => div(
///     [child],
///     classes: details.isOver ? 'opacity-100' : 'opacity-60',
///   ),
///   child: Icon(...),
/// )
/// ```
class DropZone extends StatefulComponent
    implements CoreDropZoneContract<Component, DropZoneBuilder> {
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
  final Component child;

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
  late final String _elementId = 'coui-drop-zone-${_dropZoneSeq++}';

  DragScopeController? _scope;
  void Function()? _stopLayoutObserver;

  bool get _enabled => component.enabled ?? true;

  /// A disabled zone deregisters rather than lingering unmeasured.
  ///
  /// The engine resolves collisions purely from what the registry holds, so
  /// dropping the registration is the whole of "this zone stops accepting".
  void _syncRegistration() {
    final scope = _scope;
    if (scope == null) return;

    if (!_enabled) {
      scope.registry.unregisterDropZone(component.id);
      _stopLayoutObserver?.call();
      _stopLayoutObserver = null;

      return;
    }

    scope.registry.registerDropZone(
      component.id,
      data: component.data,
      owner: this,
    );
    _handleMeasure();
    _stopLayoutObserver ??= observeLayoutChanges(_elementId, _handleMeasure);
  }

  void _handleMeasure() => _scope?.measureDropZone(component.id, _elementId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DragScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _scope?.registry.unregisterDropZone(component.id);
      _scope = scope;
    }
    _syncRegistration();
  }

  @override
  void dispose() {
    _stopLayoutObserver?.call();
    _scope?.registry.unregisterDropZone(component.id);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final scope = DragScope.maybeOf(context);
    final details = _enabled
        ? (scope?.detailsForZone(component.id) ?? .idle)
        : CoreDropZoneDetails.idle;

    final builder = component.builder;
    final content = builder == null
        ? component.child
        : builder(context, details, component.child);

    return div(
      [content],
      id: _elementId,
      attributes: {
        'aria-dropeffect': details.isOver ? 'move' : 'none',
        if (!_enabled) 'aria-disabled': 'true',
      },
    );
  }
}
