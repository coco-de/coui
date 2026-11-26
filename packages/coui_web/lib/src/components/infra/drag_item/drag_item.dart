import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_dom.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Per-instance suffix for drag element ids.
int _dragItemSeq = 0;

/// A draggable item inside the nearest `DragScope`.
///
/// `DragItem` marks [child] as grabbable. The engine reports drag intent
/// through the lifecycle callbacks — applications own their data and update
/// their own state in response (for example on [onDragEnd], whose event
/// carries the hovered `DropZone` id).
///
/// Grabbing the whole item is the default; wrap a descendant in a
/// [DragHandle] to narrow the grab surface to that descendant instead.
///
/// The item deliberately does not move itself: consumers already position
/// from the same session, so translating here too would apply that
/// movement twice. Read `DragScope.maybeOf(context)!.transformOf(id)` to
/// follow the pointer.
///
/// The Flutter `DragItem` exposes the identical named-properties API, so
/// cross-platform call sites look the same.
///
/// ```dart
/// DragItem(
///   id: CoreDragId('card-1'),
///   onDragEnd: (event) => handleDrop(event),
///   child: Card(...),
/// )
/// ```
class DragItem extends StatefulComponent
    implements CoreDragItemContract<Component> {
  /// Creates a [DragItem].
  const DragItem({
    required this.id,
    required this.child,
    this.enabled,
    this.data,
    this.activationConstraint =
        CoreDragItemContract.defaultActivationConstraint,
    this.keyboardDragStep = CoreDragItemContract.defaultKeyboardDragStep,
    this.keyboardDraggable = CoreDragItemContract.defaultKeyboardDraggable,
    this.label,
    this.hint,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
    super.key,
  });

  @override
  final CoreDragId id;

  @override
  final Component child;

  @override
  final bool? enabled;

  @override
  final Object? data;

  @override
  final CoreDragActivationConstraint activationConstraint;

  @override
  final double keyboardDragStep;

  @override
  final bool keyboardDraggable;

  @override
  final String? label;

  @override
  final String? hint;

  @override
  final CoreDragStartCallback? onDragStart;

  @override
  final CoreDragMoveCallback? onDragMove;

  @override
  final CoreDragEndCallback? onDragEnd;

  @override
  final CoreDragCancelCallback? onDragCancel;

  @override
  State<DragItem> createState() => _DragItemState();
}

class _DragItemState extends State<DragItem> {
  late final String _elementId = 'coui-drag-item-${_dragItemSeq++}';

  /// Ids of registered [DragHandle] elements — copy-on-write so reads
  /// never observe a half-mutated set.
  Set<String> _handleIds = const <String>{};
  DragScopeController? _scope;
  void Function()? _stopPointerStream;
  void Function()? _stopLayoutObserver;

  Stopwatch? _sincePointerDown;

  /// Where a keyboard drag has walked to, in scope coordinates.
  CoreDragPoint? _keyboardPointer;

  bool get _enabled => component.enabled ?? true;

  void _register() {
    _scope?.registerItem(
      component.id,
      owner: this,
      data: component.data,
      callbacks: DragItemCallbacks(
        onDragStart: component.onDragStart,
        onDragMove: component.onDragMove,
        onDragEnd: component.onDragEnd,
        onDragCancel: component.onDragCancel,
      ),
    );
    _handleMeasure();
    _stopLayoutObserver ??= observeLayoutChanges(_elementId, _handleMeasure);
  }

  void _handleMeasure() => _scope?.measureItem(component.id, _elementId);

  // ─── pointer input ────────────────────────────────────────────────────

  /// Starts a session and streams the rest of the drag from the document.
  ///
  /// The pointer stream lives on the document rather than on a captured
  /// element: `setPointerCapture` retargets the closing `pointerup` and
  /// `click` to the capturing element, which silently breaks any handler
  /// an ancestor installed — a tap straight after a drag then does nothing.
  void _handlePointerDown(web.PointerEvent event, web.HTMLElement _) {
    final scope = _scope;
    if (!_enabled || scope == null) return;
    if (!_grabAllowedAt(event)) return;

    // A fresh measurement at grab time beats a cached one: the page may
    // have scrolled or reflowed since the last observer callback.
    _handleMeasure();

    final sinceDown = Stopwatch()..start();
    _sincePointerDown = sinceDown;
    scope.runtime.pointerDown(
      component.id,
      position: scope.toScopePoint(viewportPointOf(event)),
      constraint: component.activationConstraint,
    );

    _stopPointerStream?.call();
    _stopPointerStream = registerDragPointerListeners(
      onMove: (position) => scope.runtime.pointerMove(
        scope.toScopePoint(position),
        elapsed: sinceDown.elapsed,
      ),
      onUp: () {
        _endPointerStream();
        scope.runtime.pointerUp();
      },
      onCancel: () {
        _endPointerStream();
        scope.runtime.cancel();
      },
    );
  }

