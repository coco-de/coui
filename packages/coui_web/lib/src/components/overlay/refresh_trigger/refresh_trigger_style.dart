/// Style-slot single entry point for the Web `RefreshTrigger`.
///
/// Mirrors the Flutter `refresh_trigger_style.dart`: a
/// `resolveRefreshTrigger` merge function that walks the nested merge
/// chain (`CoreRefreshTriggerStyle.defaultX` →
/// `theme.refreshTrigger.style` → `widget.refreshTriggerStyle`) and
/// ships back a [ResolvedRefreshTrigger] paint-ready chrome bundle.
///
/// Per-state chrome (indicator slide offset / padding swap + indicator
/// label colour swap — both depend on the current [CoreRefreshStage] —
/// and the pull-progress arrow rotation) is folded into the bundle as
/// `indicatorWrapper` / `indicator` / `labelRow` / `arrow` slot fields.
/// Runtime state (`stage` / `direction` / `reverse` / `dragging` /
/// `offset` / `progress`) flows in as resolver args so
/// `refresh_trigger.dart` build only reads
/// `chrome.X.className / inlineStyles` and never composes className /
/// inline-CSS itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedRefreshTrigger — slot-only chrome bundle
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `RefreshTrigger`.
///
/// DOM shape:
///
/// ```text
/// root (<div relative overflow-hidden>)             // outer wrapper
///   ├─ indicatorWrapper (<div absolute>)            // edge anchor rail
///   │    └─ indicator (<div role="status">)         // slide offset + stage padding
///   │         └─ labelRow (<div inline-flex>)       // stage-driven label colour
///   │              ├─ arrow? (only when pulling)    // pull-progress rotation
///   │              ├─ <span> label text
///   │              ├─ arrow? (only when pulling)
///   │              ├─ Loading? (only when refreshing)
///   │              └─ check? (only when completed)
///   └─ content (<div overflow-auto>)                // scrollable host
///        └─ child
/// ```
///
/// All slot chromes are non-null — `refresh_trigger.dart` decides
/// whether to render the arrow / spinner / check based on the stage.
/// Per-state chrome (indicator slide offset, padding, label colour,
/// arrow rotation) is folded into the slot fields by
/// [resolveRefreshTrigger] itself via the runtime resolver args.
class ResolvedRefreshTrigger implements WebResolvedChrome {
  /// Creates a [ResolvedRefreshTrigger].
  const ResolvedRefreshTrigger({
    required this.root,
    required this.content,
    required this.indicatorWrapper,
    required this.indicator,
    required this.labelRow,
    required this.arrow,
  });

  /// Paint-ready chrome for the outermost wrapper
  /// `<div relative overflow-hidden>` — clips the indicator while it is
  /// parked outside the pulled edge.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the scrollable content host
  /// `<div overflow-auto>` that hosts the user [RefreshTrigger] child —
  /// `overscroll-behavior: contain` keeps the pull gesture from
  /// triggering the browser's native pull-to-refresh.
  final WebElementChrome content;

  /// Paint-ready chrome for the indicator anchor rail `<div absolute>`
  /// pinned to the pulled edge (top / bottom / left / right per
  /// direction × reverse) — centres the surface along the cross axis
  /// and stays pointer-transparent so the content underneath keeps
  /// receiving the gesture.
  final WebElementChrome indicatorWrapper;

  /// Paint-ready chrome for the indicator surface `<div role="status">`
  /// — background / corner radius / stage padding plus the pull-driven
  /// slide transform (hidden by its own extent at rest, translated in
  /// by the safe pull offset) and the settle transition.
  final WebElementChrome indicator;

  /// Paint-ready chrome for the indicator label row `<div inline-flex>`
  /// — typography class + flex gap + stage-driven text colour + optional
  /// nested label `CoreTextStyle` override baked in.
  final WebElementChrome labelRow;

  /// Paint-ready chrome for the pull-arrow `<div inline-flex>` shown
  /// beside the label in the `pulling` stage — rotation follows the
  /// pull progress (0 → 1 maps onto a 180° flip, matching the Flutter
  /// indicator).
  final WebElementChrome arrow;
}

/// Resolved behavior timings for `RefreshTrigger`. No DOM chrome —
/// widget behavior helper only: the completion-hold timer and the
/// settle animation the gesture state machine schedules around.
class ResolvedRefreshTriggerTiming {
  /// Creates a [ResolvedRefreshTriggerTiming].
  const ResolvedRefreshTriggerTiming({required this.animationDuration});

  /// Indicator settle / completion-hold duration — mirrors the Flutter
  /// resolver's `animationDuration` used both for the slide-back
  /// transition and the completed → idle hold timer.
  final Duration animationDuration;
}

