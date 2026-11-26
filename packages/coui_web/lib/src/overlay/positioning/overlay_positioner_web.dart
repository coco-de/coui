/// Web implementation of [OverlayPositioner] — the public orchestrator
/// for the floating (popover) engine.
///
/// Ties together:
///   - [computeOverlayPosition] / [resolveOverlayCollision] for the pure
///     geometry (in `positioner.dart` and `collision.dart`),
///   - [OverlayOutsideClick] for document-level dismissal,
///   - [OverlayScrollTracker] for scroll/resize driven updates,
///   - [OverlayPositionRegistry] so at most one popover is open at a time.
///
/// The popover element is **portaled by the consumer** into the root
/// `OverlayHost` layer (via `OverlayController.mount`) — this
/// controller does not own a portal. It assumes the panel is already in
/// the document and only *positions* it (flip/shift collision) and wires
/// the dismissal / reposition listeners.
///
/// Consumer components (Tooltip, Select, DatePicker, …) construct a
/// [OverlayPositioner] with the **DOM ids** of their trigger and popover
/// elements, and invoke [open] / [close] from their state machine; this
/// class resolves the elements via `getElementById` internally and hides
/// every DOM detail. Passing ids (not `HTMLElement`s) keeps the consumer
/// SSR-safe — `co_*.dart` must never import `package:web`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_feed_web.dart';
import 'package:coui_web/src/overlay/positioning/collision.dart';
import 'package:coui_web/src/overlay/positioning/fit.dart';
import 'package:coui_web/src/overlay/positioning/outside_click_web.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';
import 'package:coui_web/src/overlay/positioning/registry.dart';
import 'dart:js_interop';

import 'package:coui_web/src/overlay/positioning/scroll_tracker_web.dart';
import 'package:web/web.dart' as web;

/// Web orchestrator for a single floating (popover) panel.
class OverlayPositioner implements OverlayPositionEntry {
  /// Creates a [OverlayPositioner].
  ///
  /// [triggerId] / [popoverId] are the DOM ids of the anchor and the
  /// floating panel. They are resolved lazily via `getElementById` at
  /// [open] / [update] time, so the panel element may be inserted into the
  /// document only when it becomes visible.
  OverlayPositioner({
    required String triggerId,
    required String popoverId,
    this.placement = CorePopoverStyle.defaultDropdownPlacement,
    this.gap = CorePopoverStyle.defaultFormPopoverPlacementOffset,
    this.viewportPadding = CorePopoverStyle.defaultViewportPadding,
    this.collision = CorePopoverStyle.defaultCollision,
    this.closeOnOutsideClick = true,
    this.closeOnEsc = true,
    this.closeOnScroll = CorePopoverStyle.defaultCloseOnScroll,
    this.triggerAncestorScrollOnly = false,
    this.onScrollClose,
    this.fitViewportHeight = false,
    this.measureAnchor,
    this.measureTopInset,
    this.onPosition,
    this.onFit,
    this.onAnchorMeasured,
    this.onPanelMeasured,
    this.onClose,
  }) : _triggerId = triggerId,
       _popoverId = popoverId;

  /// Preferred placement of the popover relative to its trigger.
  final CorePopoverPlacement placement;

  /// Gap between the trigger and the popover along the primary axis.
  final double gap;

  /// Minimum distance between the popover and each viewport edge when
  /// [CorePopoverCollision.shift] is applied. Per-side values so the
  /// host can reserve space for fixed headers / banners / safe-area
  /// insets.
  final CoreEdgeInsets viewportPadding;

  /// Collision policy applied when the popover overflows the viewport.
  final Set<CorePopoverCollision> collision;

  /// Whether clicking outside the popover dismisses it.
  final bool closeOnOutsideClick;

  /// Whether the `Escape` key dismisses the popover.
  final bool closeOnEsc;

  /// Whether scrolling the trigger's ancestors dismisses the popover.
  final bool closeOnScroll;

  /// Restrict scroll events to the trigger's ancestors and viewport.
  final bool triggerAncestorScrollOnly;

  /// Handles a scroll dismissal instead of the positioner's default close.
  final void Function()? onScrollClose;

  /// Whether the panel is held to the room the viewport leaves it
  /// ([CoreOverlayFit]) — the Flutter engine's `fitViewportHeight`.
  ///
  /// A panel taller than that room is capped to it ([onFit] reports the cap)
  /// and placed at the top of it, so a list in the panel scrolls instead of
  /// running off the screen. A panel that fits is placed exactly as without
  /// the flag. The panel's scroller — the element a host marks with
  /// [kOverlayFitScrollerClass] — is what tells the positioner how much more
  /// a capped panel holds than it shows.
  final bool fitViewportHeight;

  /// Measures the anchor box, in viewport coordinates, in place of the
  /// trigger element's own box — for an anchor that is no element, such as a
  /// run of selected text (the Flutter engine's `anchorRect`). The trigger
  /// element is still what the dismissal and scroll listeners are attached
  /// around. Returning `null` — the anchor is gone for now — leaves the panel
  /// where it was last placed.
  final OverlayRect? Function()? measureAnchor;