  void _endPointerStream() {
    _sincePointerDown?.stop();
    _sincePointerDown = null;
    _stopPointerStream?.call();
    _stopPointerStream = null;
  }

  /// Whether a pointer landing on this event's target may start a drag.
  ///
  /// With no [DragHandle] the whole item grabs. With one, the pointer must
  /// have landed inside a handle element — resolved from the event's own
  /// target so a handle rendered anywhere in the subtree still narrows the
  /// grab surface.
  bool _grabAllowedAt(web.PointerEvent event) {
    final handleIds = _handleIds;
    if (handleIds.isEmpty) return true;

    if (event.target case final web.Element target) {
      for (final handleId in handleIds) {
        final handle = web.document.getElementById(handleId);
        if (handle != null && handle.contains(target)) return true;
      }
    }

    return false;
  }

  // ─── keyboard input ───────────────────────────────────────────────────

  /// Picks up, walks, drops and cancels a drag from the keyboard.
  ///
  /// The engine has no notion of a pointer device, so a keyboard drag is
  /// just a session whose "pointer" this walks in [DragItem.keyboardDragStep]
  /// increments — collision and drop resolve exactly as for a mouse.
  void _handleKeyDown(web.KeyboardEvent event) {
    final scope = _scope;
    if (!_enabled || !component.keyboardDraggable || scope == null) return;

    final runtime = scope.runtime;
    final dragging = runtime.activeId == component.id;
    final key = event.key;

    if (key == ' ' || key == 'Enter') {
      event.preventDefault();
      if (dragging) {
        runtime.pointerUp();
        _keyboardPointer = null;

        return;
      }
      _startKeyboardDrag(scope);

      return;
    }

    if (!dragging) return;

    if (key == 'Escape') {
      event.preventDefault();
      runtime.cancel(reason: .dismissed);
      _keyboardPointer = null;

      return;
    }

    final step = _keyboardStepFor(key);
    if (step == null) return;

    event.preventDefault();
    final next = (_keyboardPointer ?? runtime.session!.pointer).translate(
      step.x,
      step.y,
    );
    _keyboardPointer = next;
    runtime.pointerMove(next);
  }

  void _startKeyboardDrag(DragScopeController scope) {
    _handleMeasure();
    final rect = scope.registry.itemRects[component.id];
    if (rect == null) return;

    final origin = rect.center;
    _keyboardPointer = origin;
    scope.runtime
      ..pointerDown(
        component.id,
        position: origin,
        inputKind: .keyboard,
      )
      ..pointerMove(origin);
  }

  CoreDragOffset? _keyboardStepFor(String key) {
    final step = component.keyboardDragStep;

    return switch (key) {
      'ArrowLeft' => CoreDragOffset(x: -step),
      'ArrowRight' => CoreDragOffset(x: step),
      'ArrowUp' => CoreDragOffset(y: -step),
      'ArrowDown' => CoreDragOffset(y: step),
      _ => null,
    };
  }

  // ─── handle registration ──────────────────────────────────────────────

  /// Claims the grab surface for a descendant [DragHandle]'s element.
  void handleHandleRegistered(String elementId) {
    _handleIds = {..._handleIds, elementId};
  }

  /// Releases a previously claimed grab surface.
  void handleHandleUnregistered(String elementId) {
    _handleIds = {
      for (final id in _handleIds)
        if (id != elementId) id,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DragScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _scope?.unregisterItem(component.id, owner: this);
      _scope = scope;
    }
    _register();
  }

  @override
  void dispose() {
    _stopPointerStream?.call();
    _stopLayoutObserver?.call();
    _scope?.unregisterItem(component.id, owner: this);
    super.dispose();
  }