// ════════════════════════════════════════════════════════════════
// resolveRefreshTrigger — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves the behavior timing bundle for the gesture state machine —
/// see [ResolvedRefreshTriggerTiming].
ResolvedRefreshTriggerTiming resolveRefreshTriggerTiming(
  BuildContext context, {
  CoreRefreshTriggerStyle? refreshTriggerStyle,
}) {
  final refreshTriggerTheme = context.theme.coreComponentTheme?.refreshTrigger;
  final merged = resolveStyleChain(const CoreRefreshTriggerStyle(), [
    refreshTriggerTheme?.style,
    refreshTriggerStyle,
  ]);
  final animationDuration =
      merged.animationDuration ??
      CoreRefreshTriggerStyle.defaultAnimationDuration;

  return ResolvedRefreshTriggerTiming(animationDuration: animationDuration);
}

/// Resolves [ResolvedRefreshTrigger] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreRefreshTriggerStyle.defaultX` static const fallback so the
/// entry reads only fully-resolved CSS-ready values. Runtime state
/// flows in as resolver args:
///
/// - [stage] / [direction] / [reverse] — the semantic pull state.
/// - [dragging] — `true` while the pointer is down, which drops the
///   slide transition so the indicator tracks the finger 1:1 (mirrors
///   the Flutter `duration: _scrolling ? .zero : animationDuration`).
/// - [offset] — the safe pull extent in px (decelerate resistance
///   already applied by the widget state machine).
/// - [progress] — raw pull extent ÷ minExtent, clamped 0 → 1; drives
///   the arrow flip.
///
/// ```text
/// CoreRefreshTriggerStyle.defaultX        // design system default
///   → theme.coreComponentTheme.refreshTrigger.style
///   → widget.refreshTriggerStyle
/// ```
ResolvedRefreshTrigger resolveRefreshTrigger(
  BuildContext context, {
  required CoreRefreshStage stage,
  required CoreRefreshDirection direction,
  required bool reverse,
  required bool dragging,
  required double offset,
  required double contentOffset,
  required double progress,
  CoreRefreshTriggerStyle? refreshTriggerStyle,
}) {
  final refreshTriggerTheme = context.theme.coreComponentTheme?.refreshTrigger;

  // 2-step merge chain — theme.style → widget.refreshTriggerStyle.
  final merged = resolveStyleChain(const CoreRefreshTriggerStyle(), [
    refreshTriggerTheme?.style,
    refreshTriggerStyle,
  ]);

  // ─── Stage1 RESOLVE — merged override else static const default ──
  final background =
      merged.indicatorBackgroundColor ??
      CoreRefreshTriggerStyle.defaultIndicatorBackgroundColor;
  final radius =
      merged.indicatorBorderRadius ??
      CoreRefreshTriggerStyle.defaultIndicatorBorderRadius;
  final padding =
      merged.indicatorPadding ??
      CoreRefreshTriggerStyle.defaultIndicatorPadding;
  final pullingPadding =
      merged.pullingPadding ?? CoreRefreshTriggerStyle.defaultPullingPadding;
  // Per-stage text style slots — each carries the `labelLarge` role
  // token plus the stage foreground colour. The active stage's slot,
  // with the per-instance `labelStyle` overlaid, routes through
  // `emitTypography` so the role class + stage-colour token class +
  // any scalar overlay emit together.
  final activeStageSlot = switch (stage) {
    .idle || .pulling => CoreRefreshTriggerStyle.defaultIdleTextStyle.merge(
      merged.idleTextStyle,
    ),
    .refreshing => CoreRefreshTriggerStyle.defaultRefreshingTextStyle.merge(
      merged.refreshingTextStyle,
    ),
    .completed => CoreRefreshTriggerStyle.defaultCompletedTextStyle.merge(
      merged.completedTextStyle,
    ),
  };
  final isVertical = direction == .vertical;
  // ─── Stage2 EMIT (Web, theme-free) ────────────────────
  // Background — token default emits a `bg-<token>` class, a raw caller
  // override drops the class and emits inline CSS. Radius / padding are
  // always inline `toValue()` (token-aware shorthand). The label routes
  // through `emitTypography`: the active stage slot supplies the role
  // token AND the stage colour token, so the resulting class carries
  // `text-{role} text-{colourToken}` and any per-instance `labelStyle`
  // scalar overlay emits inline alongside.
  final backgroundEmit = emitColor(
    merged.indicatorBackgroundColor,
    background,
    .background,
  );
  final labelEmit = emitTypography(
    merged.labelStyle,
    activeStageSlot,
  );
  final indicatorBorderRadius = radius.toValue();
  final indicatorPadding = padding.toValue();
  final pullingPaddingValue = pullingPadding.toValue();
  // Nested `CoreGapStyle` slot — merge the design-system default with
  // the per-instance override. Mirrors the Flutter resolver which
  // forwards the slot to the `Gap` siblings between the indicator
  // row children. The label-row flex gap is always emitted inline
  // (through `spaceCss`) from this merged slot — single-signature, no
  // `gap-*` Tailwind class.
  final indicatorGapStyle = CoreRefreshTriggerStyle.defaultIndicatorGapStyle
      .merge(merged.indicatorGapStyle);
  final indicatorGapSize = indicatorGapStyle.size!;
  final animationDuration =
      (merged.animationDuration ??
              CoreRefreshTriggerStyle.defaultAnimationDuration)
          .inMilliseconds;
  // ─── Local builders ───────────────────────────────────

  /// Composes the outermost wrapper `<div>` Tailwind className —
  /// `relative` so the indicator rail can anchor to the pulled edge,
  /// `overflow-hidden` so the parked indicator stays clipped, and
  /// `w-full` so a flex/grid parent cannot shrink the scroll host to
  /// its intrinsic content width (the Flutter twin's scrollable fills
  /// the viewport the same way).
  String buildRootClassName() =>
      '${WebLayout.relativeOverflowHidden} ${WebLayout.wFull}';

  /// Composes the scrollable content host `<div>` Tailwind className —
  /// `h-full` fills a fixed-height root so the host becomes the scroll
  /// viewport (no-op when the root sizes to its content).
  String buildContentClassName() =>
      '${WebLayout.overflowAuto} ${WebLayout.hFull}';

  /// Composes the content host inline-CSS bundle —
  /// `overscroll-behavior: contain` keeps the component's own pull
  /// gesture from chaining into the browser's native pull-to-refresh /
  /// scroll chaining while the boundary is overscrolled; while
  /// [dragging] text selection is suppressed so the pull drag does not
  /// sweep-select the list copy. The pull [offset] also translates the
  /// content along the pull axis so the list follows the drag together
  /// with the indicator (mirrors the Flutter twin, whose
  /// `BouncingScrollPhysics` overscroll drags the list itself), with
  /// the same settle transition as the indicator.
  Styles buildContentInlineStyles() {
    final offsetCss = '${contentOffset / kRemDivisor}rem';
    final transform = isVertical
        ? (reverse ? 'translateY(-$offsetCss)' : 'translateY($offsetCss)')
        : (reverse ? 'translateX(-$offsetCss)' : 'translateX($offsetCss)');
    return .new(
      raw: {
        'overscroll-behavior': 'contain',
        'transform': transform,
        if (!dragging)
          'transition':
              'transform ${animationDuration}ms '
              'var(--easing-${CoreEasing.scale.easeOutSine})',
        if (dragging) 'user-select': 'none',
      },
    );
  }

  /// Composes the indicator anchor rail `<div>` Tailwind className —
  /// pinned to the pulled edge (direction × reverse, mirroring the
  /// Flutter `_wrapPositioned`), centring the surface on the cross
  /// axis, pointer-transparent so the gesture stays on the content.
  String buildIndicatorWrapperClassName() {
    final anchor = isVertical
        ? (reverse
              ? '${WebLayout.absolute} bottom-0 left-0 right-0'
              : '${WebLayout.absolute} top-0 left-0 right-0')
        : (reverse
              ? '${WebLayout.absolute} top-0 bottom-0 right-0'
              : '${WebLayout.absolute} top-0 bottom-0 left-0');
    final center = isVertical
        ? '${WebLayout.flex} ${WebLayout.justifyCenter}'
        : '${WebLayout.flex} ${WebLayout.itemsCenter}';
    return '$anchor $center pointer-events-none';
  }

  /// Composes the indicator `<div role="status">` Tailwind className —
  /// the default-token background class (`bg-<token>` from
  /// [emitColor]) is added only when the caller did **not** override
  /// `indicatorBackgroundColor`; on a raw override the class is empty
  /// so the inline rule wins (card colour pattern). Also marks this
  /// element as a `role: .functional` component surface — restated here
  /// rather than composing `OutlinedContainer` (a DOM restructure) the
  /// way `Alert` restates it on its own root — so a material preset
  /// reaches the indicator the pull gesture floats over the content it
  /// refreshes with.
  String buildIndicatorClassName() {
    final classList = [
      WebLayout.flexCenter,
      ...webSurfaceMarkerFor(.functional),
      backgroundEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the indicator `<div role="status">` inline-CSS bundle —
  /// always-inline border-radius shorthand, the emit-family background
  /// inline fragment (raw override only), stage-dependent padding
  /// shorthand, and the pull-driven slide transform: parked the surface
  /// hides behind the pulled edge by its own extent and the safe pull
  /// [offset] translates it in (mirrors the Flutter
  /// `FractionalTranslation` + `Transform.translate` pair). While
  /// [dragging] the transition is dropped so the surface tracks the
  /// pointer 1:1; otherwise it settles with the easing token.
  Styles buildIndicatorInlineStyles() {
    final offsetCss = '${offset / kRemDivisor}rem';
    final transform = isVertical
        ? (reverse
              ? 'translateY(calc(100% - $offsetCss))'
              : 'translateY(calc(-100% + $offsetCss))')
        : (reverse
              ? 'translateX(calc(100% - $offsetCss))'
              : 'translateX(calc(-100% + $offsetCss))');
    final raw = {
      'padding': stage == .pulling ? pullingPaddingValue : indicatorPadding,
      'border-radius': indicatorBorderRadius,
      'transform': transform,
      if (!dragging)
        'transition':
            'transform ${animationDuration}ms '
            'var(--easing-${CoreEasing.scale.easeOutSine})',
      ...?backgroundEmit.inline,
      // The other half of the surface marker above — publishes the fill
      // this indicator chose so a material preset can restate it at its
      // own alpha without knowing which token that was.
      ...surfaceFillVar(background),
    };
    return Styles(raw: raw);
  }

  /// Composes the label row `<div>` Tailwind className — `inline-flex`
  /// keeps the icon + label co-aligned, plus the [emitTypography] role
  /// + stage-colour token classes. The flex gap is always emitted
  /// inline (see [buildLabelRowInlineStyles]) — single-signature, no
  /// `gap-*` class.
  String buildLabelRowClassName() => [
    WebLayout.inlineFlexItemsCenter,
    // Single-line label — the indicator surface sizes to its content,
    // so without nowrap a narrow host wraps the copy word-by-word
    // (the Flutter row never wraps).
    WebLayout.whitespaceNowrap,
    labelEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the label row inline-CSS bundle — flex gap (`spaceCss`,
  /// always inline via the merged [CoreGapStyle] slot) plus any inline
  /// fragment produced by [emitTypography] (scalar overlay, or a raw
  /// colour / arbitrary style when no role token survives).
  Styles buildLabelRowInlineStyles() {
    final raw = {
      'gap': spaceCss(indicatorGapSize),
      ...?labelEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the arrow wrapper `<div>` Tailwind className — keeps the
  /// rotated icon aligned with the surrounding label baseline. The
  /// arrow glyph inherits its `color` from the label-row stage colour
  /// (set on the parent `labelRow` element) via the CSS cascade, so no
  /// colour class is added here.
  String buildArrowClassName() => WebLayout.inlineFlex;

  /// Composes the arrow wrapper inline-CSS bundle — the pull-progress
  /// rotation applied to the `arrow-down` glyph. 0 → 1 [progress] maps
  /// onto a 0 → −180° flip (vertical) or a −90° → −270° flip
  /// (horizontal), mirroring the Flutter `_buildPulling` angles.
  Styles buildArrowInlineStyles() {
    // 0 → 1 pull progress maps onto a half-turn flip; horizontal starts
    // from a quarter turn (mirrors the Flutter `_buildPulling` angles).
    const kHalfTurnDegrees = 180.0;
    const kQuarterTurnDegrees = 90.0;
    final degrees = isVertical
        ? -kHalfTurnDegrees * progress
        : -kQuarterTurnDegrees + (-kHalfTurnDegrees * progress);
    return Styles(
      raw: {
        'transform': 'rotate(${degrees.toStringAsFixed(1)}deg)',
        'transition':
            'transform ${animationDuration}ms '
            'var(--easing-${CoreEasing.scale.easeOutSine})',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedRefreshTrigger(
    root: WebElementChrome(className: buildRootClassName()),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    indicatorWrapper: WebElementChrome(
      className: buildIndicatorWrapperClassName(),
    ),
    indicator: WebElementChrome(
      className: buildIndicatorClassName(),
      inlineStyles: buildIndicatorInlineStyles(),
    ),
    labelRow: WebElementChrome(
      className: buildLabelRowClassName(),
      inlineStyles: buildLabelRowInlineStyles(),
    ),
    arrow: WebElementChrome(
      className: buildArrowClassName(),
      inlineStyles: buildArrowInlineStyles(),
    ),
  );
}