  /// Measures, each time the panel is placed, how far from the top of the
  /// viewport the room for the panel begins — for a host that keeps the
  /// panel off something above the anchor: a toolbar floating over a
  /// selection stays below the editor's own toolbar (the Flutter engine's
  /// `margin`, moved with the anchor). The larger of it and
  /// [viewportPadding]'s top is the room's top edge, so the collision rule
  /// flips a panel that does not fit above the anchor within that room.
  /// Null leaves the room the viewport's.
  final double Function()? measureTopInset;

  /// Called with the flip/shift-resolved viewport-space `(left, top)`
  /// origin **and** the resolved [CorePopoverPlacement] (the side the
  /// panel actually landed on after any flip) every time the position is
  /// (re)computed. The consumer applies it **declaratively** (e.g.
  /// `setState` → resolver emits `top`/`left` into the panel's inline
  /// styles, and reads `placement` for side-dependent chrome such as the
  /// transform-origin / arrow direction) so the position survives Jaspr's
  /// vdom reconciliation — the controller never writes DOM styles itself.
  final void Function(double left, double top, CorePopoverPlacement placement)?
  onPosition;

  /// Called with the height the panel is capped to, or `null` when it is not
  /// capped, each time the position is (re)computed — only for a positioner
  /// with [fitViewportHeight].
  ///
  /// Declarative like [onPosition]: the consumer stores it beside `(left,
  /// top)` and emits it as the panel's `max-height` (with the content
  /// scrolling), so a re-render keeps it.
  final void Function(double? maxHeight)? onFit;

  /// Optional callback fired with the trigger's measured viewport rect on
  /// every (re)computation. Consumers that size the panel relative to the
  /// anchor (e.g. a Select dropdown matching the trigger's width via
  /// `anchorFixedSize` / `anchorMaxSize` / `anchorMinSize`) read this
  /// instead of re-measuring the trigger themselves — the positioner is
  /// the single measurement source.
  final void Function(OverlayRect anchor)? onAnchorMeasured;

  /// Optional callback fired with the panel's own measured viewport rect.
  ///
  /// The symmetric half of [onAnchorMeasured]. `update` already measures
  /// this to resolve collisions and threw it away; a consumer that needs
  /// the panel's box — to carve a shape in the panel's own coordinates,
  /// say — would otherwise measure the same element a second time and get
  /// a second answer.
  final void Function(OverlayRect panel)? onPanelMeasured;

  /// Optional callback fired when the popover closes.
  final void Function()? onClose;

  final String _triggerId;
  final String _popoverId;

  web.HTMLElement? _popover;
  OverlayOutsideClick? _outsideClick;
  OverlayScrollTracker? _scrollTracker;
  bool _isOpen = false;

  /// The cap last reported through [onFit], so the next measurement knows
  /// whether the panel it reads is held.
  double? _fitCap;

  /// Whether the popover is currently open.
  bool get isOpen => _isOpen;

  /// Opens the popover: registers exclusivity, computes position, and
  /// attaches scroll / outside-click listeners. Idempotent. No-op if
  /// either element is absent from the DOM (the panel must already be
  /// portaled into the host overlay layer by the consumer).
  void open() {
    if (_isOpen) return;
    final trigger = _resolve(_triggerId);
    final popover = _resolve(_popoverId);
    if (trigger == null || popover == null) return;
    _popover = popover;
    OverlayPositionRegistry.open(this);
    update();
    if (closeOnOutsideClick || closeOnEsc) {
      _outsideClick = OverlayOutsideClick(
        trigger: trigger,
        popover: popover,
        // `close` is the canonical verb for the controller lifecycle; the
        // `handle*` lint applies to UI event handlers, not lifecycle tearoffs.
        onDismiss: () => close(),
        listenEsc: closeOnEsc,
      )..attach();
    }
    _scrollTracker = OverlayScrollTracker(
      trigger: trigger,
      popover: popover,
      onChange: () => update(),
      closeOnScroll: closeOnScroll,
      onScrollClose: onScrollClose ?? () => close(),
      triggerAncestorScrollOnly: triggerAncestorScrollOnly,
      // A held panel follows the viewport it is held to, and scrolls its own
      // rows without that being the trigger moving.
      trackViewportResize: fitViewportHeight,
      ignorePanelScroll: fitViewportHeight,
    )..attach();
    _isOpen = true;
  }

