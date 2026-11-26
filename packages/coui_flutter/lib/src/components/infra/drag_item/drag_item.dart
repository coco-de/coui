import 'package:coui_flutter/coui_flutter.dart';
// `Drag` and the key-event types sit outside the barrel's curated
// re-export surface, so this adapter imports them directly.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// A draggable item inside the nearest [DragScope].
///
/// `DragItem` marks [child] as grabbable. The engine reports drag intent
/// through the lifecycle callbacks — applications own their data and update
/// their own state in response (for example on [onDragEnd], whose event
/// carries the hovered [DropZone] id).
///
/// Grabbing the whole item is the default; wrap a descendant in a
/// [DragHandle] to narrow the grab surface to that descendant instead.
///
/// The Web `DragItem` exposes the identical named-properties API, so
/// cross-platform call sites look the same.
///
/// ```dart
/// DragItem(
///   id: CoreDragId('card-1'),
///   onDragEnd: (event) => handleDrop(event),
///   child: Card(...),
/// )
/// ```
class DragItem extends StatefulWidget implements CoreDragItemContract<Widget> {
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
  final Widget child;

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
  final GlobalKey _boxKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'DragItem');

  /// Handles that have claimed the grab surface, if any. Rebuilt (never
  /// mutated in place) on every register / unregister.
  Set<BuildContext> _handles = const <BuildContext>{};

  final Stopwatch _sincePointerDown = Stopwatch();
  DragScopeController? _scope;

  /// Owned delayed press-and-hold recognizer — created lazily on first
  /// pointer down, replaced when the configured delay changes, disposed
  /// with this state. Owning it here (and feeding it pointers through a
  /// [Listener]) keeps its lifecycle out of [RawGestureDetector], which
  /// disposes whatever recognizers it creates itself.
  DelayedMultiDragGestureRecognizer? _delayedRecognizer;

  void handleRegisterHandle(BuildContext handle) {
    _handles = {..._handles, handle};
  }

  void handleUnregisterHandle(BuildContext handle) {
    _handles = _handles.difference({handle});
  }

  /// Where a keyboard drag has walked to, in scope coordinates.
  CoreDragPoint? _keyboardPointer;

  bool get _enabled => widget.enabled ?? true;

  void _register() => _scope?.registerItem(
    widget.id,
    owner: this,
    data: widget.data,
    callbacks: DragItemCallbacks(
      onDragStart: widget.onDragStart,
      onDragMove: widget.onDragMove,
      onDragEnd: widget.onDragEnd,
      onDragCancel: widget.onDragCancel,
    ),
  );

  // ─── measurement ──────────────────────────────────────────────────────

  void _scheduleMeasure() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  /// Records this item's rect in scope coordinates.
  ///
  /// Skipped while this item is the one being dragged: its cached rect is
  /// what the engine compares against, so re-measuring mid-drag would chase
  /// the item's own movement.
  void _measure() {
    if (!mounted) return;
    final scope = _scope;
    if (scope == null || scope.activeId == widget.id) return;

    final rect = _measureRect();
    if (rect == null) return;

    scope.registry.measureItem(widget.id, rect);
  }

  CoreDragRect? _measureRect() {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = DragScope.renderBoxOf(context);
    if (box == null || origin == null || !box.hasSize || !origin.hasSize) {
      return null;
    }

    final topLeft = box.localToGlobal(.zero, ancestor: origin);

    return CoreDragRect(
      left: topLeft.dx,
      top: topLeft.dy,
      width: box.size.width,
      height: box.size.height,
    );
  }

  CoreDragPoint _scopePoint(Offset globalPosition) {
    final origin = DragScope.renderBoxOf(context);
    final local = origin?.globalToLocal(globalPosition) ?? globalPosition;

    return CoreDragPoint(local.dx, local.dy);
  }

  // ─── pointer input ────────────────────────────────────────────────────

  /// Whether a pointer landing at [globalPosition] may start a drag.
  ///
  /// With no [DragHandle] the whole item grabs. With one or more, only they
  /// do — asking at pointer-down rather than at build time is what lets a
  /// handle mounted *below* this widget still narrow the grab surface on
  /// the very first frame.
  bool _grabAllowedAt(Offset globalPosition) {
    if (!_enabled || _scope == null) return false;
    if (_handles.isEmpty) return true;

    for (final handle in _handles) {
      final box = handle.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if (box.paintBounds.contains(box.globalToLocal(globalPosition))) {
        return true;
      }
    }

    return false;
  }

  void _handleDragDown(DragDownDetails details) {
    if (!_grabAllowedAt(details.globalPosition)) return;

    _sincePointerDown
      ..reset()
      ..start();
    _scope?.runtime.pointerDown(
      widget.id,
      position: _scopePoint(details.globalPosition),
      constraint: widget.activationConstraint,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) =>
      _scope?.runtime.pointerMove(
        _scopePoint(details.globalPosition),
        elapsed: _sincePointerDown.elapsed,
      );

  void _handleDragEnd(DragEndDetails details) {
    _sincePointerDown.stop();
    _scope?.runtime.pointerUp();
  }

  void _handleDragCancel() {
    _sincePointerDown.stop();
    _scope?.runtime.cancel();
  }

  /// Whether the activation constraint asks for a press-and-hold grab.
  bool get _usesDelayedGrab => widget.activationConstraint.delay > .zero;

  /// Routes a pointer into the owned delayed recognizer.
  ///
  /// Delegating the hold to Flutter's own delayed recognizer is what keeps
  /// an enclosing scrollable usable: until the hold completes the drag has
  /// not entered the gesture arena, so a quick swipe still scrolls.
  void _handleDelayedPointerDown(PointerDownEvent event) {
    final recognizer = _delayedRecognizer ??= DelayedMultiDragGestureRecognizer(
      delay: widget.activationConstraint.delay,
    );
    recognizer
      ..onStart = _startDelayedDrag
      ..addPointer(event);
  }

  /// A press-and-hold grab, for constraints that ask for a delay.
  Drag? _startDelayedDrag(Offset globalPosition) {
    if (!_grabAllowedAt(globalPosition)) return null;

    final runtime = _scope?.runtime;
    if (runtime == null) return null;

    final origin = _scopePoint(globalPosition);
    _sincePointerDown
      ..reset()
      ..start();
    runtime
      ..pointerDown(
        widget.id,
        position: origin,
        inputKind: .touch,
        constraint: widget.activationConstraint,
      )
      // The hold already satisfied the delay, so hand the engine the same
      // point back to promote the session without waiting for movement.
      ..pointerMove(origin, elapsed: widget.activationConstraint.delay);

    return _DragItemDrag(
      onUpdate: (details) => runtime.pointerMove(
        _scopePoint(details.globalPosition),
        elapsed: _sincePointerDown.elapsed,
      ),
      onEnd: (_) {
        _sincePointerDown.stop();
        runtime.pointerUp();
      },
      onCancel: () {
        _sincePointerDown.stop();
        runtime.cancel();
      },
    );
  }

  /// Every pointer kind that drags by pressing and moving — all but
  /// [PointerDeviceKind.trackpad].
  ///
  /// A trackpad reports only its two-finger scroll, pan and pinch under that
  /// kind (`PointerPanZoom*` events); its clicks and click-drags arrive as a
  /// mouse. Left in, a scroll over this item that the enclosing list could
  /// not claim first — content shorter than the viewport, or a swipe drifting
  /// sideways past the pan slop before the list's vertical slop — grabbed the
  /// item, and lifting the fingers dropped it. Flutter's own `Draggable`
  /// ignores those gestures, and the Web twin never sees them as pointers
  /// (they are `wheel` events).
  static final Set<PointerDeviceKind> _dragDevices = {
    for (final kind in PointerDeviceKind.values)
      if (kind != PointerDeviceKind.trackpad) kind,
  };

  Map<Type, GestureRecognizerFactory> _panGestures() {
    return {
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(supportedDevices: _dragDevices),
            (instance) => instance
              ..onDown = _handleDragDown
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel,
          ),
    };
  }

  // ─── keyboard input ───────────────────────────────────────────────────

  /// Picks up, walks, drops and cancels a drag from the keyboard.
  ///
  /// The engine has no notion of a pointer device, so a keyboard drag is
  /// just a session whose "pointer" this method walks in [keyboardDragStep]
  /// increments — collision and drop resolve exactly as they do for a mouse.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final runtime = _scope?.runtime;
    if (runtime == null ||
        !_enabled ||
        !widget.keyboardDraggable ||
        event is KeyUpEvent) {
      return .ignored;
    }

    final dragging = runtime.activeId == widget.id;
    final key = event.logicalKey;

    if (key == .space || key == .enter) {
      if (dragging) {
        runtime.pointerUp();
        _keyboardPointer = null;
      } else {
        if (!_startKeyboardDrag(runtime)) return .ignored;
      }

      return .handled;
    }

    if (!dragging) return .ignored;

    if (key == .escape) {
      runtime.cancel(reason: .dismissed);
      _keyboardPointer = null;

      return .handled;
    }

    final step = _keyboardStepFor(key);
    if (step == null) return .ignored;

    final next = (_keyboardPointer ?? runtime.session!.pointer).translate(
      step.x,
      step.y,
    );
    _keyboardPointer = next;
    runtime.pointerMove(next);

    return .handled;
  }

  bool _startKeyboardDrag(CoreDragRuntime runtime) {
    final rect = runtime.registry.itemRects[widget.id] ?? _measureRect();
    if (rect == null) return false;

    final origin = rect.center;
    _keyboardPointer = origin;
    runtime
      ..pointerDown(
        widget.id,
        position: origin,
        inputKind: .keyboard,
        constraint: .immediate,
      )
      ..pointerMove(origin);

    return true;
  }

  CoreDragOffset? _keyboardStepFor(LogicalKeyboardKey key) {
    final step = widget.keyboardDragStep;

    return switch (key) {
      .arrowLeft => CoreDragOffset(x: -step),
      .arrowRight => CoreDragOffset(x: step),
      .arrowUp => CoreDragOffset(y: -step),
      .arrowDown => CoreDragOffset(y: step),
      _ => null,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DragScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _scope?.unregisterItem(widget.id, owner: this);
      _scope = scope;
    }
    _register();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(DragItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _scope?.unregisterItem(oldWidget.id, owner: this);
    }
    if (oldWidget.activationConstraint.delay !=
        widget.activationConstraint.delay) {
      // The delay is baked into the recognizer at construction — drop the
      // stale one so the next pointer down picks up the new constraint.
      _delayedRecognizer?.dispose();
      _delayedRecognizer = null;
    }
    _register();
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _scope?.unregisterItem(widget.id, owner: this);
    _delayedRecognizer?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── render ───────────────────────────────────────────────────────────

  /// Renders [child] untransformed and reports movement instead.
  ///
  /// The item deliberately does not move itself: consumers already position
  /// from the same session (a panel sets its own offset, a sortable row
  /// shifts along its computed displacement), so translating here too would
  /// apply that movement twice. Read `DragScope.maybeOf(context)
  /// .transformOf(id)` to follow the pointer.
  @override
  Widget build(BuildContext context) {
    // Register the scope dependency so a scope swap rebuilds this item —
    // didChangeDependencies already stored this same value, so the
    // assignment only consumes the lookup result.
    _scope = DragScope.maybeOf(context);
    _scheduleMeasure();

    return KeyedSubtree(
      key: _boxKey,
      child: Semantics(
        enabled: _enabled,
        label: widget.label,
        hint: widget.hint,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKey,
          canRequestFocus: _enabled && widget.keyboardDraggable,
          // A consumer that owns the keyboard path on a descendant leaves
          // this item out of the tab order entirely, so the row is not a
          // second stop in front of its own handle.
          skipTraversal: !widget.keyboardDraggable,
          child: _DragItemHandleScope(
            registerHandle: handleRegisterHandle,
            unregisterHandle: handleUnregisterHandle,
            child: MouseRegion(
              cursor: _enabled && _handles.isEmpty
                  ? SystemMouseCursors.grab
                  : .defer,
              child: Listener(
                onPointerDown: _enabled && _usesDelayedGrab
                    ? _handleDelayedPointerDown
                    : null,
                // A cancelled pointer has to abort the session, not
                // complete it. `PanGestureRecognizer` only reaches
                // `onCancel` from its *possible* state — once a drag is
                // live, a `PointerCancelEvent` is routed to `onEnd`
                // instead, so the system taking the pointer away (a nav
                // gesture, the notification shade, the app going to the
                // background, a browser `pointercancel`) committed the
                // reorder the user was in the middle of abandoning.
                //
                // This `Listener` sits on the hit-test path ahead of
                // `GestureBinding`, which is what routes the event to
                // the recognizer, so the runtime is already idle by the
                // time the spurious `onEnd` lands — and `pointerUp` on
                // an idle runtime is a no-op. `onCancel` stays wired: it
                // is still the right handler for a pointer that never
                // became a drag. The delayed-grab path already models
                // this correctly through `Drag.cancel`, so this brings
                // the immediate path in line with it, and with the Web
                // twin, which has listened for `pointercancel` all along.
                onPointerCancel: _enabled
                    ? (_) => _scope?.runtime.cancel()
                    : null,
                child: RawGestureDetector(
                  gestures: _enabled && !_usesDelayedGrab
                      ? _panGestures()
                      : const {},
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A `Drag` that forwards a delayed multi-drag to the engine.
class _DragItemDrag extends Drag {
  _DragItemDrag({
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final void Function(DragUpdateDetails details) onUpdate;
  final void Function(DragEndDetails details) onEnd;
  final void Function() onCancel;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd(details);

  @override
  void cancel() => onCancel();
}

/// Lets a [DragHandle] tell its enclosing [DragItem] that it exists.
class _DragItemHandleScope extends InheritedWidget {
  const _DragItemHandleScope({
    required this.registerHandle,
    required this.unregisterHandle,
    required super.child,
  });

  final void Function(BuildContext handle) registerHandle;
  final void Function(BuildContext handle) unregisterHandle;

  @override
  bool updateShouldNotify(_DragItemHandleScope oldWidget) => false;
}

/// Narrows the grab surface of the enclosing [DragItem] to [child].
///
/// Without a handle the whole item is grabbable. With one, a pointer must
/// land inside a handle to start a drag — which is what lets a sortable row
/// stay selectable and its buttons stay tappable while still reordering.
///
/// ```dart
/// DragItem(
///   id: CoreDragId('row-1'),
///   child: Row(
///     children: [
///       DragHandle(child: Icon(LucideIcons.gripVertical)),
///       Expanded(child: Text('Reorder me')),
///     ],
///   ),
/// )
/// ```
class DragHandle extends StatefulWidget {
  /// Creates a [DragHandle].
  const DragHandle({required this.child, super.key});

  /// The grab affordance.
  final Widget child;

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle> {
  _DragItemHandleScope? _item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final item = context
        .dependOnInheritedWidgetOfExactType<_DragItemHandleScope>();
    if (identical(item, _item)) return;

    _item?.unregisterHandle(context);
    _item = item;
    item?.registerHandle(context);
  }

  @override
  void dispose() {
    _item?.unregisterHandle(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: _item == null ? .defer : SystemMouseCursors.grab,
    child: widget.child,
  );
}
