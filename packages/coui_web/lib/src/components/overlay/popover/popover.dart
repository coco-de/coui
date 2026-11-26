import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/density_scope.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/overlay/popover/modal_dismiss_control.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/infra/liquid_morph/liquid_morph_clip.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart';

/// Process-level counter used to mint unique scope ids so multiple
/// `Popover` instances on the same page don't collide on
/// `getElementById` lookups.
int _coPopoverIdCounter = 0;

/// A unified popover component for CoUI Web.
///
/// Renders a floating panel anchored to a [trigger] component with
/// configurable [placement], collision-aware positioning, optional
/// modal backdrop, animated open/close, ESC + outside-click dismissal,
/// and an imperative open/close [controller].
///
/// Mirrors Flutter `Popover` 1:1 — same parameter names, same
/// semantics, same default values — so cross-platform call sites can
/// reuse identical code.
///
/// Per Epic #1302, panel chrome / dimensional / animation overrides
/// flow through the single [popoverStyle] field — see
/// [CorePopoverStyle] for the merge chain. Behaviour fields stay flat
/// on the component because they describe interaction policy.
///
/// Example:
/// ```dart
/// Popover(
///   trigger: Button(child: Text('Open')),
///   content: Text('Hello!'),
///   placement: CorePopoverPlacement.bottomStart,
/// )
/// ```
///
/// surface:functional — the panel it anchors is mounted by the overlay
/// layer, over the page.
class Popover extends UiStatefulComponent
    implements
        CorePopoverContract<Component, CoreVoidCallback, PopoverController> {
  /// Creates a [Popover].
  const Popover({
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
    this.controller,
    this.openTrigger = CorePopoverTrigger.click,
    this.modal = false,
    this.dismissOnOutsideTap = true,
    this.dismissOnEscape = true,
    this.closeOnScroll = false,
    this.collision,
    this.widthConstraint,
    this.heightConstraint,
    this.onClose,
    this.popoverStyle,
  });

  @override
  final Component trigger;

  @override
  final Component content;

  @override
  final CorePopoverPlacement placement;

  @override
  final PopoverController? controller;

  @override
  final CorePopoverTrigger openTrigger;

  @override
  final bool modal;

  @override
  final bool dismissOnOutsideTap;

  @override
  final bool dismissOnEscape;

  /// Whether scrolling an ancestor of the trigger or the viewport dismisses
  /// the panel. Defaults to false; panel and unrelated list scrolling do not
  /// close it.
  final bool closeOnScroll;

  @override
  final Set<CorePopoverCollision>? collision;

  @override
  final CorePopoverConstraint? widthConstraint;

  @override
  final CorePopoverConstraint? heightConstraint;

  @override
  final CoreVoidCallback? onClose;

  @override
  final CorePopoverStyle? popoverStyle;

  /// Returns a copy of this [Popover] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Popover copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
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
    Component? trigger,
    Component? content,
    CorePopoverPlacement? placement,
    PopoverController? controller,
    CorePopoverTrigger? openTrigger,
    bool? modal,
    bool? dismissOnOutsideTap,
    bool? dismissOnEscape,
    bool? closeOnScroll,
    Set<CorePopoverCollision>? collision,
    CorePopoverConstraint? widthConstraint,
    CorePopoverConstraint? heightConstraint,
    CoreVoidCallback? onClose,
    CorePopoverStyle? popoverStyle,
  }) {
    return Popover(
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
      controller: controller ?? this.controller,
      openTrigger: openTrigger ?? this.openTrigger,
      modal: modal ?? this.modal,
      dismissOnOutsideTap: dismissOnOutsideTap ?? this.dismissOnOutsideTap,
      dismissOnEscape: dismissOnEscape ?? this.dismissOnEscape,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      collision: collision ?? this.collision,
      widthConstraint: widthConstraint ?? this.widthConstraint,
      heightConstraint: heightConstraint ?? this.heightConstraint,
      onClose: onClose ?? this.onClose,
      popoverStyle: popoverStyle ?? this.popoverStyle,
    );
  }

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  bool _isOpen = false;
  bool _isMounted = false;

  /// Whether the panel is playing its exit animation (`co-overlay-exit`)
  /// before unmount. `_isOpen` controls whether the panel is in the DOM at
  /// all; this drives the shared `resolveOverlayMotion` to emit the exit
  /// keyframe over the close window.
  bool _closing = false;

  /// Pending exit timer — non-null while the panel is animating out
  /// after [_handleClose]. Cancelled if the popover is reopened
  /// before the animation completes.
  Timer? _exitTimer;

  /// Close-animation duration, cached from the single `build` resolve so
  /// [_handleClose] sizes [_exitTimer] without resolving again. Flows
  /// through [CorePopoverStyle] (user-overridable via
  /// `popoverStyle.closeAnimationDuration`).
  Duration _closeDuration = CorePopoverStyle.defaultCloseAnimationDuration;

  /// Resolved external controller — `component.controller` if provided,
  /// otherwise an internally-owned controller so callers always get a
  /// working object back from `component.controller!.isOpen` etc.
  late PopoverController _external;
  bool _ownsExternal = false;

  /// Stable, per-instance ids used so `popover_dom_web.dart` can locate
  /// the trigger / panel / scope nodes by `getElementById`.
  late final String _scopeId;
  late final String _triggerId;
  late final String _panelId;

  /// Root wrapper id — a caller-supplied id wins (passthrough) and is the
  /// element the composed-path outside-click dismissal treats as "inside"
  /// (alongside [_panelId]); else the generated scope id. The internal
  /// [_triggerId] / [_panelId] stay generated (positioner / portal use).
  String get _effectiveScopeId => component.id ?? _scopeId;

  /// Resolved (collision-aware) placement reported by the unified
  /// [OverlayPositioner]'s `onPosition` callback — the side the panel
  /// actually landed on after any flip. Starts at the user-provided
  /// preference. Exposed to chrome via the panel's `data-placement`
  /// attribute so side-dependent styling (CSS arrows, etc.) can target
  /// the resolved side.
  late CorePopoverPlacement _resolvedPlacement = component.placement;

  /// The unified overlay positioning controller — measures the trigger +
  /// panel, applies flip/shift collision, reports the resolved origin via
  /// `onPosition` and the trigger rect via `onAnchorMeasured`, and owns
  /// the scroll/resize reposition listeners. Null while the popover is
  /// closed. Positioning-only: dismissal stays component-owned (the
  /// composed-path outside-click + Esc listeners below), so the engine's
  /// `closeOnOutsideClick` / `closeOnEsc` / `closeOnScroll` are all off.
  /// SSR-safe (the conditional import yields a no-op stub on the server).
  OverlayPositioner? _positioner;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// panel, fed back declaratively from [_positioner]'s `onPosition`
  /// callback. Null until the first frame resolves the position (the
  /// panel renders `opacity-0` during that window).
  double? _left;
  double? _top;

  /// Anchor (trigger) size snapshot — populated from [_positioner]'s
  /// `onAnchorMeasured` callback on every (re)computation. Drives the
  /// constraint policy (`anchorFixedSize` / `anchorMaxSize` /
  /// `anchorMinSize`) so the panel can match the trigger's width/height.
  double? _anchorWidth;
  double? _anchorHeight;

  /// Anchor origin, in the same viewport space `onPosition` reports.
  ///
  /// Kept alongside the size because the morph needs the trigger's *box*,
  /// not just how big it was.
  double? _anchorLeft;
  double? _anchorTop;

  /// The panel's own box, from the positioner's own measurement.
  double? _panelWidth;
  double? _panelHeight;

  /// The two bodies and the tempo, frozen at the moment all three
  /// measurements first landed.
  ///
  /// Frozen rather than live, and not as an optimisation: the clip
  /// restarts its runtime whenever these change, so live blobs would mean
  /// every scroll or resize reposition restarts the morph mid-flight — a
  /// panel that keeps leaving its trigger without ever arriving, for as
  /// long as the page is moving.
  _MorphLaunch? _morphLaunch;

  // DOM dismissal listener disposers — all null on SSR (`popover_dom_
  // stub.dart` returns no-op closures). Component-owned (not delegated to
  // the engine) so the composed-path outside-click survives jaspr's
  // microtask portal re-mount race; reposition listeners live on the
  // unified [OverlayPositioner] instead.
  void Function()? _disposeOutsideClick;
  void Function()? _disposeKeydown;

  /// Portal handle — set when the panel is mounted on the host
  /// overlay layer; null when the popover is closed or no
  /// [OverlayPortal] exists in the ancestor chain (test contexts
  /// without `CoUIWeb` fall back to inline rendering).
  OverlayController? _overlayController;
  int? _overlayToken;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coPopoverIdCounter++;
    _scopeId = 'co-popover-$id';
    _triggerId = 'co-popover-trigger-$id';
    _panelId = 'co-popover-panel-$id';
    _external = component.controller ?? PopoverController();
    _ownsExternal = component.controller == null;
    _external.attachHandlers(show: _handleOpen, close: _handleClose);
  }

  /// Unmounts the panel from any host overlay layer this state mounted
  /// it on. Safe to call multiple times.
  void _unmountPortal() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) {
      controller.unmount(token);
    }
    _overlayController = null;
    _overlayToken = null;
  }

  // ───────────────────────────── open/close ──────────────────────────

  void _handleOpen() {
    if (_isOpen) return;
    _exitTimer?.cancel();
    _exitTimer = null;
    setState(() {
      _isOpen = true;
      _closing = false;
      _resolvedPlacement = component.placement;
    });
    _external.notifyOpenChanged(isOpen: true);
    _attachDismissalListeners();
    // Mount the panel (hidden — `opacity-0` until placed), then position it
    // on the next frame. The `co-overlay-enter` keyframe plays on the
    // (re)inserted node once the origin commits (`positioned` true), so no
    // second flip-frame is needed — the animation runs on insertion
    // regardless of the portal node-recreation (see `resolveOverlayMotion`).
    scheduleNextFrame(() {
      if (!_isMounted || !_isOpen) return;
      _openPositioner();
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel
  /// and opens it — measures trigger + panel, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` plus the trigger rect via `onAnchorMeasured` (both
  /// declarative). Dismissal remains component-owned. Scroll dismissal is
  /// opt-in and restricted to the trigger's ancestors.
  void _openPositioner() {
    if (!_isMounted || !_isOpen) return;
    final config = resolvePopoverConfig(
      context,
      collision: component.collision,
      // The density the document carries now — the engine takes the
      // viewport padding as a number, so it is moved at the open it serves.
      density: DensityScope.currentDensity(),
      popoverStyle: component.popoverStyle,
    );
    _positioner?.dispose();
    _positioner = OverlayPositioner(
      triggerId: _triggerId,
      popoverId: _panelId,
      placement: component.placement,
      gap: config.gap,
      viewportPadding: config.viewportPadding,
      collision: config.collision,
      closeOnOutsideClick: false,
      closeOnEsc: false,
      closeOnScroll: component.closeOnScroll,
      triggerAncestorScrollOnly: component.closeOnScroll,
      onScrollClose: _handleClose,
      onPosition: (left, top, placement) {
        if (!_isMounted) return;
        setState(() {
          _left = left;
          _top = top;
          _resolvedPlacement = placement;
        });
        _armMorph();
      },
      onAnchorMeasured: (anchor) {
        if (!_isMounted) return;
        setState(() {
          _anchorWidth = anchor.width;
          _anchorHeight = anchor.height;
          _anchorLeft = anchor.left;
          _anchorTop = anchor.top;
        });
        _armMorph();
      },
      onPanelMeasured: (panel) {
        if (!_isMounted) return;
        setState(() {
          _panelWidth = panel.width;
          _panelHeight = panel.height;
        });
        _armMorph();
      },
    )..open();
  }

  /// Builds the launch once every measurement it needs has landed.
  ///
  /// Reads the surface style off the live document attribute rather than
  /// through `SurfaceStyleScope`: that scope is never mounted on Web, so
  /// `of(context)` answers `.defaultId` unconditionally and a gate written
  /// through it would compile, type-check, mirror the Flutter call exactly,
  /// and disable the morph forever. The attribute is also the correct read
  /// on its own terms — the morph runs on the client, and a value baked in
  /// Dart at build time goes stale on the next runtime style switch.
  void _armMorph() {
    if (_morphLaunch != null) return;

    final left = _left;
    final top = _top;
    final anchorLeft = _anchorLeft;
    final anchorTop = _anchorTop;
    final anchorWidth = _anchorWidth;
    final anchorHeight = _anchorHeight;
    final panelWidth = _panelWidth;
    final panelHeight = _panelHeight;
    if (left == null ||
        top == null ||
        anchorLeft == null ||
        anchorTop == null ||
        anchorWidth == null ||
        anchorHeight == null ||
        panelWidth == null ||
        panelHeight == null) {
      return;
    }

    // Avoid mounting a clip when motion is already disabled. The runtime
    // also observes the preference during a flight.
    if (prefersReducedMotion) return;

    // `CoreSurfaceRecipe.of` rather than a tuned resolve, correct only
    // while `CoreSurfaceTuning` carries no morph field. If one is added,
    // this has to go through the tuning or it silently bypasses it.
    final panelStyle = resolvePopover(
      context,
      popoverStyle: component.popoverStyle,
    ).style.panelStyle!;
    final spring = CoreSurfaceRecipe.of(
      panelStyle.surfaceStyle ?? SurfaceStyleScope.currentSurfaceStyle(),
    ).overlayMorph;
    if (spring == null) return;

    final radius = panelStyle.borderRadius!.topLeft;

    // Rebased onto the panel's own coordinates by the shared Core
    // builder, so the same subtraction on the Flutter half cannot drift
    // from this one. `onPosition` reports the outer panel div's
    // border-box origin verbatim and that div carries no transform, so
    // there is nothing to undo first.
    final bodies = morphBodies(
      triggerCenterX: anchorLeft + (anchorWidth / 2),
      triggerCenterY: anchorTop + (anchorHeight / 2),
      triggerWidth: anchorWidth,
      triggerHeight: anchorHeight,
      panelOriginX: left,
      panelOriginY: top,
      panelWidth: panelWidth,
      panelHeight: panelHeight,
      radius: radius,
    );

    setState(() {
      _morphLaunch = _MorphLaunch(
        anchor: bodies.anchor,
        panel: bodies.panel,
        spring: spring,
      );
    });
  }

  void _handleClose() {
    if (!_isOpen) return;
    _detachAllListeners();
    // Tear down the positioning controller (detaches its scroll/resize
    // listeners) immediately; the panel stays mounted for the fade-out.
    _positioner?.dispose();
    _positioner = null;
    _external.notifyOpenChanged(isOpen: false);
    component.onClose?.call();
    // Play the exit keyframe (`co-overlay-exit`, via `_closing`) while the
    // panel is still mounted, then unmount after the close window so the
    // user sees a fade-out rather than an instant disappearance.
    // `_closeDuration` was cached from the single `build` resolve (no
    // re-resolve here — the panel `Popup`'s `CorePopupStyle` is the single
    // source, shared with the menu family).
    // Cleared so the next open re-arms from fresh measurements rather
    // than replaying the flight the panel took last time, from wherever
    // its trigger was then.
    _morphLaunch = null;
    setState(() => _closing = true);
    _exitTimer?.cancel();
    _exitTimer = Timer(_closeDuration, () {
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

  void _handleToggle() {
    if (_isOpen) {
      _handleClose();
    } else {
      _handleOpen();
    }
  }

  // ─────────────────── component-owned dismissal ────────────────────

  /// Attaches the component-owned dismissal listeners — document
  /// composed-path outside-click + `Escape` keydown. Positioning /
  /// reposition listeners live on the unified [OverlayPositioner]; only
  /// dismissal stays here so the composed-path check survives jaspr's
  /// microtask-based portal re-mount race (the engine's contains-based
  /// outside-click would re-fire during that window and close the panel
  /// spuriously).
  void _attachDismissalListeners() {
    if (component.dismissOnOutsideTap) {
      _disposeOutsideClick = registerDocumentClickListener(
        () {
          if (!_isOpen) return;
          _handleClose();
        },
        // The trigger lives inside the popover's own `_scopeId`, but
        // the panel has been portaled into [OverlayHost] — it is
        // *not* a descendant of `_scopeId` anymore. Listing both
        // makes a click on either side count as "inside".
        //
        // The composed-path scan (inside the listener) keeps the check
        // correct even when the click lands on a deeply nested node that
        // has no id of its own (calendar day cells, button content
        // `<span>`s, …) and survives the portal re-mount race.
        containerIds: () => [_effectiveScopeId, _panelId],
      );
    }
    if (component.dismissOnEscape) {
      _disposeKeydown = registerDocumentKeydownListener((key) {
        if (!_isOpen) return;
        if (key == 'Escape') _handleClose();
      });
    }
  }

  void _detachAllListeners() {
    _disposeOutsideClick?.call();
    _disposeOutsideClick = null;
    _disposeKeydown?.call();
    _disposeKeydown = null;
  }

  Map<String, EventCallback> _triggerEvents() {
    return switch (component.openTrigger) {
      .click => {'click': (_) => _handleToggle()},
      .hover => {
        'mouseenter': (_) => _handleOpen(),
        'mouseleave': (_) => _handleClose(),
      },
      .focus => {'focus': (_) => _handleOpen(), 'blur': (_) => _handleClose()},
      .manual => const {},
    };
  }

  /// Mounts / updates / unmounts the panel on [controller] via a
  /// microtask so the controller's listener (the host's `setState`)
  /// runs after the current build commits. `entry == null` clears the
  /// slot (popover closed); non-null re-uses the existing token via
  /// [OverlayController.update] when one exists, or [mount]s a fresh
  /// token otherwise.
  void _schedulePortalSync(OverlayController controller, Component? entry) {
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
        _overlayToken = controller.mount(
          layer: .popover,
          panel: entry,
          modal: component.modal,
        );
      } else {
        controller.update(token, entry);
      }
    });
  }

  @override
  void didUpdateComponent(covariant Popover oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      _external.detachHandlers();
      if (_ownsExternal) {
        _external.dispose();
      }
      _external = component.controller ?? PopoverController();
      _ownsExternal = component.controller == null;
      _external.attachHandlers(show: _handleOpen, close: _handleClose);
    }
    if (oldComponent.placement != component.placement) {
      _resolvedPlacement = component.placement;
    }
    if (oldComponent.closeOnScroll != component.closeOnScroll &&
        _isOpen &&
        !_closing) {
      scheduleMicrotask(() {
        if (_isMounted && _isOpen && !_closing) _openPositioner();
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _exitTimer?.cancel();
    _exitTimer = null;
    _detachAllListeners();
    _positioner?.dispose();
    _positioner = null;
    _unmountPortal();
    _external.detachHandlers();
    if (_ownsExternal) {
      _external.dispose();
    }
    super.dispose();
  }

  // ───────────────────────────── render ────────────────────────────

  @override
  Component build(BuildContext context) {
    // Single resolve — chrome + the merged panel style (carrying the
    // open/close durations) all in one pass. Motion is applied by the
    // shared `resolveOverlayMotion` below (keyframes), not baked into the
    // resolver.
    final resolved = resolvePopover(
      context,
      left: _left,
      top: _top,
      anchorWidth: _anchorWidth,
      anchorHeight: _anchorHeight,
      widthConstraint: component.widthConstraint ?? .flexible,
      heightConstraint: component.heightConstraint ?? .flexible,
      popoverStyle: component.popoverStyle,
    );
    // Cache the chained close duration from this single resolve so
    // `_handleClose` sizes the exit timer without resolving again.
    _closeDuration = resolved.style.closeAnimationDuration!;

    final triggerNode = div(
      [component.trigger],
      id: _triggerId,
      classes: resolved.trigger.className,
      styles: resolved.trigger.inlineStyles,
      attributes: {
        'aria-haspopup': 'dialog',
        'aria-expanded': _isOpen ? 'true' : 'false',
        // Which surface the expanded state is about. Only while open: the
        // panel is not in the document otherwise, and a reference to an
        // id that does not exist is worse than none.
        if (_isOpen) 'aria-controls': _panelId,
      },
      events: _triggerEvents(),
    );

    // The panel nests three divs so the unified `OverlayPositioner`
    // measures a stable, scale-free layout box and the open/close scale
    // motion stays isolated from positioning (same shape as the menu
    // family: outer-measured → motion box → chrome bubble).
    //
    // - outer (`resolved.panel`): carries `id: _panelId`, `position:
    //   fixed`, the engine-resolved `top` / `left`, and the anchor-driven
    //   constraint declarations (`width` / `max-height` etc.). No scale —
    //   so `getBoundingClientRect` reports the bubble's true layout size
    //   for the positioner / collision.
    // - motion box: the shared `resolveOverlayMotion` `co-overlay-enter` /
    //   `co-overlay-exit` keyframes (scale 0.9 → 1.0 + fade). The keyframe
    //   plays on the (re)inserted node, surviving the portal's node
    //   re-creation (a transition would not). The scale lives here, off the
    //   id-carrying outer box, so it does not skew the measured rect.
    // - inner (`resolved.bubble`): `Popup` box chrome only. `data-placement`
    //   exposes the engine-resolved side for side-dependent CSS.
    Component? panelNode;
    if (_isOpen) {
      final motion = resolveOverlayMotion(
        positioned: _left != null && _top != null,
        closing: _closing,
        openDuration: resolved.style.openAnimationDuration!,
        closeDuration: resolved.style.closeAnimationDuration!,
        morphing: _morphLaunch != null,
      );
      panelNode = div(
        [
          div(
            [
              div(
                [component.content],
                classes: resolved.bubble.className,
                styles: resolved.bubble.inlineStyles,
                attributes: {
                  'role': 'dialog',
                  'data-placement': _resolvedPlacement.name,
                },
              ),
            ],
            classes: motion.className,
            styles: motion.inlineStyles,
          ),
        ],
        id: _panelId,
        classes: resolved.panel.className,
        styles: resolved.panel.inlineStyles,
        attributes: TopLayer.attributesFor(context),
      );
      final launch = _morphLaunch;
      if (launch != null) {
        // Wrapped, not nested: the clip renders its child unchanged and
        // writes `clip-path` straight onto the element carrying
        // `_panelId` — the outer div, which is the only one that is both
        // transform-free and addressable. The middle div is scaled (the
        // clip would scale with it) and the inner one already has
        // `overflow-hidden` plus a radius to compound with.
        panelNode = LiquidMorphClip(
          elementId: _panelId,
          anchor: launch.anchor,
          panel: launch.panel,
          spring: launch.spring,
          child: panelNode,
        );
      }
    }

    Component? backdropNode;
    if (_isOpen && component.modal) {
      backdropNode = div(
        const [],
        classes: resolved.backdrop.className,
        styles: resolved.backdrop.inlineStyles,
        // The scrim is `fixed inset-0`, so it needs the viewport as its
        // containing block as much as the panel does. Promoted before the
        // panel (document order), it stays beneath it in the top layer.
        attributes: {...TopLayer.attributesFor(context), 'aria-hidden': 'true'},
        events: component.dismissOnOutsideTap
            ? {'click': (_) => _handleClose()}
            : const {},
      );
    }

    // The assistive-technology twin of the scrim click, offered under the
    // scrim's own condition: a modal surface that closes when clicked away.
    // The page behind it is `inert` and the scrim `aria-hidden`, so a
    // screen-reader user has nothing else to activate (the Flutter seat
    // attaches `Semantics(onDismiss:)` to the same surfaces).
    final dismissNode =
        _isOpen && component.modal && component.dismissOnOutsideTap
        ? modalDismissControl(context, onDismiss: _handleClose)
        : null;

    // Sync the panel + backdrop to the root [OverlayHost]'s popover
    // layer when one is available in the ancestor chain. Sync runs as
    // a microtask so we don't mutate the controller (and trigger its
    // listeners' setState) during this widget's build.
    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      final entries = [?backdropNode, ?panelNode, ?dismissNode];
      final entry = entries.isEmpty
          ? null
          : entries.length == 1
          ? entries.first
          : div(entries, classes: WebLayout.contents);
      _schedulePortalSync(portal.controller, portal.capture(context, entry));
    } else if (_overlayController != null) {
      // We previously had a portal ancestor but it's gone — clean up.
      _unmountPortal();
    }

    return div(
      [
        triggerNode,
        if (!portalled) ?backdropNode,
        if (!portalled) ?panelNode,
        if (!portalled) ?dismissNode,
      ],
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Popover.withStyle` extension —
/// merges a [CorePopoverStyle] patch into [Popover.popoverStyle] via
/// the existing [Popover.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePopoverStyle.merge` right-side-wins semantics).
extension PopoverStyleChain on Popover {
  /// Returns a copy of this [Popover] with [patch] merged into
  /// [popoverStyle] (patch fields win on conflict).
  Popover withStyle(CorePopoverStyle patch) => copyWith(
    popoverStyle: (popoverStyle ?? const CorePopoverStyle()).merge(patch),
  );
}

/// The two bodies and the tempo a morph launches with.
///
/// A value type so the component can hold "not armed yet" as null rather
/// than as six half-populated fields.
@immutable
class _MorphLaunch {
  const _MorphLaunch({
    required this.anchor,
    required this.panel,
    required this.spring,
  });

  final CoreMorphBlob anchor;
  final CoreMorphBlob panel;
  final CoreMorphSpring spring;
}