  /// Closes the popover: tears down listeners and invokes [onClose].
  /// Idempotent. The panel itself is unmounted from the host overlay
  /// layer by the consumer (via `OverlayController.unmount`).
  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    _outsideClick?.detach();
    _outsideClick = null;
    _scrollTracker?.detach();
    _scrollTracker = null;
    _popover = null;
    _fitCap = null;
    OverlayPositionRegistry.close(this);
    onClose?.call();
  }

  /// Recomputes and reapplies the popover's position. Called internally
  /// by scroll / resize events, and callable externally if content changes
  /// the popover's size.
  void update() {
    final trigger = _resolve(_triggerId);
    final popover = _popover;
    if (trigger == null || popover == null) return;
    final measure = measureAnchor;
    final triggerRect = measure == null ? _measure(trigger) : measure();
    if (triggerRect == null) return;
    onAnchorMeasured?.call(triggerRect);
    final popoverRect = _measure(popover);
    // The panel can measure 0×0 when [update] runs in the same frame
    // the panel was portaled into the overlay host (e.g. a tooltip
    // opening while an adjacent one is still tearing down delays the
    // mount microtask past the consumer's next-frame open). Emitting a
    // position from a zero rect drops the centre-alignment correction
    // (the panel lands half its width off the anchor) — remeasure next
    // frame instead.
    if (popoverRect.width == 0 && popoverRect.height == 0) {
      final handler = ((double _) {
        if (_isOpen || identical(_popover, popover)) update();
      }).toJS;
      final _ = web.window.requestAnimationFrame(handler);
      return;
    }
    // After the zero-rect guard, so a consumer never sees a box that was
    // measured before the panel was mounted.
    onPanelMeasured?.call(popoverRect);
    final topInset = measureTopInset?.call() ?? 0;
    // On a viewport a fold splits, the room is the anchor's segment.
    final viewport = overlayViewportWithinFold(
      viewport: OverlayViewport(
        width: web.window.innerWidth.toDouble(),
        height: web.window.innerHeight.toDouble(),
        paddingLeft: viewportPadding.left,
        paddingTop: topInset > viewportPadding.top
            ? topInset
            : viewportPadding.top,
        paddingRight: viewportPadding.right,
        paddingBottom: viewportPadding.bottom,
      ),
      fold: WebFoldFeed.read(),
      anchor: triggerRect,
    );

    // The height the panel would have if nothing held it: the box the
    // browser measured, plus what a held panel's scroller holds beyond what it
    // shows. (The collision below keeps working on the measured box. For a
    // held panel that is the room; a panel measured free for the first time
    // is measured again once the cap has been rendered.)
    var naturalHeight = popoverRect.height;
    if (fitViewportHeight) {
      final room = CoreOverlayFit.availableExtent(
        viewport: viewport.height,
        paddingBefore: viewport.paddingTop,
        paddingAfter: viewport.paddingBottom,
      );
      naturalHeight = overlayNaturalHeight(
        measuredHeight: popoverRect.height,
        overflow: _scrollerOverflow(popover),
        room: room,
        wasCapped: _fitCap != null,
      );
    }

    final resolution = resolveOverlayCollision(
      trigger: triggerRect,
      popover: OverlaySize(
        width: popoverRect.width,
        height: popoverRect.height,
      ),
      placement: placement,
      viewport: viewport,
      gap: gap,
      policy: collision,
    );

    var top = resolution.position.top;
    if (fitViewportHeight) {
      final fit = CoreOverlayFit.fit(
        viewport: viewport.height,
        paddingBefore: viewport.paddingTop,
        paddingAfter: viewport.paddingBottom,
        start: top,
        extent: naturalHeight,
      );
      top = fit.start;
      final cap = fit.capped ? fit.extent : null;
      _fitCap = cap;
      // The panel is about to be re-rendered at the new height. The tracker's
      // `ResizeObserver` hears that and measures again — the cap is a
      // function of the viewport alone, so the second pass reports the same
      // cap and the loop ends there.
      onFit?.call(cap);
    }

    // Declarative output — the consumer writes these into the panel's
    // inline styles via its own state, so the position is owned by Jaspr's
    // vdom (not an imperative DOM write that a re-render would clobber).
    onPosition?.call(resolution.position.left, top, resolution.placement);
  }

  /// How much more the panel's scroller holds than it shows — zero when no
  /// element in the panel is marked as the scroller, or nothing scrolls.
  double _scrollerOverflow(web.HTMLElement popover) {
    final scroller = popover.querySelector('.$kOverlayFitScrollerClass');
    if (scroller == null) return 0;
    final overflow = scroller.scrollHeight - scroller.clientHeight;

    return overflow > 0 ? overflow.toDouble() : 0;
  }

  /// Releases all listeners and resets internal DOM state.
  ///
  /// Should be called from the state's `dispose()` or when the trigger
  /// element is unmounted; after [dispose] the controller should not be
  /// re-opened.
  void dispose() {
    close();
  }

  @override
  void requestClose() {
    close();
  }

  /// Resolves a DOM id to its [web.HTMLElement], or null if absent.
  web.HTMLElement? _resolve(String id) {
    final element = web.document.getElementById(id);
    return element == null ? null : element as web.HTMLElement;
  }

  OverlayRect _measure(web.Element element) {
    final rect = element.getBoundingClientRect();
    return OverlayRect(
      left: rect.left.toDouble(),
      top: rect.top.toDouble(),
      width: rect.width.toDouble(),
      height: rect.height.toDouble(),
    );
  }
}
