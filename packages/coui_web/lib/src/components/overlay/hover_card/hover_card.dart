import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/overlay/hover_card/hover_card_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Process-level counter used to mint unique scope ids so multiple
/// `HoverCard` instances on the same page don't collide on
/// `getElementById` lookups.
int _coHoverCardIdCounter = 0;

/// A unified hover card component for CoUI Web.
///
/// Displays a floating card on hover over the [trigger] component.
/// The card stays open while the pointer is over either the trigger
/// or the card itself, and closes after [closeDelay] once the pointer
/// leaves both regions. On touch devices a long press on the trigger
/// also opens the card (parity with Flutter `HoverCard.onLongPress`).
///
/// The panel is portaled into the root `OverlayHost` popover layer
/// (same layer as `Popover` — hover cards are click-equivalent
/// floating surfaces, distinct from the `tooltip` layer which is for
/// brief hover hints). This means the panel is no longer clipped by
/// ancestor `overflow: hidden` / `transform` containers.
///
/// Mirrors Flutter `HoverCard` 1:1 — same parameter names, same
/// timing tokens, same enter/exit motion (scale 0.9 ↔ 1.0 over
/// `CoreHoverCardStyle.defaultTransitionDuration`).
///
/// Example:
/// ```dart
/// HoverCard(
///   trigger: Text('@user'),
///   content: Text('User profile card'),
///   placement: CorePopoverPlacement.bottom,
/// )
/// ```
///
/// surface:functional — an anchored panel the overlay layer mounts over its
/// trigger.
class HoverCard extends UiStatefulComponent
    implements CoreHoverCardContract<Component, CoreVoidCallback> {
  /// Creates a [HoverCard].
  const HoverCard({
    required this.trigger,
    required this.content,
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
    this.placement = CorePopoverPlacement.bottom,
    this.openDelay,
    this.closeDelay,
    this.onClose,
    this.hoverCardStyle,
  });

  @override
  final Component trigger;

  @override
  final Component content;

  @override
  final CorePopoverPlacement placement;

  @override
  final Duration? openDelay;

  @override
  final Duration? closeDelay;

  @override
  final CoreVoidCallback? onClose;

  @override
  final CoreHoverCardStyle? hoverCardStyle;

  /// Returns a copy of this [HoverCard] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  HoverCard copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Component? trigger,
    Component? content,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CorePopoverPlacement? placement,
    Duration? openDelay,
    Duration? closeDelay,
    CoreVoidCallback? onClose,
    CoreHoverCardStyle? hoverCardStyle,
  }) {
    return HoverCard(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
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
      placement: placement ?? this.placement,
      openDelay: openDelay ?? this.openDelay,
      closeDelay: closeDelay ?? this.closeDelay,
      onClose: onClose ?? this.onClose,
      hoverCardStyle: hoverCardStyle ?? this.hoverCardStyle,
    );
  }

  @override
  State<HoverCard> createState() => _HoverCardState();
}

/// Chain sugar mirroring the Flutter `HoverCard.withStyle` extension —
/// merges a [CoreHoverCardStyle] patch into [HoverCard.hoverCardStyle] via
/// the existing [HoverCard.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHoverCardStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CorePopupStyle.borderRadius] and `.primary` sets
/// [CorePopupStyle.backgroundColor] on [CoreHoverCardStyle.panelStyle] — the
/// panel box is a composed `Popup`, and these are its primary fill and
/// corner. A semantic layer that names these after component-specific intent
/// (decided together with design) is a follow-up once more components adopt
/// this pattern.
///
/// ```dart
/// HoverCard(trigger: Text('@user'), content: Text('Bio')).radius4.surface
/// ```
extension HoverCardStyleChain on HoverCard {
  /// Returns a copy of this [HoverCard] with [patch] merged into
  /// [hoverCardStyle] (patch fields win on conflict).
  HoverCard withStyle(CoreHoverCardStyle patch) => copyWith(
    hoverCardStyle: (hoverCardStyle ?? const CoreHoverCardStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  HoverCard get radius0 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.zero),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  HoverCard get radius2 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  HoverCard get radius4 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  HoverCard get radius6 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  HoverCard get radius8 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  HoverCard get radius10 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  HoverCard get radius12 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  HoverCard get radius14 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  HoverCard get radius16 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  HoverCard get radius20 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  HoverCard get radius24 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  HoverCard get radius28 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  HoverCard get radius32 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  HoverCard get radius36 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  HoverCard get radius40 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  HoverCard get radius48 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  HoverCard get radius56 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  HoverCard get radius64 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  HoverCard get radius9999 => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  HoverCard get primary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  HoverCard get secondary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.secondary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  HoverCard get tertiary => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  HoverCard get surface => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  HoverCard get surfaceContainer => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  HoverCard get error => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.error),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  HoverCard get success => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.success),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  HoverCard get warning => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.warning),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  HoverCard get info => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.info),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  HoverCard get outline => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(
        backgroundColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  HoverCard get transparent => withStyle(
    const CoreHoverCardStyle(
      panelStyle: CorePopupStyle(backgroundColor: .transparent),
    ),
  );
}

