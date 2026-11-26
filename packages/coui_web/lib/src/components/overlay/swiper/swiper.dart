import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer.dart';
import 'package:coui_web/src/components/overlay/swiper/swiper_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// A swipe-gesture wrapper that reveals an overlay panel from one
/// edge of the viewport.
///
/// `Swiper` wraps a [child] and listens for touch / pointer swipe
/// gestures in the direction that would reveal a [position]-edged
/// overlay (e.g. a swipe to the right reveals a `left` overlay). When
/// the swipe crosses the reveal threshold the [overlayContent] is
/// presented through the composed unified `Drawer` (`openDrawer`) —
/// inheriting its slide animation, barrier and drag-to-dismiss, so an
/// open panel can be swiped shut again.
///
/// The component also accepts a controlled [open] value paired with
/// [onOpenChanged] so the overlay can be driven programmatically.
///
/// ```dart
/// Swiper(
///   position: CoreSwiperPosition.left,
///   variant: CoreSwiperVariant.drawer,
///   overlayContent: NavigationMenu(),
///   child: AppHeader(),
/// )
/// ```
class Swiper extends UiStatefulComponent
    implements CoreSwiperContract<Component> {
  /// Creates a [Swiper].
  const Swiper({
    required this.child,
    required this.overlayContent,
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
    this.position = CoreSwiperPosition.defaultPosition,
    this.variant = CoreSwiperVariant.defaultVariant,
    this.open = false,
    this.onOpenChanged,
    this.enabled = true,
    this.showDragHandle = true,
    this.barrierDismissible = true,
    this.swiperStyle,
  });

  @override
  final Component child;

  @override
  final Component overlayContent;

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
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    Component? overlayContent,
    CoreSwiperPosition? position,
    CoreSwiperVariant? variant,
    bool? open,
    void Function(bool)? onOpenChanged,
    bool? enabled,
    bool? showDragHandle,
    bool? barrierDismissible,
    CoreSwiperStyle? swiperStyle,
    Component? child,
  }) {
    return Swiper(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      overlayContent: overlayContent ?? this.overlayContent,
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

/// Chain sugar mirroring the Flutter `Swiper.withStyle` extension —
/// merges a [CoreSwiperStyle] patch into [Swiper.swiperStyle] via the
/// existing [Swiper.copyWith].
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

/// Minimum swipe distance (CSS px) before a gesture counts as a
/// reveal. Below this the gesture is treated as an incidental touch.
/// Not a design token — interaction implementation detail.
/// Axis-dominant slop before a pointer drag becomes a swipe-to-open
/// scrub (mirrors Flutter's kTouchSlop).
const double _kSwipeSlop = 18;

class _SwiperState extends State<Swiper> {
  /// Whether the composed drawer is currently presented.
  bool _isOpen = false;

  /// Close callback captured from the drawer builder — drives the
  /// controlled `open = false` path.
  void Function([void])? _closeDrawer;

  /// Pointer coordinate where the active swipe gesture started.
  DrawerScrubController? _scrub;
  bool _committed = false;
  double? _swipeStartX;
  double? _swipeStartY;
  void Function()? _detachDrag;
  StreamSubscription<web.Event>? _blurSubscription;
  StreamSubscription<web.Event>? _visibilitySubscription;
  int _overlayGeneration = 0;

  /// Returns the drag-axis sign that corresponds to the gesture which
  /// reveals the overlay: a `left` overlay is revealed by dragging
  /// rightwards (+1), a `right` overlay by dragging leftwards (-1),
  /// etc.
  double _revealSign() => switch (component.position) {
    .left || .top => 1,
    .right || .bottom => -1,
  };

  CoreDrawerSide get _drawerSide => switch (component.position) {
    .left => .left,
    .right => .right,
    .top => .top,
    .bottom => .bottom,
  };

  void _openOverlay(
    BuildContext context, {
    DrawerScrubController? scrubController,
    bool notifyOpen = true,
  }) {
    if (_isOpen) return;
    _isOpen = true;
    _committed = false;
    final generation = ++_overlayGeneration;
    final resolved = resolveSwiper(
      context,
      variant: component.variant,
      position: component.position,
      swiperStyle: component.swiperStyle,
    );
    // The composed unified Drawer owns the panel surface, barrier,
    // slide animation, drag-to-dismiss and the grab handle — Swiper only
    // contributes the reveal gesture.
    final future = openDrawer<void>(
      context: context,
      side: _drawerSide,
      scrubController: scrubController,
      builder: (close) {
        _closeDrawer = close;
        return Drawer(
          content: component.overlayContent,
          side: _drawerSide,
          // The handle is the drawer's own — drawn on the panel edge that
          // faces the viewport centre, in the drawer style's handle chrome.
          showDragHandle: component.showDragHandle,
          barrierDismissible: component.barrierDismissible,
          // shadcn's actual drawer/sheet distinction: the drawer
          // variant scales the app behind it (backdrop zoom-out), the
          // sheet variant does not.
          transformBackdrop: component.variant == .drawer,
          drawerStyle: resolved.drawerStyle,
        );
      },
    );
    unawaited(
      future.whenComplete(() {
        if (!mounted || generation != _overlayGeneration) return;
        _resetGesture();
        _closeDrawer = null;
        _scrub = null;
        if (_isOpen) {
          _isOpen = false;
          // Aborted scrubs never opened — no close event for them.
          if (_committed) component.onOpenChanged?.call(false);
        }
        _committed = false;
      }),
    );
    if (notifyOpen) {
      _committed = true;
      component.onOpenChanged?.call(true);
    }
  }

  void _closeOverlay() {
    _resetGesture();
    _scrub = null;
    if (!_isOpen) return;
    _isOpen = false;
    _closeDrawer?.call();
    _closeDrawer = null;
  }

  // ── Swipe-to-open gesture engine (shadcn parity) ────────────────
  //
  // Passing the axis-dominant slop mounts the drawer immediately with
  // a scrub controller; every subsequent move drives the panel /
  // barrier / backdrop 1:1 with the pointer (progress = travelled ÷
  // panel extent). Release settles — springs fully open past the half
  // threshold, slides back shut (with the close animation) below it.
  // No min-distance gate, so a slow deliberate pull opens just as
  // reliably as a flick. Mirrors the Flutter swiper's ghost scrub.

  void _handleSwipeStart(double x, double y) {
    if (!component.enabled || _isOpen) return;
    _swipeStartX = x;
    _swipeStartY = y;
  }

  void _resetGesture() {
    final detach = _detachDrag;
    _detachDrag = null;
    detach?.call();
    if (_blurSubscription != null) unawaited(_blurSubscription!.cancel());
    _blurSubscription = null;
    if (_visibilitySubscription != null) {
      unawaited(_visibilitySubscription!.cancel());
    }
    _visibilitySubscription = null;
    _swipeStartX = null;
    _swipeStartY = null;
  }

  void _cancelSwipe() {
    final scrubbing = _scrub != null;
    _resetGesture();
    if (scrubbing) _closeOverlay();
  }

  void _handleSwipeMove(BuildContext context, double x, double y) {
    final startX = _swipeStartX;
    final startY = _swipeStartY;
    if (startX == null || startY == null) return;

    final isHorizontal = component.position.isHorizontal;
    final mainDelta = (isHorizontal ? x - startX : y - startY) * _revealSign();
    final crossDelta = isHorizontal ? y - startY : x - startX;

    final scrub = _scrub;
    if (scrub == null) {
      if (_isOpen) return;
      // Axis-dominant slop, reveal direction only.
      if (mainDelta < _kSwipeSlop || mainDelta.abs() < crossDelta.abs()) {
        return;
      }
      final controller = DrawerScrubController();
      _scrub = controller;
      // Progress must be non-null from the very first entry build so
      // the overlay mounts pointer-transparent — otherwise its
      // viewport-covering root steals the next move event and the
      // scrub never receives another delta.
      controller.update(0);
      _openOverlay(context, scrubController: controller, notifyOpen: false);
      return;
    }

    // Escape or another Drawer dismiss can end the scrub before its
    // close animation completes. Later pointer events cannot revive it.
    if (scrub.progress == null) {
      _resetGesture();
      return;
    }

    final extent = scrub.panelExtent ?? _fallbackPanelExtent(context);
    if (extent <= 0) return;
    scrub.update(mainDelta / extent);
  }

  void _handleSwipeEnd(BuildContext context, double x, double y) {
    _handleSwipeMove(context, x, y);
    _resetGesture();
    final scrub = _scrub;
    if (scrub == null) return;
    _scrub = null;
    final progress = scrub.progress;
    if (progress == null) return;
    if (progress >= CoreDrawerContract.defaultDragDismissThreshold) {
      scrub.settle(open: true);
      _committed = true;
      component.onOpenChanged?.call(true);
    } else {
      _closeOverlay();
    }
  }

  /// The horizontal panel extent is the resolved panel width; vertical
  /// content-sized panels report their measured extent through the
  /// scrub controller, so this fallback only covers the first moves
  /// before that measurement lands.
  double _fallbackPanelExtent(BuildContext context) {
    final resolved = resolveSwiper(
      context,
      variant: component.variant,
      position: component.position,
      swiperStyle: component.swiperStyle,
    );
    return resolved.drawerStyle.panelWidth ?? CoreDrawerStyle.defaultPanelWidth;
  }

  Map<String, void Function(web.Event)> _childEvents(BuildContext context) {
    if (!component.enabled) return const {};
    return {
      'pointerdown': (web.Event event) {
        final pointer = event as web.PointerEvent;
        if (_detachDrag != null ||
            _isOpen ||
            !pointer.isPrimary ||
            pointer.button != 0) {
          return;
        }
        final x = mouseClientX(event);
        final y = mouseClientY(event);
        if (x == null || y == null) return;
        _handleSwipeStart(x, y);
        // The modal Drawer makes this subtree inert at the first slop
        // crossing. Keep following the same pointer at document level.
        _detachDrag = registerDragListeners(
          downEvent: event,
          onMove: (move) {
            final x = mouseClientX(move);
            final y = mouseClientY(move);
            if (x != null && y != null) {
              _handleSwipeMove(context, x, y);
              if (_scrub != null) preventDefault(move);
            }
          },
          onUp: (up) {
            final x = mouseClientX(up);
            final y = mouseClientY(up);
            if (x != null && y != null) {
              _handleSwipeEnd(context, x, y);
            } else {
              _cancelSwipe();
            }
          },
          onCancel: (_) => _cancelSwipe(),
        );
        _blurSubscription = web.EventStreamProviders.blurEvent
            .forTarget(web.window)
            .listen((_) => _cancelSwipe());
        _visibilitySubscription =
            const web.EventStreamProvider<web.Event>(
              'visibilitychange',
            ).forTarget(web.document).listen((_) {
              if (web.document.visibilityState == 'hidden') _cancelSwipe();
            });
      },
    };
  }

  Map<String, String> _rootAttributes() {
    final attributes = {
      'data-swiper-position': component.position.name,
      'data-swiper-variant': component.variant.name,
    };
    if (component.enabled) {
      attributes['data-swiper-enabled'] = 'true';
    }
    if (_isOpen) {
      attributes['aria-expanded'] = 'true';
    }
    return attributes;
  }

  @override
  void didUpdateComponent(Swiper oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (_scrub != null &&
        (!component.enabled || component.position != oldComponent.position)) {
      final close = _closeDrawer;
      _resetGesture();
      _scrub = null;
      unawaited(
        Future.microtask(() {
          if (mounted && identical(close, _closeDrawer)) _closeOverlay();
        }),
      );
    } else if (!component.enabled ||
        component.position != oldComponent.position) {
      _resetGesture();
    }
    // React to controlled open changes. `openDrawer` mutates the
    // overlay-host controller, which must not happen inside this
    // widget's build/reconcile pass — defer a microtask (portal sync
    // rule), re-checking the latest `open`.
    if (component.open != oldComponent.open) {
      if (!component.open) _resetGesture();
      unawaited(
        Future.microtask(() {
          if (!mounted) return;
          if (component.open) {
            _openOverlay(context);
          } else {
            _closeOverlay();
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    _resetGesture();
    _isOpen = false;
    _committed = false;
    _closeDrawer?.call();
    _closeDrawer = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSwiper(
      context,
      variant: component.variant,
      position: component.position,
      swiperStyle: component.swiperStyle,
    );

    return div(
      [
        div(
          [component.child],
          classes: resolved.child.className,
          styles: resolved.child.inlineStyles,
          events: _childEvents(context),
        ),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        if (!component.enabled) const Styles(raw: {'touch-action': 'auto'}),
        ?component.css,
      ]),
      attributes: {...component.componentAttributes, ..._rootAttributes()},
      events: component.events,
    );
  }
}
