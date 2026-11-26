import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/drag_item/drag_item.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:coui_web/src/components/layout/draggable_panel/draggable_panel_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart'
    as popover_dom;
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Fraction of the container height used for the handle's initial Y dock.
const double _kInitialYFraction = 0.25;

/// Engine id of the panel handle — one draggable per panel instance, so a
/// constant id is unambiguous inside this panel's own `DragScope`.
const CoreDragId _kHandleDragId = CoreDragId('coui-draggable-panel-handle');

/// The initial Y dock expressed as a CSS percentage (matches
/// [_kInitialYFraction]).
const String _kInitialYPercent = '25%';

/// Monotonic source for per-instance root element ids (container
/// measurement scope).
int _draggablePanelIdCounter = 0;

/// A floating, draggable, edge-docking panel — CoUI's cross-platform
/// equivalent of an Apple PencilKit tool palette.
///
/// [child] is the subtree the panel floats over (typically the whole
/// screen). A draggable handle overlays it; dragging moves it and, on
/// release, it snaps to the nearer container edge. Clicking the handle
/// toggles the expandable [panel] surface. Chrome flows through the
/// single [draggablePanelStyle]; drag behaviour (`dockType` / `enabled` /
/// `closeOnTapOutside` / `dockOffset`) and the optional [controller] stay
/// flat on the widget — identical to the Flutter `DraggablePanel`.
///
/// surface:behind — a panel dragged around over the page, with that page
/// behind it the whole time.
///
/// surface:functional — a panel dragged around over the page, with that
/// page behind it.
class DraggablePanel extends UiStatefulComponent
    implements CoreDraggablePanelContract<Component> {
  /// Creates a [DraggablePanel].
  const DraggablePanel({
    this.child,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.panel,
    this.handle,
    this.dockType = CoreDraggablePanelDockType.defaultDockType,
    this.enabled = CoreDraggablePanelContract.defaultEnabled,
    this.closeOnTapOutside =
        CoreDraggablePanelContract.defaultCloseOnTapOutside,
    this.dockOffset = CoreDraggablePanelContract.defaultDockOffset,
    this.controller,
    this.onPositionChanged,
    this.onOpenChanged,
    this.draggablePanelStyle,
  });

  @override
  final Component? child;

  @override
  final Component? panel;

  @override
  final Component? handle;

  @override
  final CoreDraggablePanelDockType dockType;

  @override
  final bool enabled;

  @override
  final bool closeOnTapOutside;

  @override
  final double dockOffset;

  @override
  final CoreDraggablePanelController? controller;

  @override
  final void Function(double x, double y)? onPositionChanged;

  @override
  final CoreValueChanged<bool>? onOpenChanged;

  @override
  final CoreDraggablePanelStyle? draggablePanelStyle;

  /// Returns a copy of this [DraggablePanel] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  DraggablePanel copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    Component? child,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    Component? panel,
    Component? handle,
    CoreDraggablePanelDockType? dockType,
    bool? enabled,
    bool? closeOnTapOutside,
    double? dockOffset,
    CoreDraggablePanelController? controller,
    void Function(double x, double y)? onPositionChanged,
    CoreValueChanged<bool>? onOpenChanged,
    CoreDraggablePanelStyle? draggablePanelStyle,
  }) {
    return DraggablePanel(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      panel: panel ?? this.panel,
      handle: handle ?? this.handle,
      dockType: dockType ?? this.dockType,
      enabled: enabled ?? this.enabled,
      closeOnTapOutside: closeOnTapOutside ?? this.closeOnTapOutside,
      dockOffset: dockOffset ?? this.dockOffset,
      controller: controller ?? this.controller,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
      onOpenChanged: onOpenChanged ?? this.onOpenChanged,
      draggablePanelStyle: draggablePanelStyle ?? this.draggablePanelStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<DraggablePanel> {
  CoreDraggablePanelController? _ownController;

  /// Root element id — the measurement scope for the container-relative
  /// coordinate frame (the Web analogue of Flutter's `LayoutBuilder`).
  late final String _rootId =
      component.id ?? 'coui-draggable-panel-${_draggablePanelIdCounter++}';

  /// Container (root box) size in CSS px. Measured after the first client
  /// render and kept fresh by a `ResizeObserver`, so drag clamps, edge
  /// snapping and panel placement are all container-relative — not
  /// browser-window-relative (Flutter parity: `LayoutBuilder` constraints).
  ({double width, double height})? _containerSize;

  void Function()? _containerResizeDisposer;

  /// Whether the handle has been placed at an explicit (left/top)
  /// position. Before the first client measurement it docks to the right
  /// edge purely in CSS so SSR needs no viewport measurement.
  bool _positioned = false;

  /// Whether the current pointer interaction moved (drag) vs a plain tap.
  bool _dragged = false;

  /// True while a pointer drag is active — suppresses the handle's CSS
  /// transition so it tracks the pointer without lag (Flutter parity:
  /// `_animate = false` during a drag; the release snap re-enables it).
  bool _dragging = false;

  /// Handle position when the current drag session started. The engine
  /// reports movement as a pointer-anchored transform, so the live
  /// position is `base + transform` (no delta accumulation drift).
  double _dragBaseX = 0;
  double _dragBaseY = 0;

  /// The shared drag engine runtime — the same `coui_core` engine the Flutter
  /// `DraggablePanel` runs, so both platforms recognise the drag, keyboard
  /// activation and a11y announcements identically.
  final DragScopeController _dragController = DragScopeController();

  /// Dock geometry resolved through the same merge chain as the chrome
  /// (theme → widget style), refreshed on every build. The handlers only
  /// run after a build, so it is always set by the time they read it.
  late ResolvedDraggablePanelRuntime _runtime;

  CoreDraggablePanelController get _controller =>
      component.controller ??
      (_ownController ??= CoreDraggablePanelController());

  @override
  void initState() {
    super.initState();
    // After the first client render: observe the root box. The observer
    // fires immediately with the initial size, which records the initial
    // dock position into the controller (Flutter parity: the post-frame
    // `setPosition` in the first finite `LayoutBuilder` pass). No-op on
    // the server (stub `scheduleNextFrame`).
    popover_dom.scheduleNextFrame(_attachContainerObserver);
  }

  void _attachContainerObserver() {
    if (!mounted) return;
    _containerResizeDisposer = dom_utils.observeElementResize(_rootId, (
      width,
      height,
    ) {
      if (!mounted) return;
      final firstMeasure = _containerSize == null;
      _containerSize = (width: width, height: height);
      if (firstMeasure && !_positioned) {
        // Convert the CSS dock into explicit container-local coordinates
        // so `controller.x/y` reflect the real dock before any interaction
        // and a first tap never teleports the handle.
        _controller.setPosition(
          _runtime.dockSlotX(containerWidth: width, left: false),
          height * _kInitialYFraction,
        );
        setState(() => _positioned = true);
        return;
      }
      // Container resized — re-render so panel placement recomputes
      // (Flutter parity: LayoutBuilder re-runs on constraint change).
      setState(() {});
    });
  }

  void _setOpen(bool open) {
    if (_controller.open == open) return;
    setState(() => _controller.open = open);
    component.onOpenChanged?.call(open);
  }

  /// Ensures the container frame is known and the handle sits at an
  /// explicit container-local slot before a drag session moves it.
  ({double width, double height})? _ensureContainerFrame() {
    // Fallback: if the mount measurement was missed (observer not attached
    // yet), read the box once now.
    final container = _containerSize ?? dom_utils.readElementSize(_rootId);
    if (container == null) return null;
    _containerSize = container;
    if (!_positioned) {
      _positioned = true;
      _controller.setPosition(
        _runtime.dockSlotX(containerWidth: container.width, left: false),
        container.height * _kInitialYFraction,
      );
    }
    return container;
  }

  /// Anchors the drag at the handle's current slot — the engine reports
  /// movement relative to the pointer-down position from here on.
  ///
  /// The anchor is where the handle is *painted*, not its logical slot: an
  /// `outside` handle resting past the edge must start the drag from there,
  /// or it would jump inward by the part hidden past the edge (Flutter
  /// parity).
  void handleDragStart(CoreDragStartEvent event) {
    if (_ensureContainerFrame() == null) return;
    _dragged = false;
    _dragBaseX = _paintedX();
    _dragBaseY = _controller.y;
  }

  void handleDragMove(CoreDragMoveEvent event) {
    final container = _containerSize;
    if (container == null) return;
    final transform = event.session.transform;
    final minX = _runtime.dragMinX;
    final maxX = _runtime.dragMaxX(container.width);
    final maxY = (container.height - _runtime.handleSize - component.dockOffset)
        .clamp(
          component.dockOffset,
          double.infinity,
        );
    _dragged = true;
    setState(() {
      _dragging = true;
      _controller.setPosition(
        (_dragBaseX + transform.x).clamp(minX, maxX),
        (_dragBaseY + transform.y).clamp(component.dockOffset, maxY),
      );
    });
  }

  void handleDragEnd(CoreDragEndEvent event) => _settleToEdge();

  void handleDragCancel(CoreDragCancelEvent event) => _settleToEdge();

  /// Snaps to the nearer of the left / right container edges (the release
  /// snap animates — `_dragging` false restores the CSS transition).
  ///
  /// The snap target is the logical dock slot for both dock types; an
  /// `outside` handle is then painted past the edge by [_paintedX].
  void _settleToEdge() {
    final container = _containerSize;
    if (container == null) {
      setState(() => _dragging = false);
      return;
    }
    final snappedX = _runtime.dockSlotX(
      containerWidth: container.width,
      left: _runtime.isLeftHalf(
        x: _controller.x,
        containerWidth: container.width,
      ),
    );
    final currentY = _controller.y;
    setState(() {
      _dragging = false;
      _controller.setPosition(snappedX, currentY);
    });
    component.onPositionChanged?.call(_controller.x, _controller.y);
  }

  /// Starts a fresh pointer interaction on the handle.
  ///
  /// [_dragged] must be cleared here rather than only when a click
  /// consumes it: a drag does not always end in a `click` (the browser
  /// suppresses it when the pointer travels far enough), and a stale
  /// `true` would then swallow the *next* genuine tap.
  void handleHandlePointerDown(Object event) {
    _dragged = false;
  }

  /// A plain click on the handle toggles the panel. The engine's drag
  /// recogniser only claims the pointer once it has moved past the
  /// activation distance, so a click that ends a real drag is suppressed
  /// by [_dragged] (Flutter parity: `GestureDetector.onTap` loses the
  /// arena to an active drag).
  void handleHandleClick(Object event) {
    if (_dragged) return;
    // Called for its measurement side effect only — the toggle works with
    // or without a resolved container frame.
    final _ = _ensureContainerFrame();
    _setOpen(!_controller.open);
  }

  String _remOf(double px) => '${px / kRemDivisor}rem';

  /// Where the handle is painted for its logical position — the dock-type
  /// resting slot, except while a drag is live (Flutter parity:
  /// `_paintedX`). Before the container is measured there is no frame to
  /// resolve a slot against, so the logical position stands.
  double _paintedX() => _runtime.paintedX(
    x: _controller.x,
    open: _controller.open,
    dragging: _dragging,
    containerWidth: _containerSize?.width,
  );

  /// Positions the handle — the geometry lives in the style file so it
  /// is testable without a browser.
  Styles _handlePosition() => buildDraggablePanelHandlePositionInlineStyles(
    _runtime,
    positioned: _positioned,
    x: _controller.x,
    y: _controller.y,
    open: _controller.open,
    dragging: _dragging,
    initialTop: _kInitialYPercent,
    containerWidth: _containerSize?.width,
  );

  /// Positions the panel beside the handle on the side with room.
  Styles _panelPosition(double handleSize, double panelWidth) {
    final gap = component.dockOffset;
    final container = _containerSize;
    if (!_positioned || container == null) {
      // Handle docked right → panel opens to its left.
      return Styles(
        raw: {
          'right': _remOf(component.dockOffset + handleSize + gap),
          'top': _kInitialYPercent,
        },
      );
    }
    final dockLeft = _runtime.isLeftHalf(
      x: _controller.x,
      containerWidth: container.width,
    );
    final panelLeft = dockLeft
        ? _controller.x + handleSize + gap
        : (_controller.x - panelWidth - gap).clamp(0.0, double.infinity);

    // Vertical: open downward from the handle's top by default, but flip
    // upward (anchor the panel's bottom to the handle's bottom) when there is
    // more room above than below — otherwise the panel is clipped by the
    // container edge when the handle is docked low. Mirrors the Flutter
    // `DraggablePanel._buildPanel` placement.
    final spaceBelow = (container.height - _controller.y - gap).clamp(
      0.0,
      double.infinity,
    );
    final spaceAbove = (_controller.y + handleSize - gap).clamp(
      0.0,
      double.infinity,
    );
    final openUpward = spaceBelow < spaceAbove;
    final maxHeight = openUpward ? spaceAbove : spaceBelow;

    return Styles(
      raw: {
        'left': _remOf(panelLeft),
        if (openUpward)
          'bottom': _remOf(
            (container.height - _controller.y - handleSize).clamp(
              0.0,
              double.infinity,
            ),
          )
        else
          'top': _remOf(_controller.y),
        // The room the panel has; the scroller inside it takes the overflow
        // (`resolved.panelScroller`), so the surface itself never clips.
        'max-height': _remOf(maxHeight),
      },
    );
  }

  @override
  void dispose() {
    _containerResizeDisposer?.call();
    _dragController.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    _runtime = resolveDraggablePanelRuntime(
      context,
      dockType: component.dockType,
      dockOffset: component.dockOffset,
      draggablePanelStyle: component.draggablePanelStyle,
    );
    final child = component.child;
    if (!component.enabled) {
      return child ?? div(const [], classes: component.rootClasses(''));
    }

    final resolved = resolveDraggablePanel(
      context,
      dockType: component.dockType,
      dragging: _dragging,
      draggablePanelStyle: component.draggablePanelStyle,
    );
    final handleSize = _runtime.handleSize;
    final panelWidth = _runtime.panelWidth;
    final open = _controller.open;

    // Default handle icon — the unified vector `Icon` with the nested
    // `CoreIconStyle` slot (raw-forward); a custom `handle` still
    // inherits the handle chrome's foreground colour via currentColor.
    final handleContent =
        component.handle ??
        Icon(LucideIcons.menu, iconStyle: resolved.handleIconStyle);

    return DragScope(
      controller: _dragController,
      // The root fills the caller's box with `h-full` — a percentage, which
      // resolves against `auto` if anything sits between the two, and every
      // child here is absolutely positioned so `auto` is zero. Adopting the
      // root as the scope's measurement origin keeps the scope out of the
      // box tree entirely, which is what the Flutter twin gets for free
      // from building an inherited marker that owns no render object.
      originElementId: _rootId,
      child: div(
        [
          // Every slot is keyed because the ones above the handle are
          // conditional: without keys, opening the panel shifts the handle's
          // index and jaspr rebuilds it from scratch — remounting the
          // `DragItem` mid-drag, whose disposal cancels the live session.
          if (child != null)
            div(
              [child],
              key: const ValueKey('content'),
              classes: 'absolute inset-0',
            ),
          if (open && component.closeOnTapOutside)
            div(
              const [],
              key: const ValueKey('scrim'),
              classes: 'absolute inset-0 z-${CoreZIndex.scale.z40}',
              events: {'pointerdown': (_) => _setOpen(false)},
            ),
          if (open && component.panel != null)
            div(
              [
                div(
                  [component.panel!],
                  classes: resolved.panelScroller.className,
                ),
              ],
              key: const ValueKey('panel'),
              classes: resolved.panel.className,
              styles: Styles.combine([
                ?resolved.panel.inlineStyles,
                _panelPosition(handleSize, panelWidth),
              ]),
            ),
          // Tap handling sits *outside* the engine draggable on purpose.
          // The engine captures the pointer on its own wrapper node, and
          // pointer capture retargets `pointerup` / `click` to that capture
          // element — a handler on the inner handle never sees them, since
          // events bubble up rather than down. Wrapping the draggable lets
          // the retargeted click bubble into this handler.
          div(
            [
              DragItem(
                id: _kHandleDragId,
                activationConstraint: const CoreDragActivationConstraint(
                  distance:
                      CoreDraggablePanelContract.defaultDragActivationDistance,
                ),
                onDragStart: handleDragStart,
                onDragMove: handleDragMove,
                onDragEnd: handleDragEnd,
                onDragCancel: handleDragCancel,
                child: div(
                  [handleContent],
                  classes: resolved.handle.className,
                  styles: Styles.combine([
                    ?resolved.handle.inlineStyles,
                    _handlePosition(),
                  ]),
                ),
              ),
            ],
            key: const ValueKey('handle'),
            events: {
              'pointerdown': handleHandlePointerDown,
              'click': handleHandleClick,
            },
          ),
        ],
        id: _rootId,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `DraggablePanel.withStyle` extension —
/// merges a [CoreDraggablePanelStyle] patch into
/// [DraggablePanel.draggablePanelStyle] via the existing
/// [DraggablePanel.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDraggablePanelStyle.merge` right-side-wins semantics).
extension DraggablePanelStyleChain on DraggablePanel {
  /// Returns a copy of this [DraggablePanel] with [patch] merged into
  /// [draggablePanelStyle] (patch fields win on conflict).
  DraggablePanel withStyle(CoreDraggablePanelStyle patch) => copyWith(
    draggablePanelStyle:
        (draggablePanelStyle ?? const CoreDraggablePanelStyle()).merge(patch),
  );
}
