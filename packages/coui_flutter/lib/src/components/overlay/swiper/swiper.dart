import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;

/// A swipe-gesture wrapper that reveals an overlay panel from one
/// edge of the screen.
///
/// `Swiper` wraps a [child] and listens for swipe gestures in the
/// direction that would reveal a [position]-edged overlay (e.g. a
/// swipe to the right reveals a `left` overlay). When the swipe
/// flings past the reveal direction the [overlayContent] is presented
/// through the composed unified `Drawer` (`openDrawer`) — inheriting
/// its slide animation, barrier and drag-to-dismiss, so an open panel
/// can be swiped shut again.
///
/// The component also accepts a controlled [open] value paired with
/// [onOpenChanged] so the overlay can be driven programmatically — a
/// tap on a menu button, for example.
///
/// ```dart
/// Swiper(
///   position: CoreSwiperPosition.left,
///   variant: CoreSwiperVariant.drawer,
///   overlayContent: const NavigationMenu(),
///   child: const AppHeader(),
/// )
/// ```
class Swiper extends StatefulWidget implements CoreSwiperContract<Widget> {
  /// Creates a [Swiper].
  const Swiper({
    required this.child,
    required this.overlayContent,
    this.position = CoreSwiperPosition.defaultPosition,
    this.variant = CoreSwiperVariant.defaultVariant,
    this.open = false,
    this.onOpenChanged,
    this.enabled = true,
    this.showDragHandle = true,
    this.barrierDismissible = true,
    this.swiperStyle,
    super.key,
  });

  @override
  final Widget child;

  @override
  final Widget overlayContent;

  @override
  final CoreSwiperPosition position;

  @override
  final CoreSwiperVariant variant;

  @override
  final bool open;

  @override
  final void Function(bool)? onOpenChanged;

  @override
  final bool enabled;

  @override
  final bool showDragHandle;

  @override
  final bool barrierDismissible;

  @override
  final CoreSwiperStyle? swiperStyle;