  // ─── render ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    final dragging = DragScope.maybeOf(context)?.activeId == component.id;

    return DragHandleRegistrar(
      register: handleHandleRegistered,
      unregister: handleHandleUnregistered,
      child: div(
        [component.child],
        id: _elementId,
        // The Flutter twin adds no geometry — it hands its constraints to
        // the child — so the wrapper is a transparent grid rather than a
        // plain block (which would leave a child of a fixed-height parent at
        // its own height and give an inline child a line box).
        classes: _enabled && _handleIds.isEmpty
            ? '${WebLayout.gridTransparent} cursor-grab'
            : WebLayout.gridTransparent,
        attributes: {
          'aria-label': ?component.label,
          'aria-description': ?component.hint,
          // A consumer that owns the keyboard path on a descendant (a
          // sortable handle) gets a plain wrapper: no tab stop, and no
          // `application` role that would take browse mode away from the
          // row's own content.
          if (component.keyboardDraggable) ...{
            'aria-grabbed': '$dragging',
            'aria-disabled': '${!_enabled}',
            // `role="application"` is earned here, not assumed: once a drag
            // starts, `_handleKeyDown` above intercepts Space/Enter
            // (grab/release), Escape (cancel) and all four arrow keys (move
            // the dragged item one `keyboardDragStep` at a time). Without
            // this role, a screen reader's browse-mode virtual cursor would
            // consume those arrow keys as "move focus" instead of forwarding
            // them here, and keyboard drag-and-drop would silently not work.
            'role': 'application',
            'tabindex': _enabled ? '0' : '-1',
          },
        },
        events: _enabled
            ? {
                'pointerdown':
                    EventHandlers.createPointerCurrentTargetEventHandler(
                      _handlePointerDown,
                    ),
                if (component.keyboardDraggable)
                  'keydown': EventHandlers.createKeyboardEventHandler(
                    _handleKeyDown,
                  ),
              }
            : const {},
      ),
    );
  }
}

/// Lets a [DragHandle] tell its enclosing [DragItem] that it exists.
@immutable
class DragHandleRegistrar extends InheritedComponent {
  /// Creates a handle registrar.
  const DragHandleRegistrar({
    required this.register,
    required this.unregister,
    required super.child,
    super.key,
  });

  /// Claims the grab surface for the element with the given id.
  final void Function(String elementId) register;

  /// Releases a previously claimed grab surface.
  final void Function(String elementId) unregister;

  @override
  bool updateShouldNotify(DragHandleRegistrar oldComponent) => false;
}

/// Per-instance suffix for handle element ids.
int _dragHandleSeq = 0;

/// Narrows the grab surface of the enclosing [DragItem] to [child].
///
/// Without a handle the whole item is grabbable. With one, a pointer must
/// land inside a handle to start a drag — which is what lets a sortable row
/// stay selectable and its buttons stay clickable while still reordering.
class DragHandle extends StatefulComponent {
  /// Creates a [DragHandle].
  const DragHandle({required this.child, super.key});

  /// The grab affordance.
  final Component child;

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle> {
  late final String _elementId = 'coui-drag-handle-${_dragHandleSeq++}';

  DragHandleRegistrar? _registrar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registrar = context
        .dependOnInheritedComponentOfExactType<DragHandleRegistrar>();
    if (identical(registrar, _registrar)) return;

    _registrar?.unregister(_elementId);
    _registrar = registrar;
    registrar?.register(_elementId);
  }

  @override
  void dispose() {
    _registrar?.unregister(_elementId);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // The Flutter twin wraps in a `MouseRegion`, which adds no geometry of
    // its own. A bare `<div>` is not that: it inherits the row's
    // line-height, opens a line box, and parks an inline-level child on the
    // baseline — leaving a 16px icon sitting above the centre of the row it
    // belongs to. Centring here is what makes the wrapper size to its child
    // the way the Flutter one does.
    //
    // The alignment holds whether or not a registrar is present: the
    // wrapper renders either way, so making it conditional would leave the
    // other path quietly misaligned.
    return div(
      [component.child],
      id: _elementId,
      classes: _registrar == null
          ? WebLayout.inlineFlexItemsCenter
          : '${WebLayout.inlineFlexItemsCenter} cursor-grab',
    );
  }
}
