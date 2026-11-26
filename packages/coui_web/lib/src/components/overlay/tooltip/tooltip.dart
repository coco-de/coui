import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Enter / exit motion — mirrors Flutter `FixedTooltipOverlayHandler`
/// + `PopoverOverlayWidget` so both platforms animate identically.
///
/// - **Open**: 150 ms (`AnimationConstants.short`) with `linear` curve
///   (Flutter uses `Curves.linear` for the open phase).
/// - **Close**: 100 ms wall-clock with `Interval(0, 2/3)` → only the
///   first ~67 ms produces visible motion. CSS `transition-timing-
///   function` can't express interval shaping, so we shorten the
///   emitted `transition-duration` to 2/3 of the close window — same
///   trick `co_popover.dart` uses.
/// - **Scale range**: 0.9 ↔ 1.0 (matches the Flutter popover
///   collapsed / open scale extents). The legacy CSS class `scale-95`
///   was 0.95 — too subtle compared to Flutter's 0.9 and gave the
///   wrong "Web feels different" impression noted in PR review.
const Duration _kOpenDuration =
    CoreTooltipContract.defaultOpenAnimationDuration;

/// Full close duration — what the timer waits for before unmounting
/// the panel from the DOM.
const Duration _kCloseDuration =
    CoreTooltipContract.defaultCloseAnimationDuration;

/// Visible portion of the close transition. Mirrors Flutter
/// `Interval(0, 2/3)` close shaping — Flutter's animation drives the
/// scale + fade only during the first 2/3 of the wall-clock and
/// holds the closed state for the remaining 1/3 before the entry is
/// removed. CSS replicates this by shortening `transition-duration`.
const Duration _kCloseVisibleDuration = Duration(
  milliseconds: CoreDuration.instant * 2 ~/ 3,
);

/// Process-level counter used to mint unique scope ids so multiple
/// `Tooltip` instances on the same page don't collide on
/// `getElementById` lookups.
int _coTooltipIdCounter = 0;