  /// Returns a copy of this [Swiper] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Swiper copyWith({
    Key? key,
    Widget? overlayContent,
    CoreSwiperPosition? position,
    CoreSwiperVariant? variant,
    bool? open,
    void Function(bool)? onOpenChanged,
    bool? enabled,
    bool? showDragHandle,
    bool? barrierDismissible,
    CoreSwiperStyle? swiperStyle,
    Widget? child,
  }) {
    return Swiper(
      key: key ?? this.key,
      overlayContent: overlayContent ?? this.overlayContent,
      position: position ?? this.position,
      variant: variant ?? this.variant,
      open: open ?? this.open,
      onOpenChanged: onOpenChanged ?? this.onOpenChanged,
      enabled: enabled ?? this.enabled,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      swiperStyle: swiperStyle ?? this.swiperStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Swiper> createState() => _SwiperState();
}

/// Chain sugar for merging a [CoreSwiperStyle] patch into
/// [Swiper.swiperStyle] without hand-reconstructing every field. Mirrors
/// the Web `Swiper.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwiperStyle.merge` right-side-wins semantics).
extension SwiperStyleChain on Swiper {
  /// Returns a copy of this [Swiper] with [patch] merged into
  /// [swiperStyle] (patch fields win on conflict).
  Swiper withStyle(CoreSwiperStyle patch) => copyWith(
    swiperStyle: (swiperStyle ?? const CoreSwiperStyle()).merge(patch),
  );
}

// Full TickerProviderStateMixin (not Single-): every swipe creates a
// fresh ghost controller, so the state vends a ticker per gesture over
// its lifetime.
class _SwiperState extends State<Swiper> with TickerProviderStateMixin {
  /// Whether the composed drawer is currently presented.
  bool _isOpen = false;

  // Swipe-to-open gesture state (see the engine section below).
  final GlobalKey _ghostPanelKey = GlobalKey();
  Offset? _pointerDownPosition;
  bool _dragging = false;
  AnimationController? _ghostController;
  DrawerBackdropRegistration? _ghostRegistration;

  bool get _isHorizontal => widget.position.isHorizontal;

  /// Returns the drag-axis sign that corresponds to the gesture which
  /// reveals the overlay: a `left` overlay is revealed by dragging
  /// rightwards (+1), a `right` overlay by dragging leftwards (-1),
  /// etc.
  double get _revealSign {
    return switch (widget.position) {
      .left || .top => 1,
      .right || .bottom => -1,
    };
  }

  CoreDrawerSide get _drawerSide {
    return switch (widget.position) {
      .left => .left,
      .right => .right,
      .top => .top,
      .bottom => .bottom,
    };
  }

  void _notifyOpenChanged({required bool isOpen}) {
    widget.onOpenChanged?.call(isOpen);
  }

  /// The unified drawer panel — shared verbatim by the committed
  /// route presentation and the ghost-layer scrub so the two are
  /// pixel-identical and the commit swap is invisible.
  Widget _buildDrawerPanel(BuildContext context) {
    final resolved = resolveSwiper(
      context,
      variant: widget.variant,
      swiperStyle: widget.swiperStyle,
    );
    return Drawer(
      content: widget.overlayContent,
      side: _drawerSide,
      // The handle is the drawer's own — drawn on the panel edge that faces
      // the viewport centre, in the drawer style's handle chrome.
      showDragHandle: widget.showDragHandle,
      barrierDismissible: widget.barrierDismissible,
      transformBackdrop: widget.variant == .drawer,
      drawerStyle: resolved.drawerStyle,
    );
  }

  void _openOverlay({DrawerAnimationHandle? animationHandle}) {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    final resolved = resolveSwiper(
      context,
      variant: widget.variant,
      swiperStyle: widget.swiperStyle,
    );
    // The composed unified Drawer owns the panel surface, slide
    // animation, barrier, drag-to-dismiss and the grab handle — Swiper
    // only contributes the reveal gesture.
    // shadcn's actual drawer/sheet distinction: the drawer variant
    // scales the app behind it (backdrop zoom-out), the sheet variant
    // does not ("a sheet is a drawer with no backdrop transformation").
    final transformBackdrop = widget.variant == .drawer;
    final future = openDrawer<void>(
      context: context,
      side: _drawerSide,
      barrierDismissible: widget.barrierDismissible,
      transformBackdrop: transformBackdrop,
      animationHandle: animationHandle,
      drawerStyle: resolved.drawerStyle,
      // The builder must return the unified Drawer widget, which
      // paints the panel surface — background, border and shadow.
      // Handing it bare content would float the children over the
      // barrier with no panel behind them.
      builder: _buildDrawerPanel,
    );
    unawaited(
      future.whenComplete(() {
        if (!mounted) return;
        if (_isOpen) {
          setState(() => _isOpen = false);
          _notifyOpenChanged(isOpen: false);
        }
      }),
    );
    _notifyOpenChanged(isOpen: true);
  }

  void _closeOverlay() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    closeDrawer<void>(context);
  }

  // ── Swipe-to-open gesture engine (shadcn parity) ────────────────
  //
  // The finger scrubs a **ghost panel** rendered through the app
  // shell's `DrawerBackdropLayer`, driven 1:1 by a Swiper-owned
  // animation controller; releasing past the half threshold springs
  // it fully open and swaps in the real drawer route (pixel-identical,
  // so the swap is invisible), below it the ghost slides back shut.
  //
  // Why not scrub the route itself: presenting a route mid-gesture is
  // impossible — `Navigator.push` cancels every in-flight pointer
  // (`_cancelActivePointers`) and the framework then drops the
  // pointer's remaining move events entirely (its hit-test path is
  // removed with the synthetic cancel), so no widget — recognizer or
  // raw listener — ever sees the rest of the drag. shadcn avoids this
  // by never routing its drawers; the ghost layer borrows exactly
  // that architecture for the gesture, while committed opens keep the
  // route's barrier / Escape / back-button semantics.
  //
  // Raw pointer events (not a GestureDetector) with an axis-dominant
  // slop so taps and cross-axis scrolls never open the panel — and no
  // fling-velocity gate, so a slow deliberate pull opens just as
  // reliably as a flick. Mirrors the Web swiper's raw listeners.

  double? _ghostPanelExtent() {
    final size = _ghostPanelKey.currentContext?.size;
    if (size == null) return null;
    return _isHorizontal ? size.width : size.height;
  }

  /// The ghost — scrim + slide-in panel, visually identical to the
  /// real drawer route's presentation so the commit swap is seamless.
  Widget _buildGhost(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final resolvedDrawer = resolveDrawer(
          context,
          side: _drawerSide,
          drawerStyle: resolveSwiper(
            context,
            variant: widget.variant,
            swiperStyle: widget.swiperStyle,
          ).drawerStyle,
        );
        final isHorizontal = _isHorizontal;
        final slide = Tween(
          begin: switch (widget.position) {
            .left => const Offset(-1, 0),
            .right => const Offset(1, 0),
            .top => const Offset(0, -1),
            .bottom => const Offset(0, 1),
          },
          end: Offset.zero,
        ).animate(controller);
        return Stacks(
          children: [
            Position.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: controller,
                  child: ColoredBox(color: resolvedDrawer.barrierColor),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: switch (widget.position) {
                  .left => Alignment.centerLeft,
                  .right => Alignment.centerRight,
                  .top => Alignment.topCenter,
                  .bottom => Alignment.bottomCenter,
                },
                // The slide wraps the PANEL box (not the full-width
                // page): fractional offsets are relative to the child's
                // own size, and only a panel-sized fraction keeps the
                // scrub 1:1 with the finger (a page-sized fraction
                // moves the panel viewport÷panel× slower).
                child: SlideTransition(
                  position: slide,
                  child: SizedBox(
                    width: isHorizontal ? resolvedDrawer.panelWidth : null,
                    height: isHorizontal ? null : resolvedDrawer.panelHeight,
                    child: KeyedSubtree(
                      key: _ghostPanelKey,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: Builder(builder: _buildDrawerPanel),
    );
  }

  void _beginGhostDrag() {
    final host = DrawerBackdropLayer.maybeOf(context);
    if (host == null) {
      // No app-shell host (plain MaterialApp embeds): fall back to a
      // committed open — the route animates itself, without scrubbing.
      _openOverlay();
      return;
    }
    final resolved = resolveSwiper(
      context,
      variant: widget.variant,
      swiperStyle: widget.swiperStyle,
    );
    final resolvedDrawer = resolveDrawer(
      context,
      side: _drawerSide,
      drawerStyle: resolved.drawerStyle,
    );
    final controller = AnimationController(
      duration: resolvedDrawer.openAnimationDuration,
      reverseDuration: resolvedDrawer.closeAnimationDuration,
      vsync: this,
    );
    _ghostController = controller;
    final transformBackdrop = widget.variant == .drawer;
    _ghostRegistration = host.register(
      animation: controller,
      scale: transformBackdrop ? resolvedDrawer.backdropScale : 1.0,
      cornerRadius: transformBackdrop
          ? resolvedDrawer.backdropCornerRadius
          : .zero,
      panel: _buildGhost(controller),
    );
  }

  void _disposeGhost() {
    final registration = _ghostRegistration;
    _ghostRegistration = null;
    if (registration != null) {
      DrawerBackdropLayer.maybeOf(context)?.unregister(registration);
    }
    _ghostController?.dispose();
    _ghostController = null;
  }

  /// Commits the scrubbed-open ghost: presents the real drawer route
  /// at full progress (pixel-identical), then removes the ghost on the
  /// next frame so the swap is invisible.
  void _commitGhost() {
    final animationHandle = DrawerAnimationHandle();
    _openOverlay(animationHandle: animationHandle);
    animationHandle.controller?.value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _disposeGhost();
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _isOpen || _ghostController != null) return;
    _pointerDownPosition = event.position;
    _dragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final downPosition = _pointerDownPosition;
    if (downPosition == null) return;

    if (!_dragging) {
      final travelled = event.position - downPosition;
      final mainDelta = _isHorizontal ? travelled.dx : travelled.dy;
      final crossDelta = _isHorizontal ? travelled.dy : travelled.dx;
      // Axis-dominant slop — begin the swipe once the finger clearly
      // moves along the reveal axis.
      if (mainDelta.abs() < kTouchSlop || mainDelta.abs() < crossDelta.abs()) {
        return;
      }
      _dragging = true;
      _beginGhostDrag();
      return;
    }

    final controller = _ghostController;
    if (controller == null) return;
    final extent = _ghostPanelExtent();
    if (extent == null || extent == 0) return;
    final delta =
        (_isHorizontal ? event.delta.dx : event.delta.dy) * _revealSign;
    controller.value += delta / extent;
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointerDownPosition = null;
    if (!_dragging) return;
    _dragging = false;
    final controller = _ghostController;
    if (controller == null) return;
    if (controller.value >= CoreDrawerContract.defaultDragDismissThreshold) {
      unawaited(
        controller
            .forward()
            .orCancel
            .then((_) {
              if (mounted) _commitGhost();
            })
            .catchError((Object _) {}),
      );
    } else {
      unawaited(
        controller
            .reverse()
            .orCancel
            .then((_) {
              if (mounted) _disposeGhost();
            })
            .catchError((Object _) {}),
      );
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    if (!_dragging) return;
    _dragging = false;
    final controller = _ghostController;
    if (controller == null) return;
    unawaited(
      controller
          .reverse()
          .orCancel
          .then((_) {
            if (mounted) _disposeGhost();
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _disposeGhost();
    super.dispose();
  }

  @override
  void didUpdateWidget(Swiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to controlled open changes. `didUpdateWidget` runs inside the
    // parent's build/reconcile pass, and `_openOverlay` / `_closeOverlay`
    // mutate the root `Navigator` (push / pop) which marks the overlay
    // dirty — doing that synchronously here throws
    // `setState() or markNeedsBuild() called during build`. Defer the
    // route mutation to the next frame (re-checking the latest `open`
    // since it may flip again before the callback runs).
    if (widget.open != oldWidget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.open) {
          _openOverlay();
        } else {
          _closeOverlay();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draggable = widget.enabled;

    // Web twin exposes aria-expanded on the swipe trigger — whether the
    // panel is open is state the reader needs, not just a visual.
    return Semantics(
      expanded: _isOpen,
      child: Listener(
        onPointerDown: draggable ? _handlePointerDown : null,
        onPointerMove: draggable ? _handlePointerMove : null,
        onPointerUp: draggable ? _handlePointerUp : null,
        onPointerCancel: draggable ? _handlePointerCancel : null,
        behavior: .translucent,
        child: widget.child,
      ),
    );
  }
}