class _HoverCardState extends State<HoverCard> {
  bool _isOpen = false;
  bool _isMounted = false;

  /// Whether the panel is playing its exit animation (`co-overlay-exit`)
  /// before unmount. Drives the shared `resolveOverlayMotion` to emit the
  /// exit keyframe over the close window; `_isOpen` controls DOM presence.
  bool _closing = false;

  /// Pending open / close timers — cancelled when the pointer flips
  /// state again before the delay elapses.
  Timer? _openTimer;
  Timer? _closeTimer;
  Timer? _exitTimer;

  /// Pending long-press timer — armed on touch `pointerdown`, fires
  /// [_handleOpen] after [_openDelay] (parity with Flutter
  /// `GestureDetector.onLongPress`).
  Timer? _longPressTimer;

  /// Whether the pointer is currently inside the trigger. Combined
  /// with [_pointerInPanel] to decide whether to keep the card open
  /// or fire the close timer.
  bool _pointerInTrigger = false;
  bool _pointerInPanel = false;

  /// Stable, per-instance ids used so `popover_dom.dart` can locate
  /// the trigger / panel nodes by `getElementById` for placement
  /// measurements.
  late final String _triggerId;
  late final String _panelId;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// panel, fed back declaratively from [_floating]'s `onPosition`
  /// callback. Null until the first frame resolves the position.
  double? _left;
  double? _top;

  /// The unified overlay positioning controller — measures the trigger +
  /// panel, applies flip/shift collision, and reports the resolved origin
  /// via `onPosition`. Owns the scroll/resize listeners. Null while the
  /// hover card is closed. SSR-safe (the conditional import yields a
  /// no-op stub on the server).
  OverlayPositioner? _floating;

  /// Portal handle — set when the panel is mounted on the host
  /// overlay layer; null when the hover card is hidden or no
  /// [OverlayPortal] exists in the ancestor chain (test contexts
  /// without `CoUIWeb` fall back to inline rendering).
  OverlayController? _overlayController;
  int? _overlayToken;

  /// Per-build resolved style — populated by [build] and consumed by
  /// pointer/timer handlers that fire between builds.
  /// Behavioural timing (open/close delay + transition duration) resolved
  /// off the merge chain via [resolveHoverCardTiming] — read by the
  /// stateful pointer / Timer handlers between builds. Kept off
  /// [ResolvedHoverCard] (pure chrome) per the number_ticker pattern.
  ({Duration openDelay, Duration closeDelay, Duration transitionDuration})?
  _timing;

