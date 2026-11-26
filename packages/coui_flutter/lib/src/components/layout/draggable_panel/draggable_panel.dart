import 'package:coui_flutter/coui_flutter.dart';

/// Default glyph drawn inside the collapsed handle when no custom
/// `handle` is supplied (a simple drag affordance).

/// Fraction of the viewport height used for the handle's initial Y dock.
const double _kInitialYFraction = 0.25;

/// Engine id of the panel handle — one draggable per panel instance, so a
/// constant id is unambiguous inside this panel's own `DragScope`.
const CoreDragId _kHandleDragId = CoreDragId('coui-draggable-panel-handle');

/// A floating, draggable, edge-docking panel — CoUI's cross-platform
/// equivalent of an Apple PencilKit tool palette.
///
/// [child] is the subtree the panel floats over (typically the whole
/// screen). A draggable handle button overlays it; dragging the handle
/// moves it and, on release, it snaps to the nearest viewport edge.
/// Tapping the handle toggles the expandable [panel] surface (caller
/// content). Every chrome override flows through the single
/// [draggablePanelStyle] ([CoreDraggablePanelStyle]); drag behaviour
/// (`dockType` / `enabled` / `closeOnTapOutside` / `dockOffset`) and the
/// optional [controller] stay flat on the widget — identical to the Web
/// `DraggablePanel`.
///
/// surface:behind — a panel dragged around over the page, with that page
/// behind it the whole time.
///
/// surface:functional — a panel dragged around over the page, with that
/// page behind it.
class DraggablePanel extends StatefulWidget
    implements CoreDraggablePanelContract<Widget> {
  /// Creates a [DraggablePanel].
  const DraggablePanel({
    this.child,
    super.key,
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
  final Widget? child;

  @override
  final Widget? panel;

  @override
  final Widget? handle;

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
    Key? key,
    Widget? panel,
    Widget? handle,
    CoreDraggablePanelDockType? dockType,
    bool? enabled,
    bool? closeOnTapOutside,
    double? dockOffset,
    CoreDraggablePanelController? controller,
    void Function(double x, double y)? onPositionChanged,
    CoreValueChanged<bool>? onOpenChanged,
    CoreDraggablePanelStyle? draggablePanelStyle,
    Widget? child,
  }) {
    return DraggablePanel(
      key: key ?? this.key,
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
  late CoreDraggablePanelController _controller =
      widget.controller ?? CoreDraggablePanelController();

  /// Whether the handle has been placed at its initial dock position (set
  /// once the first finite layout is known).
  bool _positioned = false;

  /// Whether the next position change should animate (false during an
  /// active drag so the handle tracks the pointer without lag).
  bool _animate = true;

  /// True while a drag session is live — the handle is then painted at the
  /// pointer-tracking position rather than its dock-type resting slot.
  bool _dragging = false;

  /// The shared drag engine runtime — the same `coui_core` engine the Web
  /// `DraggablePanel` runs, so both platforms recognise the drag, keyboard
  /// activation and a11y semantics identically.
  final DragScopeController _dragController = DragScopeController();

  /// Handle position when the current drag session started. The engine
  /// reports movement as a pointer-anchored transform, so the live
  /// position is `base + transform` (no delta accumulation drift).
  double _dragBaseX = 0;
  double _dragBaseY = 0;

  /// Last layout known to `build`, read back by the drag callbacks to
  /// clamp movement and pick the snap edge.
  double _viewWidth = 0;
  double _viewHeight = 0;
  double _handleSize = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate(CoreDraggablePanelState _) {
    if (mounted) setState(() {});
  }

  void _handleToggle() {
    final next = !_controller.open;
    _controller.open = next;
    widget.onOpenChanged?.call(next);
  }

  void _handleOutsideTap() {
    if (!_controller.open) return;
    _controller.open = false;
    widget.onOpenChanged?.call(false);
  }

  /// Anchors the drag at the handle's current slot — the engine reports
  /// movement relative to the pointer-down position from here on.
  ///
  /// The anchor is where the handle is *painted*, not its logical slot: an
  /// `outside` handle resting past the edge must start the drag from
  /// there, or it would jump inward by the part hidden past the edge.
  void handleDragStart(CoreDragStartEvent event) {
    // Read before `_dragging` flips — once it does, `_paintedX` reports
    // the raw logical position.
    _dragBaseX = _paintedX(_controller.x, open: _controller.open);
    _dragBaseY = _controller.y;
    _animate = false;
    _dragging = true;
  }

  void handleDragMove(CoreDragMoveEvent event) {
    final transform = event.session.transform;
    final minX = widget.dockType.minX(
      handleSize: _handleSize,
      dockOffset: widget.dockOffset,
    );
    final maxX = widget.dockType.maxX(
      viewWidth: _viewWidth,
      handleSize: _handleSize,
      dockOffset: widget.dockOffset,
    );
    final maxY = (_viewHeight - _handleSize - widget.dockOffset).clamp(
      widget.dockOffset,
      double.infinity,
    );
    _controller.setPosition(
      (_dragBaseX + transform.x).clamp(minX, maxX),
      (_dragBaseY + transform.y).clamp(widget.dockOffset, maxY),
    );
  }

  /// Where the handle is painted for the logical position [x] — the
  /// dock-type resting slot, except while a drag is live.
  double _paintedX(double x, {required bool open}) => _dragging
      ? x
      : widget.dockType.restingX(
          x: x,
          open: open,
          viewWidth: _viewWidth,
          handleSize: _handleSize,
          dockOffset: widget.dockOffset,
        );

  void handleDragEnd(CoreDragEndEvent event) => _settleToEdge();

  void handleDragCancel(CoreDragCancelEvent event) => _settleToEdge();

  /// Snaps to the nearer of the left / right viewport edges (the release
  /// snap animates — `_animate` back on restores the transition).
  ///
  /// The snap target is the logical dock slot for both dock types; an
  /// `outside` handle is then painted past the edge by [_paintedX].
  void _settleToEdge() {
    final center = _controller.x + _handleSize / 2;
    final dockLeft = center < _viewWidth / 2;
    final snappedX = dockLeft
        ? widget.dockOffset
        : _viewWidth - _handleSize - widget.dockOffset;
    // Rebuilt explicitly: a release onto the slot it started from leaves
    // the controller unchanged, and the handle must still leave its
    // pointer-tracking position for the resting one.
    // A cancel can arrive while the engine tears the session down during
    // disposal — there is nothing left to rebuild then.
    if (mounted) {
      setState(() {
        _animate = true;
        _dragging = false;
      });
    }
    final currentY = _controller.y;
    _controller.setPosition(snappedX, currentY);
    widget.onPositionChanged?.call(_controller.x, _controller.y);
  }

  Widget _buildHandle(ResolvedDraggablePanel resolved, double x, double y) {
    final size = resolved.handleSize;
    return AnimatedPositioned(
      left: x,
      top: y,
      width: size,
      height: size,
      curve: Curves.easeInOut,
      duration: _animate ? resolved.animationDuration : .zero,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // Tap toggles the panel, drag moves it: the engine's drag
        // recognizer only claims the gesture once the pointer actually
        // moves, so a stationary press still resolves as a tap here.
        child: GestureDetector(
          onTap: _handleToggle,
          child: DragItem(
            id: _kHandleDragId,
            activationConstraint: const CoreDragActivationConstraint(
              distance:
                  CoreDraggablePanelContract.defaultDragActivationDistance,
            ),
            onDragStart: handleDragStart,
            onDragMove: handleDragMove,
            onDragEnd: handleDragEnd,
            onDragCancel: handleDragCancel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolved.handleBackgroundColor,
                borderRadius: resolved.handleBorderRadius,
                boxShadow: resolved.handleShadow,
              ),
              child: Center(
                // A custom handle widget inherits the resolved foreground
                // as its ambient icon colour — the caller-supplied-widget
                // fallback. The default vector icon carries its own nested
                // style so both platforms rasterise the same glyph.
                child: IconTheme.merge(
                  data: IconThemeData(color: resolved.handleForegroundColor),
                  child:
                      widget.handle ??
                      Icon(
                        LucideIcons.menu,
                        iconStyle: resolved.handleIconStyle,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    ResolvedDraggablePanel resolved,
    double x,
    double y,
    double viewWidth,
    double viewHeight,
  ) {
    final handleSize = resolved.handleSize;
    final gap = widget.dockOffset;
    final dockLeft = x + handleSize / 2 < viewWidth / 2;
    // Open the panel beside the handle, on the side with room.
    final panelLeft = dockLeft
        ? x + handleSize + gap
        : (x - resolved.panelWidth - gap).clamp(0.0, double.infinity);

    // Vertical placement: open downward from the handle's top edge by default.
    // When the handle is docked low (less room below than above), open upward
    // by anchoring the panel's bottom to the handle's bottom edge — otherwise
    // the panel is squeezed into the sliver of space beneath a low handle and
    // its content is clipped.
    final spaceBelow = (viewHeight - y - gap).clamp(0.0, double.infinity);
    final spaceAbove = (y + handleSize - gap).clamp(0.0, double.infinity);
    final openUpward = spaceBelow < spaceAbove;
    final maxHeight = openUpward ? spaceAbove : spaceBelow;

    return AnimatedPositioned(
      left: panelLeft,
      top: openUpward ? null : y.clamp(0.0, double.infinity),
      bottom: openUpward
          ? (viewHeight - y - handleSize).clamp(0.0, double.infinity)
          : null,
      width: resolved.panelWidth,
      curve: Curves.easeInOut,
      duration: resolved.animationDuration,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        // Handed over only when the panel states a fill, so a fill-less
        // panel never stacks a second backdrop pass. The radius bounds
        // the pass to the panel shape.
        child: _MaybeSurfaceBlur(
          resolved: resolved,
          child: InsetShadow(
            shadows: resolved.panelInsetShadow,
            radius: resolved.panelBorderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolved.panelBackgroundColor,
                border: Border.all(
                  color: resolved.panelBorderColor,
                  width: resolved.panelBorderWidth,
                ),
                borderRadius: resolved.panelBorderRadius,
                boxShadow: resolved.panelShadow,
              ),
              child: Padding(
                padding: resolved.panelPadding,
                child: SingleChildScrollView(child: widget.panel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(DraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleControllerUpdate);
      _controller = widget.controller ?? CoreDraggablePanelController();
      _controller.addListener(_handleControllerUpdate);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!widget.enabled) {
      return child ?? const SizedBox.shrink();
    }

    final resolved = resolveDraggablePanel(
      context,
      draggablePanelStyle: widget.draggablePanelStyle,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewWidth = constraints.maxWidth;
        final viewHeight = constraints.maxHeight;
        final handleSize = resolved.handleSize;
        final hasViewport = viewWidth.isFinite && viewHeight.isFinite;

        // Cache the layout for the engine drag callbacks, which run
        // outside build and need the same frame's clamp / snap bounds.
        _viewWidth = viewWidth;
        _viewHeight = viewHeight;
        _handleSize = handleSize;

        // First finite layout: persist the initial dock-right position into
        // the controller (post-frame to avoid setState during build), while
        // already painting at that position so there is no (0,0) flash.
        final initialX = hasViewport
            ? viewWidth - handleSize - widget.dockOffset
            : widget.dockOffset;
        final initialY = hasViewport
            ? viewHeight * _kInitialYFraction
            : widget.dockOffset;
        if (!_positioned && hasViewport) {
          _positioned = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.setPosition(initialX, initialY);
          });
        }

        final x = _positioned ? _controller.x : initialX;
        final y = _positioned ? _controller.y : initialY;
        final open = _controller.open;
        // The panel opens beside the logical slot; the handle is painted
        // at its dock-type resting slot (past the edge for a closed
        // `outside` handle), so opening pulls it back into view.
        final handleX = hasViewport ? _paintedX(x, open: open) : x;

        return DragScope(
          controller: _dragController,
          child: Stacks(
            children: [
              if (child != null) Position.fill(child: child),
              if (open && widget.closeOnTapOutside)
                Position.fill(
                  child: GestureDetector(
                    onTap: _handleOutsideTap,
                    behavior: .translucent,
                  ),
                ),
              if (open && widget.panel != null)
                _buildPanel(resolved, x, y, viewWidth, viewHeight),
              _buildHandle(resolved, handleX, y),
            ],
          ),
        );
      },
    );
  }
}

/// Chain sugar for merging a [CoreDraggablePanelStyle] patch into
/// [DraggablePanel.draggablePanelStyle] without hand-reconstructing every
/// field. Mirrors the Web `DraggablePanel.withStyle` extension so both
/// platforms read identically.
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

/// Wraps [child] in a [SurfaceBlur] when the resolver handed over a
/// material, and returns it untouched otherwise.
///
/// A separate widget rather than a local: the panel is built inside one
/// `AnimatedPositioned(...)` expression, and hoisting it out to apply a
/// conditional would restructure the whole branch for one `if`.
class _MaybeSurfaceBlur extends StatelessWidget {
  const _MaybeSurfaceBlur({required this.resolved, required this.child});

  final ResolvedDraggablePanel resolved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blur = resolved.surfaceBlur;
    if ((blur == null || blur <= 0) && resolved.surfaceSheen == null) {
      return child;
    }
    return SurfaceBlur(
      borderRadius: resolved.panelBorderRadius,
      surfaceBlur: blur,
      surfaceSaturation: resolved.surfaceSaturation,
      surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
      surfaceSheen: resolved.surfaceSheen,
      // The active material's bend. Every surface that draws the material
      // draws all of it — the frost and the chroma without the bend is a
      // blurred panel, not glass, and the bend is the term the material
      // is named for.
      //
      // Falls back rather than being required: a style that states no
      // refraction leaves this null and the surface simply does not
      // bend, which is how every preset but glass renders.
      refraction: Theme.of(context).surfaceRefraction,
      child: child,
    );
  }
}