/// Unified cross-platform tooltip for CoUI Web.
///
/// Renders a hover-triggered floating bubble anchored to a trigger
/// component. The bubble is portaled into the root `OverlayHost`
/// tooltip layer so it is no longer clipped by ancestor
/// `overflow: hidden` or `transform` containers — matching the
/// behaviour of the new `Popover` portal pattern.
///
/// The bubble fades + scales in on hover-enter and fades out on
/// hover-leave, mirroring the `Popover` enter / exit transition
/// (opacity + scale). Open uses a 150 ms timing, close uses 100 ms,
/// matching `CorePopoverStyle.defaultOpenAnimationDuration` /
/// `defaultCloseAnimationDuration`.
///
/// Per Epic #1302, all panel-chrome / dimensional / surface-effect
/// overrides flow through [tooltipStyle]
/// (`CoreTooltipStyle`). Semantic [position] stays
/// as a top-level component parameter (원칙 6/7).
///
/// Mirrors Flutter `Tooltip` 1:1 — same parameter names, same
/// semantics.
///
/// surface:functional — the overlay positioner anchors it over whatever it
/// describes.
class Tooltip extends UiStatefulComponent
    implements CoreTooltipContract<Component> {
  /// Creates a [Tooltip].
  const Tooltip({
    required this.child,
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
    this.message = '',
    this.tooltipChild,
    this.position = CoreTooltipPosition.top,
    this.waitDuration = CoreTooltipContract.defaultWaitDuration,
    this.showDuration = CoreTooltipContract.defaultShowDuration,
    this.minDuration,
    this.tooltipStyle,
  });

  @override
  final String message;

  @override
  final Component? tooltipChild;

  @override
  final Component child;

  @override
  final CoreTooltipPosition position;

  @override
  final Duration? waitDuration;

  @override
  final Duration? showDuration;

  @override
  final Duration? minDuration;

  @override
  final CoreTooltipStyle? tooltipStyle;

  /// Returns a copy of this [Tooltip] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Tooltip copyWith({
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
    String? message,
    Component? tooltipChild,
    CoreTooltipPosition? position,
    Duration? waitDuration,
    Duration? showDuration,
    Duration? minDuration,
    CoreTooltipStyle? tooltipStyle,
    Component? child,
  }) {
    return Tooltip(
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
      message: message ?? this.message,
      tooltipChild: tooltipChild ?? this.tooltipChild,
      position: position ?? this.position,
      waitDuration: waitDuration ?? this.waitDuration,
      showDuration: showDuration ?? this.showDuration,
      minDuration: minDuration ?? this.minDuration,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Tooltip> createState() => _TooltipState();
}

/// Chain sugar mirroring the Flutter `Tooltip.withStyle` extension —
/// merges a [CoreTooltipStyle] patch into [Tooltip.tooltipStyle] via the
/// existing [Tooltip.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTooltipStyle.merge` right-side-wins semantics).
extension TooltipStyleChain on Tooltip {
  /// Returns a copy of this [Tooltip] with [patch] merged into
  /// [tooltipStyle] (patch fields win on conflict).
  Tooltip withStyle(CoreTooltipStyle patch) => copyWith(
    tooltipStyle: (tooltipStyle ?? const CoreTooltipStyle()).merge(patch),
  );
}

class _TooltipState extends State<Tooltip> {
  bool _isOpen = false;
  bool _isMounted = false;

  /// Mirrors [_isOpen] but lags by one animation frame on enter and
  /// by [_kCloseDuration] on exit, driving the panel's
  /// `opacity` / `scale` class swap so enter/exit transitions run on
  /// every hover cycle. `_isOpen` controls whether the panel is in
  /// the DOM at all; `_didEnter` controls the visual open / closed
  /// state.
  bool _didEnter = false;

  /// Pending exit timer — non-null while the panel is animating out
  /// after [_handleMouseLeave]. Cancelled if the tooltip is reopened
  /// before the animation completes (common when the user pans the
  /// mouse across the trigger).
  Timer? _exitTimer;

  /// Pending hover-wait timer — non-null while the cursor rests on the
  /// trigger but the panel hasn't opened yet (Flutter `waitDuration`
  /// parity). Cancelled when the cursor leaves before it fires.
  Timer? _enterTimer;

  /// Wall-clock (epoch ms) of the last cursor arrival on the trigger, or
  /// null once the cursor has left. Read on leave to clamp the exit
  /// delay against `minDuration` — the same measurement point the
  /// Flutter `Hover` uses (pointer enter, not panel open), so a quick
  /// leave holds the bubble for the same remainder on both platforms.
  int? _enterTimestampMs;

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

  /// Flip-resolved placement reported by the positioner — drives which
  /// bubble edge carries the tail. Starts from the widget's requested
  /// position until the first frame resolves.
  CorePopoverPlacement? _resolvedPlacement;

  /// The unified overlay positioning controller — measures the trigger +
  /// panel, applies flip/shift collision, and reports the resolved origin
  /// via `onPosition`. Owns the scroll/resize listeners. Null while the
  /// tooltip is closed. SSR-safe (the conditional import yields a no-op
  /// stub on the server).
  OverlayPositioner? _floating;

  /// Portal handle — set when the panel is mounted on the host
  /// overlay layer; null when the tooltip is hidden or no
  /// [OverlayPortal] exists in the ancestor chain (test contexts
  /// without `CoUIWeb` fall back to inline rendering).
  OverlayController? _overlayController;
  int? _overlayToken;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coTooltipIdCounter++;
    _triggerId = 'co-tooltip-trigger-$id';
    _panelId = 'co-tooltip-panel-$id';
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

  // ───────────────────────────── hover ──────────────────────────────

  void _handleMouseEnter(web.MouseEvent event) {
    // Resolved in the handler (not cached from `build`) so a timing
    // override that changed since the last paint is honoured on this
    // very hover — the Web `Hover` reads its timings the same way.
    final timing = resolveTooltipTiming(
      waitDuration: component.waitDuration,
      showDuration: component.showDuration,
      minDuration: component.minDuration,
    );
    _enterTimestampMs = DateTime.now().millisecondsSinceEpoch;
    if (_isOpen) {
      // Re-entered the trigger while the exit fade is still running —
      // cancel the pending unmount and fade straight back in (the
      // `_exitTimer` doc promises this; without the cancel the panel
      // vanishes under the resting cursor).
      if (_exitTimer != null) {
        _exitTimer!.cancel();
        _exitTimer = null;
        setState(() => _didEnter = true);
        _openFloating();
      }
      return;
    }
    // Flutter-parity hover wait (`Tooltip.waitDuration`): open only
    // after the cursor rests on the trigger, so gliding across adjacent
    // tooltipped items opens nothing in passing.
    _enterTimer?.cancel();
    _enterTimer = Timer(Duration(milliseconds: timing.waitDurationMs), () {
      _enterTimer = null;
      if (!_isMounted || _isOpen) return;
      _openSequence();
    });
  }

  void _openSequence() {
    setState(() {
      _isOpen = true;
      // Mount the panel in its closed visual state so the open-state
      // class swap below triggers the enter transition. Without this
      // gap the panel commits already at `opacity-100 scale-100` and
      // the enter animation is invisible.
      _didEnter = false;
    });
    // Wait one paint frame so the panel commits with its closed-state
    // classes (`opacity-0 scale-90`) and the browser registers them as
    // the transition's start state. The portal-sync microtask has
    // mounted the panel into the host overlay layer by now, so the
    // `OverlayPositioner` can resolve + measure it. Swapping to the
    // open-state class kicks off the enter transition.
    scheduleNextFrame(() {
      if (!_isMounted || !_isOpen) return;
      setState(() => _didEnter = true);
      _openFloating();
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel
  /// and opens it — measures trigger + panel, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` (declarative). Hover-driven, so click / esc dismissal
  /// is off; scrolling repositions (does not close).
  void _openFloating() {
    if (!_isMounted || !_isOpen) return;
    final config = resolveTooltipConfig(
      context,
      position: component.position,
      tooltipStyle: component.tooltipStyle,
    );
    _floating?.dispose();
    _floating = OverlayPositioner(
      triggerId: _triggerId,
      popoverId: _panelId,
      placement: config.placement,
      gap: config.gap,
      closeOnOutsideClick: false,
      closeOnEsc: false,
      closeOnScroll: false,
      // The resolved placement picks the bubble edge that carries the
      // tail, so flips keep the tail pointing at the trigger.
      onPosition: (left, top, placement) {
        if (!_isMounted) return;
        setState(() {
          _left = left;
          _top = top;
          _resolvedPlacement = placement;
        });
      },
    )..open();
  }

  void _handleMouseLeave(web.MouseEvent event) {
    final timing = resolveTooltipTiming(
      waitDuration: component.waitDuration,
      showDuration: component.showDuration,
      minDuration: component.minDuration,
    );
    final enterTimestampMs = _enterTimestampMs;
    _enterTimestampMs = null;
    // Cursor left before the hover wait elapsed — never open.
    _enterTimer?.cancel();
    _enterTimer = null;
    if (!_isOpen) return;
    // Flutter-parity linger (`Hover` reports un-hover only after
    // `showDuration`): the bubble stays fully visible for the linger
    // window before the exit fade starts, so leaving briefly — or
    // handing off to an adjacent tooltipped item — doesn't blink.
    //
    // `minDuration` clamps that window from below, mirroring the Flutter
    // `Hover` reverse-duration calculation: a leave before the minimum
    // has elapsed since the cursor arrived holds the bubble for the
    // remainder instead of the (possibly shorter) linger.
    final elapsedMs = enterTimestampMs == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - enterTimestampMs;
    final exitDelayMs = elapsedMs < timing.minDurationMs
        ? timing.minDurationMs - elapsedMs
        : timing.showDurationMs;
    _exitTimer?.cancel();
    _exitTimer = Timer(Duration(milliseconds: exitDelayMs), () {
      if (!_isMounted || !_isOpen) return;
      _startExit();
    });
  }

  void _startExit() {
    // Tear down the positioning controller (detaches its scroll/resize
    // listeners); the panel stays mounted for the fade-out.
    _floating?.dispose();
    _floating = null;
    // Trigger the exit transition by flipping the visual state to
    // closed while the panel is still mounted. The panel itself is
    // taken out of the DOM after the animation completes so the
    // user sees a fade-out rather than an instant disappearance.
    setState(() => _didEnter = false);
    _exitTimer?.cancel();
    // Wall-clock duration matches Flutter's `closeAnimationDuration`
    // (100 ms) so the entry stays mounted for the same total time on
    // both platforms. The visible motion lasts only 2/3 of that
    // (`_kCloseVisibleDuration`) — see the const-doc on
    // `_kCloseVisibleDuration` for the `Interval(0, 2/3)` parity
    // rationale; the timer here is the *unmount* timer, the visible
    // motion happens via the `transition-duration` declaration in
    // `build()`.
    _exitTimer = Timer(_kCloseDuration, () {
      if (!_isMounted) return;
      setState(() {
        _isOpen = false;
        _left = null;
        _top = null;
      });
      _unmountPortal();
      _exitTimer = null;
    });
  }

  /// Mounts / updates / unmounts the panel on [controller] via a
  /// microtask so the controller's listener (the host's `setState`)
  /// runs after the current build commits. `entry == null` clears the
  /// slot (tooltip hidden); non-null re-uses the existing token via
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
          layer: .tooltip,
          panel: entry,
        );
      } else {
        controller.update(token, entry);
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _enterTimer?.cancel();
    _enterTimer = null;
    _exitTimer?.cancel();
    _exitTimer = null;
    _floating?.dispose();
    _floating = null;
    _unmountPortal();
    super.dispose();
  }

  // ───────────────────────────── render ────────────────────────────

  @override
  Component build(BuildContext context) {
    // Active duration mirrors Flutter `FixedTooltipOverlayHandler`:
    // open uses the full 150 ms; close compresses to 2/3 of the
    // 100 ms close window so the visible motion ends within the
    // first ~67 ms (matching Flutter's `Interval(0, 2/3)`).
    final activeDuration = _didEnter ? _kOpenDuration : _kCloseVisibleDuration;

    // Single entry point — merge chain + token fallback + every
    // per-state slot (panel placement + bubble motion) pre-composed
    // in `tooltip_style.dart`. This build only reads
    // `chrome.X.className / inlineStyles`.
    final config = resolveTooltipConfig(
      context,
      position: component.position,
      tooltipStyle: component.tooltipStyle,
    );
    final resolved = resolveTooltip(
      context,
      didEnter: _didEnter,
      activeDurationMs: activeDuration.inMilliseconds,
      placement: _resolvedPlacement ?? config.placement,
      left: _left,
      top: _top,
      tooltipStyle: component.tooltipStyle,
    );

    Component? panelNode;
    if (_isOpen) {
      // Atomic-style nested label slot resolution (Epic #1302) —
      // labelStyle override lives on the message wrapper so the
      // override beats the panel's `text-` class precedence. The
      // resolver pre-builds a `WebElementChrome` for the label `<span>`
      // when (and only when) the caller supplied a `labelStyle`
      // override; without one the content is a bare text node and the
      // bubble's role + colour class already reaches it.
      //
      // `tooltipChild` goes through the same wrapper. Inline rules on an
      // ancestor are inherited, not imposed: a child that declares its
      // own colour or size overrides them, so the child still owns its
      // typography — it just no longer misses the override the `message`
      // path gets. Mirrors the Flutter twin wrapping both content paths
      // in one `DefaultTextStyle.merge`.
      final labelChrome = resolved.label;
      final content = component.tooltipChild ?? Text(component.message);
      final messageNode = labelChrome != null
          ? span([content], styles: labelChrome.inlineStyles)
          : content;

      // Two-div split mirrors `Popover` — outer carries the
      // viewport-fixed position transform (no transition), inner
      // carries the chrome + open-state class swap (transition).
      // Without the split the position `transform: translate(...)`
      // gets interpolated every time `_recomputeAnchor` updates the
      // anchor — visible as the bubble sliding across the screen.
      // Outer positioned wrapper carries `id: _panelId` so the
      // `OverlayPositioner` measures + positions *its* stable layout box
      // (the inner bubble's scale animation is a paint-only transform
      // that does not change this box's `getBoundingClientRect`). The
      // inner bubble carries the chrome + open-state motion classes.
      panelNode = div(
        [
          div(
            [
              messageNode,
              // Trigger-pointing tail — clip-path triangle sharing the
              // bubble background, absolutely positioned on the
              // flip-resolved placement edge. Absent when the style states
              // none (the default).
              if (resolved.tail case final tail?)
                div(
                  const [],
                  classes: tail.className,
                  styles: tail.inlineStyles,
                ),
            ],
            classes: resolved.bubble.className,
            styles: resolved.bubble.inlineStyles,
            attributes: const {'role': 'tooltip'},
          ),
        ],
        id: _panelId,
        classes: resolved.panel.className,
        styles: resolved.panel.inlineStyles,
        attributes: TopLayer.attributesFor(context),
      );
    }

    final triggerNode = div(
      [component.child],
      id: _triggerId,
      classes: resolved.trigger.className,
      events: {
        'mouseenter': EventHandlers.createMouseEventHandler(_handleMouseEnter),
        'mouseleave': EventHandlers.createMouseEventHandler(_handleMouseLeave),
      },
    );

    // Sync the panel to the root [OverlayHost]'s tooltip layer when
    // one is available. Sync runs as a microtask so we don't mutate
    // the controller (and trigger its listeners' setState) during
    // this widget's build.
    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      _schedulePortalSync(
        portal.controller,
        portal.capture(context, panelNode),
      );
    } else if (_overlayController != null) {
      // Previously had a portal ancestor but it's gone — clean up.
      _unmountPortal();
    }

    return div(
      [
        triggerNode,
        if (!portalled) ?panelNode,
      ],
      id: component.id,
      // Consumer `classes` / `css` apply to the ROOT wrapper (this
      // component's documented contract — "for the root wrapper"), so a
      // caller that needs the tooltip to participate in its own layout
      // (e.g. Tracker's `flex-1` segment cells) can size the outermost
      // box. Previously these landed on the inner trigger, which left the
      // empty root as the flex child → flex-1 never grew → wrapped
      // content collapsed to 0 width (Tracker segments invisible).
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}