  // ─────────────────────────── lifecycle ───────────────────────────

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coHoverCardIdCounter++;
    _triggerId = 'co-hover-card-trigger-$id';
    _panelId = 'co-hover-card-panel-$id';
  }

  Duration get _openDelay =>
      _timing?.openDelay ??
      component.openDelay ??
      CoreHoverCardStyle.defaultOpenDelay;

  Duration get _closeDelay =>
      _timing?.closeDelay ??
      component.closeDelay ??
      CoreHoverCardStyle.defaultCloseDelay;

  /// Wall-clock duration the host Timer waits between starting the exit
  /// keyframe (`_closing` true) and dropping the panel from the DOM — also
  /// the `co-overlay-enter` / `co-overlay-exit` keyframe duration, so the
  /// panel stays visible for the full motion. HoverCard has a single
  /// `transitionDuration`, so it feeds both enter and exit.
  Duration get _closeTransitionDuration =>
      _timing?.transitionDuration ??
      CoreHoverCardStyle.defaultTransitionDuration;

  // ────────────────────────── pointer events ────────────────────────

  void _handleTriggerEnter(web.MouseEvent event) {
    _pointerInTrigger = true;
    _closeTimer?.cancel();
    _closeTimer = null;
    if (_isOpen) return;
    _openTimer?.cancel();
    _openTimer = Timer(_openDelay, _handleOpen);
  }

  void _handleTriggerLeave(web.MouseEvent event) {
    _pointerInTrigger = false;
    _openTimer?.cancel();
    _openTimer = null;
    _scheduleClose();
  }

  /// Long-press open for touch devices — mirrors Flutter
  /// `GestureDetector.onLongPress`. `pointerdown` arms a timer that
  /// opens the card after [_openDelay]; lifting / cancelling the
  /// pointer before that disarms it.
  void _handlePointerDown(web.Event event) {
    if (_isOpen) return;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_openDelay, _handleOpen);
  }

  void _handlePointerUp(web.Event event) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _handlePanelEnter(web.MouseEvent event) {
    _pointerInPanel = true;
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _handlePanelLeave(web.MouseEvent event) {
    _pointerInPanel = false;
    _scheduleClose();
  }

  void _scheduleClose() {
    if (!_isOpen) return;
    _closeTimer?.cancel();
    _closeTimer = Timer(_closeDelay, () {
      if (!_isMounted) return;
      // Recheck state at fire time — if the pointer re-entered
      // either region during the delay, abort the close.
      if (_pointerInTrigger || _pointerInPanel) return;
      _handleClose();
    });
  }

  void _handleOpen() {
    if (!_isMounted || _isOpen) return;
    _exitTimer?.cancel();
    _exitTimer = null;
    setState(() {
      _isOpen = true;
      _closing = false;
    });
    // Wait one paint frame so the panel has portal-mounted (the
    // portal-sync microtask) before the `OverlayPositioner` measures it.
    // The `co-overlay-enter` keyframe plays on the (re)inserted node once
    // the origin commits (`positioned` true), so no separate open-state
    // flip is needed — it runs on insertion despite the portal node
    // re-creation (see `resolveOverlayMotion`).
    scheduleNextFrame(() {
      if (!_isMounted || !_isOpen) return;
      _openFloating();
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel
  /// and opens it — measures trigger + panel, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` (declarative). Hover-driven, so click / esc dismissal
  /// is off and scrolling repositions (does not close); the keep-open
  /// machine owns close timing.
  void _openFloating() {
    if (!_isMounted || !_isOpen) return;
    final config = resolveHoverCardConfig(
      context,
      hoverCardStyle: component.hoverCardStyle,
    );
    _floating?.dispose();
    _floating = OverlayPositioner(
      triggerId: _triggerId,
      popoverId: _panelId,
      placement: component.placement,
      gap: config.gap,
      closeOnOutsideClick: false,
      closeOnEsc: false,
      closeOnScroll: false,
      // Hover-card panel surface has no side-dependent chrome (no arrow),
      // so the resolved placement is ignored — only the origin is applied.
      onPosition: (left, top, _) {
        if (!_isMounted) return;
        setState(() {
          _left = left;
          _top = top;
        });
      },
    )..open();
  }

  void _handleClose() {
    if (!_isOpen) return;
    // Tear down the positioning controller (detaches its scroll/resize
    // listeners) immediately; the panel stays mounted for the fade-out.
    _floating?.dispose();
    _floating = null;
    component.onClose?.call();
    setState(() => _closing = true);
    _exitTimer?.cancel();
    _exitTimer = Timer(_closeTransitionDuration, () {
      if (!_isMounted) return;
      setState(() {
        _isOpen = false;
        _closing = false;
        _left = null;
        _top = null;
      });
      _unmountPortal();
      _exitTimer = null;
    });
  }

  // ───────────────────────────── portal ────────────────────────────

  void _unmountPortal() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) {
      controller.unmount(token);
    }
    _overlayController = null;
    _overlayToken = null;
  }

  void _schedulePortalSync(OverlayController controller, Component? entry) {
    unawaited(
      Future<void>.microtask(() {
        if (!_isMounted) return;
        if (entry == null) {
          if (_overlayController != null) _unmountPortal();
          return;
        }
        if (_overlayController != controller) {
          _unmountPortal();
          _overlayController = controller;
        }
        final token = _overlayToken;
        if (token == null) {
          _overlayToken = controller.mount(layer: .popover, panel: entry);
        } else {
          controller.update(token, entry);
        }
      }),
    );
  }

  // ──────────────────────── lifecycle / render ─────────────────────

  @override
  void dispose() {
    _isMounted = false;
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _exitTimer?.cancel();
    _longPressTimer?.cancel();
    _floating?.dispose();
    _floating = null;
    _unmountPortal();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Behavioural timing (delays + transition duration) is read off the
    // merge chain via the separate `resolve*` entry point — kept off
    // `ResolvedHoverCard` (pure chrome). Cached so the Timer handlers
    // read it between builds.
    final timing = resolveHoverCardTiming(
      context,
      widgetOpenDelay: component.openDelay,
      widgetCloseDelay: component.closeDelay,
      hoverCardStyle: component.hoverCardStyle,
    );
    _timing = timing;

    final resolved = resolveHoverCard(
      context: context,
      left: _left,
      top: _top,
      hoverCardStyle: component.hoverCardStyle,
    );

    Component? panelNode;
    if (_isOpen) {
      // Three-layer split:
      //   1) outermost (resolved.panel) — `position: fixed` `top` / `left`
      //      placement (no transform). Carries `id: _panelId` so the
      //      `OverlayPositioner` measures + positions *this* stable layout
      //      box; the middle motion div's `scale()` is a paint-only
      //      transform that does not change this box's bounding rect.
      //   2) middle (motion) — structural classes (`resolved.motion`:
      //      whitespace) combined with the shared `resolveOverlayMotion`
      //      `co-overlay-enter` / `co-overlay-exit` keyframes (the single Web
      //      overlay-motion source, shared with `Popover` + the menu family).
      //      The keyframe plays on the (re)inserted node, surviving the
      //      portal node re-creation. HoverCard has a single
      //      `transitionDuration`, so the same value feeds both enter and
      //      exit.
      //   3) inner (`resolved.bubble`) — the composed `Popup` box chrome
      //      (background / border / radius / padding / shadow / width
      //      bounds) only, the same bubble `Popover` draws.
      final motion = resolveOverlayMotion(
        positioned: _left != null && _top != null,
        closing: _closing,
        openDuration: _closeTransitionDuration,
        closeDuration: _closeTransitionDuration,
      );
      panelNode = div(
        [
          div(
            [
              div(
                [component.content],
                classes: resolved.bubble.className,
                styles: resolved.bubble.inlineStyles,
              ),
            ],
            classes: '${resolved.motion.className} ${motion.className}'.trim(),
            styles: Styles.combine([
              ?resolved.motion.inlineStyles,
              ?motion.inlineStyles,
            ]),
            attributes: const {'role': 'dialog'},
            events: {
              'mouseenter': EventHandlers.createMouseEventHandler(
                _handlePanelEnter,
              ),
              'mouseleave': EventHandlers.createMouseEventHandler(
                _handlePanelLeave,
              ),
            },
          ),
        ],
        id: _panelId,
        classes: resolved.panel.className,
        styles: resolved.panel.inlineStyles,
        attributes: TopLayer.attributesFor(context),
      );
    }

    final triggerNode = div(
      [component.trigger],
      id: _triggerId,
      classes: resolved.trigger.className,
      styles: resolved.trigger.inlineStyles,
      attributes: {
        'aria-haspopup': 'dialog',
        'aria-expanded': _isOpen ? 'true' : 'false',
      },
      events: {
        'mouseenter': EventHandlers.createMouseEventHandler(
          _handleTriggerEnter,
        ),
        'mouseleave': EventHandlers.createMouseEventHandler(
          _handleTriggerLeave,
        ),
        'pointerdown': EventHandlers.createEventHandler(_handlePointerDown),
        'pointerup': EventHandlers.createEventHandler(_handlePointerUp),
        'pointercancel': EventHandlers.createEventHandler(_handlePointerUp),
      },
    );

    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      _schedulePortalSync(
        portal.controller,
        portal.capture(context, panelNode),
      );
    } else if (_overlayController != null) {
      _unmountPortal();
    }

    return div(
      [triggerNode, if (!portalled) ?panelNode],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
