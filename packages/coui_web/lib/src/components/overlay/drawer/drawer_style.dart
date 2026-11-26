/// Style-slot single entry point for the Web `Drawer`.
///
/// Mirrors the Flutter `drawer_style.dart`: a `resolveDrawer` merge
/// function that walks the nested merge chain
/// (`CoreDrawerStyle.defaultX` → `theme.drawer.style` →
/// `widget.drawerStyle`) and ships back a `ResolvedDrawer` chrome
/// bundle. Every slot — root / barrier / panel / header / titleWrap /
/// content — ships as a `WebElementChrome` so the `co_drawer.dart`
/// build only reads `chrome.X.className / inlineStyles` and never
/// composes className/inline-CSS itself; the header close affordance
/// ships as a nested `closeButtonStyle` slot raw-forwarded to
/// `Button(variant: .plain, buttonStyle: …)`.
/// Runtime state (`side` / `open` / `dragDelta`) flows in as resolver
/// args so the barrier + panel slots resolve in the same single
/// entry point as the rest of the chrome.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedDrawer — slot-only chrome bundle
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Drawer`.
///
/// DOM shape:
///
/// ```text
/// root (<div fixed inset-0 z-50>)            // overlay wrapper
///   ├─ barrier (<div absolute inset-0 z-40>) // scrim with state-driven opacity / transition
///   └─ panel (<div absolute z-50 flex-col>)  // side-docked panel with state-driven transform
///        ├─ handle (<div>) > handlePill       // showDragHandle, bottom sheet: first
///        ├─ header (<div>)                   // co_drawer renders only when title / description != null
///        │    ├─ titleWrap (<div flex-1>)
///        │    │    └─ Text(title)            // Text chain — or, with a description:
///        │    │       heading (<div flex-col>)
///        │    │         ├─ Text(title)
///        │    │         ├─ Gap ← titleDescriptionGapStyle
///        │    │         └─ description (<div>) > Text(description)
///        │    └─ Button.plain (closeButtonStyle)   // showCloseButton
///        │         └─ Icon(x, closeButtonStyle.leadingIconStyle)
///        ├─ content (<div flex-1 overflow-auto>)
///        │    └─ component.content
///        ├─ footer (<div flex justify-end>)  // rendered only when footer != null
///        │    └─ component.footer
///        └─ handle > handlePill              // showDragHandle, top sheet: last
/// ```
///
/// A side drawer with a handle puts the body and the handle side by side:
///
/// ```text
/// panel
///   └─ sideRow (<div flex>)
///        ├─ sideBody (<div flex-col>) > header · content · footer
///        └─ handle > handlePill             // on the inner edge
/// ```
///
/// All `WebElementChrome` slot chromes are non-null — `co_drawer`
/// decides whether to render each optional slot based on instance
/// state. Per-state chrome (barrier opacity flip + panel slide
/// transform) is folded into the `barrier` / `panel` slots by
/// `resolveDrawer` itself.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [closeButtonStyle] is raw-forwarded to
///   `Button(variant: .plain, buttonStyle: …)` for the header close
///   affordance.
///
/// No scalar metadata (icon size / drag threshold / etc.) is exposed —
/// behaviour values (`dragDismissThreshold`) are widget parameters
/// (`Drawer.dragDismissThreshold`), semantic identifiers (`side`) stay
/// on the widget prop.
class ResolvedDrawer implements WebResolvedChrome {
  /// Creates a [ResolvedDrawer].
  const ResolvedDrawer({
    required this.root,
    required this.barrier,
    required this.panel,
    required this.header,
    required this.titleWrap,
    required this.content,
    required this.footer,
    required this.closeButtonStyle,
    required this.heading,
    required this.description,
    required this.titleDescriptionGapStyle,
    required this.handle,
    required this.handlePill,
    required this.sideRow,
    required this.sideBody,
  });

  /// Paint-ready chrome for the outermost `<div fixed inset-0 z-50>`
  /// overlay wrapper that pins the barrier + panel to the viewport.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the barrier (scrim) `<div absolute inset-0
  /// z-40>` — colour + opacity flip + transition + pointer-events gate
  /// driven by the `open` resolver arg.
  final WebElementChrome barrier;

  /// Paint-ready chrome for the panel `<div absolute z-50 flex-col>` —
  /// per-side docking + size defaults + slide / drag transform driven
  /// by the `side` / `open` / `dragDelta` resolver args.
  final WebElementChrome panel;

  /// Paint-ready chrome for the header row `<div>` — only rendered by
  /// `co_drawer` when `title != null`.
  final WebElementChrome header;

  /// Paint-ready chrome for the header title `<div flex-1>` wrapper
  /// — also carries the resolved `titleStyle` overrides as inline CSS
  /// so the nested `Text(title)` chain inherits them via CSS cascade.
  final WebElementChrome titleWrap;

  /// Paint-ready chrome for the panel content `<div flex-1 overflow-auto>`
  /// — padding flows through `inlineStyles`.
  final WebElementChrome content;

  /// Paint-ready chrome for the footer row `<div>` — the divider on its top
  /// edge, its padding and the right-aligned `footer` slot. Rendered only
  /// when the drawer has a footer.
  final WebElementChrome footer;

  /// Nested header close-button style — `defaultCloseButtonStyle`
  /// (tap-target padding / hit-area radius / 16-px close glyph / hover
  /// transition / focus-ring width) merged with the per-instance
  /// `closeButtonStyle` slot, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. The button resolves
  /// its own chrome (the `plain` variant owns the resting-opacity /
  /// hover-fade / foreground).
  final CoreButtonStyle closeButtonStyle;

  /// Paint-ready chrome for the column stacking the title over the
  /// description — rendered only when the drawer has a description.
  final WebElementChrome heading;

  /// Paint-ready chrome for the description `<div>` — its role class and
  /// tone from `CoreDrawerStyle.defaultDescriptionStyle` with the
  /// `descriptionStyle` slot over it; the nested `Text` inherits them.
  final WebElementChrome description;

  /// Nested spacer between the title and the description — forwarded raw
  /// to `Gap`.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Paint-ready chrome for the grab-handle box — the space around the
  /// pill, centring it on the panel edge. Rendered only when the drawer
  /// shows its handle.
  final WebElementChrome handle;

  /// Paint-ready chrome for the grab-handle pill — length along the edge,
  /// thickness across it, corner and colour.
  final WebElementChrome handlePill;

  /// Paint-ready chrome for the row that puts a side drawer's body beside
  /// its handle.
  final WebElementChrome sideRow;

  /// Paint-ready chrome for a side drawer's body column inside [sideRow].
  final WebElementChrome sideBody;
}

// ════════════════════════════════════════════════════════════════
// resolveDrawerTiming — behavior timing config (Category E)
// ════════════════════════════════════════════════════════════════

/// Resolved behavior timings for `Drawer`. No DOM chrome — widget
/// behavior helper only (the animated-dismiss timer and the scrub
/// settle need the durations outside the chrome bundle).
class ResolvedDrawerTiming {
  /// Creates a [ResolvedDrawerTiming].
  const ResolvedDrawerTiming({
    required this.openDurationMs,
    required this.closeDurationMs,
  });

  /// Open-direction slide duration in milliseconds.
  final int openDurationMs;

  /// Close-direction slide duration in milliseconds.
  final int closeDurationMs;
}

/// Resolves the open/close slide durations for `Drawer` — walks the
/// same nested-merge chain as [resolveDrawer] but yields only the
/// behaviour timings.
ResolvedDrawerTiming resolveDrawerTiming(
  BuildContext context, {
  CoreDrawerStyle? drawerStyle,
}) {
  final drawerTheme = context.theme.coreComponentTheme?.drawer;
  final merged = resolveStyleChain(const CoreDrawerStyle(), [
    drawerTheme?.style,
    drawerStyle,
  ]);
  final openDurationMs =
      (merged.openAnimationDuration ??
              CoreDrawerStyle.defaultOpenAnimationDuration)
          .inMilliseconds;
  final closeDurationMs =
      (merged.closeAnimationDuration ??
              CoreDrawerStyle.defaultCloseAnimationDuration)
          .inMilliseconds;
  return ResolvedDrawerTiming(
    openDurationMs: openDurationMs,
    closeDurationMs: closeDurationMs,
  );
}

// ════════════════════════════════════════════════════════════════
// resolveDrawerBackdropRuntime — client behaviour bundle (Category D)
// ════════════════════════════════════════════════════════════════

/// Client-side runtime config for the `Drawer` backdrop transform.
/// Fed to the overlay host's backdrop wrapper (via
/// `OverlayController.pushBackdropTransform`) when the panel opens
/// with `transformBackdrop: true` — no DOM chrome of its own.
class ResolvedDrawerBackdropRuntime {
  /// Creates a [ResolvedDrawerBackdropRuntime].
  const ResolvedDrawerBackdropRuntime({
    required this.scale,
    required this.cornerRadiusCss,
    required this.cornerRadiusTopLeftPx,
    required this.cornerRadiusTopRightPx,
    required this.cornerRadiusBottomRightPx,
    required this.cornerRadiusBottomLeftPx,
    required this.durationMs,
  });

  /// Backdrop scale factor when the drawer is fully open.
  final double scale;

  /// CSS `border-radius` the scaled backdrop clips to (settled state —
  /// full 4-corner shorthand).
  final String cornerRadiusCss;

  /// The four corners as scalars (logical px) — a swipe scrub
  /// interpolates each independently with the finger's progress
  /// (`corner × t`, the same per-corner curve `BorderRadius.lerp`
  /// drives on the Flutter backdrop host) so an asymmetric override
  /// survives mid-drag instead of collapsing to one corner's value.
  final double cornerRadiusTopLeftPx;

  /// See [cornerRadiusTopLeftPx].
  final double cornerRadiusTopRightPx;

  /// See [cornerRadiusTopLeftPx].
  final double cornerRadiusBottomRightPx;

  /// See [cornerRadiusTopLeftPx].
  final double cornerRadiusBottomLeftPx;

  /// Transition duration for the scale / radius animation — the
  /// drawer's own open duration so backdrop and panel move together.
  final int durationMs;
}

/// Resolves the backdrop-transform runtime for `Drawer` — walks the
/// same nested-merge chain as [resolveDrawer] but yields only the
/// values the overlay host's backdrop wrapper consumes.
ResolvedDrawerBackdropRuntime resolveDrawerBackdropRuntime(
  BuildContext context, {
  CoreDrawerStyle? drawerStyle,
}) {
  final drawerTheme = context.theme.coreComponentTheme?.drawer;
  final merged = resolveStyleChain(const CoreDrawerStyle(), [
    drawerTheme?.style,
    drawerStyle,
  ]);
  final scale = merged.backdropScale ?? CoreDrawerStyle.defaultBackdropScale;
  final cornerRadius =
      merged.backdropCornerRadius ??
      CoreDrawerStyle.defaultBackdropCornerRadius;
  final cornerRadiusCss = cornerRadius.toValue();
  final durationMs =
      (merged.openAnimationDuration ??
              CoreDrawerStyle.defaultOpenAnimationDuration)
          .inMilliseconds;
  return ResolvedDrawerBackdropRuntime(
    scale: scale,
    cornerRadiusCss: cornerRadiusCss,
    cornerRadiusTopLeftPx: cornerRadius.topLeft,
    cornerRadiusTopRightPx: cornerRadius.topRight,
    cornerRadiusBottomRightPx: cornerRadius.bottomRight,
    cornerRadiusBottomLeftPx: cornerRadius.bottomLeft,
    durationMs: durationMs,
  );
}

// ════════════════════════════════════════════════════════════════
// resolveDrawer — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedDrawer] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreDrawerStyle.defaultX` static const fallback so the entry
/// reads only fully-resolved CSS-ready values. Runtime state flows in
/// as the `side` / `open` / `dragDelta` / `bodyFits` args so the barrier
/// + panel slots resolve in the same pass as the static chrome; while
/// `draggable`, a touch on the panel (and on a body whose content fits)
/// goes to the panel's own drag.
///
/// With a [rubberBand] the panel can also be drawn stretched: [stretch] px
/// out at its far edge, as a scale along its slide axis about the edge it is
/// docked to ([stretchExtent] is the panel's own length on that axis, the
/// figure the scale is a fraction of). [settling] is the return to the dock
/// after a release, which takes the rubber band's duration and curve instead
/// of the slide's. Without a rubber band none of the three reaches the CSS.
///
/// ```text
/// CoreDrawerStyle.defaultX
///   → theme.coreComponentTheme.drawer.style
///   → widget.drawerStyle
/// ```
ResolvedDrawer resolveDrawer(
  BuildContext context, {
  required CoreDrawerSide side,
  required bool open,
  required double dragDelta,
  bool rubberBand = CoreDrawerContract.defaultRubberBand,
  double stretch = 0,
  double stretchExtent = 0,
  bool settling = false,
  double? openProgress,
  bool fillSafeArea = CoreDrawerContract.defaultFillSafeArea,
  bool draggable = true,
  bool bodyFits = false,
  CoreDrawerStyle? drawerStyle,
}) {
  final drawerTheme = context.theme.coreComponentTheme?.drawer;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDrawerStyle(), [
    drawerTheme?.style,
    drawerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth.
  final panelBackgroundColor =
      merged.panelBackgroundColor ??
      CoreDrawerStyle.defaultPanelBackgroundColor;
  final panelBorderColor =
      merged.panelBorderColor ?? CoreDrawerStyle.defaultPanelBorderColor;
  // A left / right drawer is a square column of the page with a 1px line on
  // its inner edge; a top / bottom sheet rounds the corners that face into
  // the viewport and draws no line.
  final isHorizontal = side == .left || side == .right;
  final panelBorderRadius =
      merged.panelBorderRadius ??
      (isHorizontal
          ? CoreDrawerStyle.defaultSidePanelBorderRadius
          : CoreDrawerStyle.defaultPanelBorderRadius);
  final panelBorderWidth =
      merged.panelBorderWidth ??
      (isHorizontal
          ? CoreDrawerStyle.defaultPanelBorderWidth
          : CoreDrawerStyle.defaultSheetPanelBorderWidth);
  // Header divider — nested slot, empty by default so `Divider`'s own
  // shared default (`outlineVariant` → `outline` fallback) applies.
  // Not the panel's own border token (#4815 디자이너 결정 #1 — the two
  // are different surfaces). Same class-default/inline-override split
  // as `panelBorderColor` below.
  // guard-nested-override: color
  final dividerColor =
      merged.dividerStyle?.color ?? CoreDividerStyle.defaultColor;
  final panelPadding =
      merged.panelPadding ?? CoreDrawerStyle.defaultPanelPadding;
  final shadowLayers =
      merged.panelBoxShadow ?? CoreDrawerStyle.defaultPanelBoxShadow;
  // Barrier (scrim) — the `barrierOpacity` multiplier is folded in via
  // `scaleAlpha` so the token emits as `rgb(var(--coui-scrim) / NN%)`
  // and the page behind the panel stays visible (mirrors the dialog
  // backdrop; the barrier div's own `opacity` property is the
  // open/close fade, not the dim level).
  final barrierOpacity =
      merged.barrierOpacity ?? CoreDrawerStyle.defaultBarrierOpacity;
  final barrierColor =
      (merged.barrierColor ?? CoreDrawerStyle.defaultBarrierColor).scaleAlpha(
        barrierOpacity,
      );
  final headerPadding =
      merged.headerPadding ?? CoreDrawerStyle.defaultHeaderPadding;
  final headerSpacing =
      merged.headerSpacing ?? CoreDrawerStyle.defaultHeaderSpacing;
  final footerPadding =
      merged.footerPadding ?? CoreDrawerStyle.defaultFooterPadding;
  // Close-button chrome — chained `defaultCloseButtonStyle` (tap-target
  // padding + hit-area radius + 16-px close glyph + 150 ms hover + 2-px
  // focus ring) with the per-instance override on top. Raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)` — the button resolves
  // its own padding / icon / hover-fade / focus-ring (the `plain`
  // variant owns the resting-opacity / hover-fade / `onSurface`
  // foreground; mirrors the toast dismiss button).
  final closeButtonStyle = CoreDrawerStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  // The header rule's thickness — the class carries the 1px default; a
  // stated thickness (0 for a header with no rule) goes inline instead.
  // guard-nested-override: thickness
  final dividerThickness = merged.dividerStyle?.thickness;
  // Description cell — role class + tone (and any overlay) from the emit
  // family.
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    CoreDrawerStyle.defaultDescriptionStyle,
  );
  // Nested CoreGapStyle slot — forwarded raw to `Gap`.
  final titleDescriptionGapStyle = CoreDrawerStyle
      .defaultTitleDescriptionGapStyle
      .merge(merged.titleDescriptionGapStyle);
  // Grab handle — the pill's length and thickness are sizes (rem, the
  // Flutter twin's `* scaling`); the space around it is spacing, routed
  // through the density variable.
  final dragHandleEmit = emitColor(
    merged.dragHandleColor,
    CoreDrawerStyle.defaultDragHandleColor,
    .background,
  );
  final dragHandleWidth =
      merged.dragHandleWidth ?? CoreDrawerStyle.defaultDragHandleWidth;
  final dragHandleThickness =
      merged.dragHandleThickness ?? CoreDrawerStyle.defaultDragHandleThickness;
  final dragHandleInset =
      merged.dragHandleInset ?? CoreDrawerStyle.defaultDragHandleInset;
  final dragHandleBorderRadius =
      (merged.dragHandleBorderRadius ??
              CoreDrawerStyle.defaultDragHandleBorderRadius)
          .toValue();
  final openDurationMs =
      (merged.openAnimationDuration ??
              CoreDrawerStyle.defaultOpenAnimationDuration)
          .inMilliseconds;
  final closeDurationMs =
      (merged.closeAnimationDuration ??
              CoreDrawerStyle.defaultCloseAnimationDuration)
          .inMilliseconds;
  // Shadow base colour flows through the single Core source
  // (`defaultShadowBaseColor` = `shadow` token). Web EMIT is theme-free
  // — `.toValue()` emits `rgb(var(--coui-shadow))` and the browser
  // resolves it at runtime (no `scheme.resolve`, a no-op on Web).
  final shadowBase =
      (merged.shadowBaseColor ?? CoreDrawerStyle.defaultShadowBaseColor)
          .toValue();
  final panelBoxShadowCss = emitShadow(shadowLayers, base: shadowBase);
  // Panel extent — width drives `left` / `right` drawers, height drives
  // `top` / `bottom`, emitted inline as `rem` (single-signature; never
  // a `w-*` / `h-*` Tailwind class drop). Width falls back to the
  // design-system default; height has none — null = content-sized (the
  // docked panel's `height: auto` wraps its content, capped by the
  // `max-height` viewport rule), matching the Flutter route's
  // unconstrained SizedBox.
  final panelWidth = merged.panelWidth ?? CoreDrawerStyle.defaultPanelWidth;
  final panelHeight = merged.panelHeight;
  final durationMs = open ? openDurationMs : closeDurationMs;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs) —
  // `CoreEasing.enter` (`ease-out`) is the existing curve for both
  // the barrier fade and panel slide, unchanged in value.
  final transitionTiming =
      '${durationMsCss(durationMs)} ${CoreEasing.enter.toVarCss()}';
  // The return from a rubber band: its own duration (a transition-tier token,
  // so `prefers-reduced-motion` zeroes it) and its own curve — the one
  // Flutter drives through `Cubic`.
  final settleMs = CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds;
  final settleTiming =
      '${durationMsCss(settleMs)} '
      '${CoreDrawerRubberBand.defaultSettleEasing.toVarCss()}';
  // Which of the two the panel's transform eases with: the return after a
  // release, or the slide.
  final panelTiming = rubberBand && settling ? settleTiming : transitionTiming;
  // Docked-edge longhand radius zeroing — the two viewport-facing
  // corners keep the resolved `panelBorderRadius` (emitted via the full
  // `border-radius` shorthand), the two edge-flush corners are zeroed
  // with `border-<edge>-<corner>-radius: 0` longhands selected per
  // [CoreDrawerSide] (no corner-value reach-in).
  final dockedCornerProps = _dockedCornerRadiusProperties(side);
  // The segment the panel keeps to. On a viewport a fold splits the panel
  // docks inside one segment — the one its edge lies in, and where the fold
  // meets that edge the upper one or the one at the reading start — as the
  // Flutter route lays it out in the same segment. The rule that names it is
  // the one both platforms read, so the panel opens on the same side. Null
  // where nothing splits the viewport, and the panel docks to it as before.
  final fold = context.dependOnInheritedComponentOfExactType<FoldLayoutScope>();
  final foldLayout = fold?.layout;
  final (edgeX, edgeY) = switch (side) {
    .left => (-1.0, 0.0),
    .right => (1.0, 0.0),
    .top => (0.0, -1.0),
    .bottom => (0.0, 1.0),
  };
  final segment = foldLayout != null && foldLayout.isSplit
      ? foldLayout.segmentIndexAligned(edgeX, edgeY, fold!.direction)
      : null;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer overlay wrapper `<div>` Tailwind className —
  /// pins barrier + panel to the viewport.
  String buildRootClassName() =>
      '${WebLayout.fixed} ${WebLayout.insetZero} z-${CoreZIndex.scale.z50}';

  /// Composes the barrier `<div>` Tailwind className — stretches
  /// behind the panel; opacity flip lives inline.
  String buildBarrierClassName() =>
      '${WebLayout.absoluteFull} z-${CoreZIndex.scale.z40}';

  /// Composes the barrier inline-CSS bundle — colour + opacity flip
  /// + matching transition duration + pointer-events gate. While a
  /// swipe scrubs the panel (`openProgress` non-null) the opacity
  /// tracks the finger with no transition, and the barrier never
  /// intercepts the pointer that is driving it.
  Styles buildBarrierInlineStyles() => .new(
    raw: {
      // Web EMIT is theme-free — the token emits `rgb(var(--coui-X))`
      // and the browser resolves it (dark-mode reactive at runtime).
      // No `scheme.resolve` (a no-op on Web).
      'background-color': barrierColor.toValue(),
      if (openProgress != null) ...{
        'opacity': '$openProgress',
        'transition': 'none',
        'pointer-events': 'none',
      } else ...{
        'opacity': open ? '1' : '0',
        'transition': 'opacity $transitionTiming',
        'pointer-events': open ? 'auto' : 'none',
      },
    },
  );

  /// Composes the panel `<div>` Tailwind className. Per-side docking +
  /// the docked-edge border live on the className. Colour defaults emit
  /// the design-system token class and drop to an inline rule when an
  /// override is present; radius / size / border-width are always
  /// emitted inline (single signature — no `w-*` / `h-*` class drop).
  String buildPanelClassName() {
    final sideClasses = switch (side) {
      .left => [
        WebLayout.topZero,
        WebLayout.leftZero,
        WebLayout.bottomZero,
        'border-r',
      ],
      .right => [
        WebLayout.topZero,
        WebLayout.rightZero,
        WebLayout.bottomZero,
        'border-l',
      ],
      .top => [
        WebLayout.topZero,
        WebLayout.leftZero,
        WebLayout.rightZero,
        'border-b',
      ],
      .bottom => [
        WebLayout.bottomZero,
        WebLayout.leftZero,
        WebLayout.rightZero,
        'border-t',
      ],
    }.join(' ');
    final bgClass = merged.panelBackgroundColor == null
        ? 'bg-${CoreDrawerStyle.defaultPanelBackgroundColor.tailwindColor}'
        : '';
    final borderColorClass = merged.panelBorderColor == null
        ? 'border-${CoreDrawerStyle.defaultPanelBorderColor.tailwindColor}'
        : '';
    return [
      // A docked panel is a surface by the same reasoning the popup and
      // the dialog already carry the marker: it draws its own fill, and
      // the page it slid over is still there behind it. Paired with the
      // fill published below — carrying the marker without publishing
      // resolves the preset's restated colour to nothing and the panel
      // loses its background instead of turning translucent.
      ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
      WebLayout.absolute,
      'z-${CoreZIndex.scale.z50}',
      WebLayout.flex,
      WebLayout.flexCol,
      bgClass,
      borderColorClass,
      sideClasses,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the panel `<div>` inline-CSS bundle — transform (slide
  /// or drag), transition (suppressed mid-drag), shadow, full
  /// `border-radius` shorthand with the docked-edge corners zeroed via
  /// longhand, docked-edge border width, extent (width or height), and
  /// colour overrides. Radius / size / border-width are always inline
  /// (single signature) — `panelBackgroundColor` / `panelBorderColor`
  /// emit inline only when overridden (token class otherwise).
  Styles buildPanelInlineStyles() {
    final dragging = dragDelta != 0;
    final scrubbing = openProgress != null;
    // Stretched past the dock: scaled along the slide axis about the docked
    // edge, so the edge stays on the viewport edge while the far one moves.
    final stretching = rubberBand && open && stretch > 0 && stretchExtent > 0;
    final openTranslate = dragging
        ? _dragTranslate(isHorizontal: isHorizontal, dragDelta: dragDelta)
        : stretching
        ? _stretchTransform(
            isHorizontal: isHorizontal,
            scale: CoreDrawerRubberBand.scaleOf(
              stretch,
              extent: stretchExtent,
            ),
          )
        : 'translateX(0) translateY(0)';
    // A swipe-to-open scrub positions the panel between its closed and
    // docked translate by the finger's progress (percentage-based, so
    // no pixel measurement is needed) with the transition suppressed —
    // the finger IS the animation.
    final translate = scrubbing
        ? _scrubTranslate(side, openProgress)
        : open
        ? openTranslate
        : _closedTranslate(side);

    final raw = {
      'transform': translate,
      'transition': dragging || stretching || scrubbing
          ? 'none'
          : 'transform $panelTiming',
      // The fixed point of the stretch. Stated at rest as well, or the
      // origin would jump between the frame the pointer lets go and the
      // frame the return starts.
      if (rubberBand) 'transform-origin': _dockOrigin(side),
      // No shadow by default: an empty stack has no layer to ride the rim on
      // (the rim decorates a surface that casts), so the declaration is
      // dropped rather than left as a dangling comma.
      if (shadowLayers.isNotEmpty)
        'box-shadow': '$panelBoxShadowCss, $kSurfaceRimVar',
      // Full shorthand carries the resolved radius on every corner …
      'border-radius': panelBorderRadius.toValue(),
      // … then the two docked-edge corners are flattened so the panel
      // sits flush against the viewport edge.
      for (final prop in dockedCornerProps) prop: '0',
      _dockedEdgeWidthProperty(side): strokeWidthCss(panelBorderWidth),
      // The drag is the panel's own: a touch that starts outside the
      // scrolling body drives it rather than panning the page — the body
      // is a scroll container of its own, so it still scrolls (the Flutter
      // twin's gesture arena gives a scrollable the drag the same way).
      if (draggable) 'touch-action': 'none',
      // Extent on the slide axis — inline `rem` (no class drop). A
      // vertical panel without an explicit height stays `height: auto`
      // (content-sized) and is capped at the viewport so tall content
      // scrolls inside the `overflow-auto` content wrapper instead of
      // growing past the screen (Flutter parity: the route's loose,
      // screen-bounded constraints).
      if (isHorizontal)
        'width': '${panelWidth / kRemDivisor}rem'
      else ...{
        if (panelHeight != null) 'height': '${panelHeight / kRemDivisor}rem',
        'max-height': '100%',
      },
    };
    // Colour overrides emit inline only when the caller supplied one; the
    // token default stays on the className above. Web EMIT is theme-free —
    // `.toValue()` emits `rgb(var(--coui-X))` for a token override (no
    // `scheme.resolve`, a no-op on Web).
    if (merged.panelBackgroundColor != null) {
      raw['background-color'] = panelBackgroundColor.toValue();
    }
    if (merged.panelBorderColor != null) {
      raw['border-color'] = panelBorderColor.toValue();
    }
    // The other half of the marker above: a preset restates the fill as
    // the same token at a lower alpha, and it cannot know which token
    // this panel chose. So the panel publishes the triplet.
    raw.addAll(surfaceFillVar(panelBackgroundColor));
    // The panel is already flush with the viewport edge it docks to, so the
    // fill needs no extra geometry — only the content has to stay clear of
    // the inset. Padding the docked edge by the browser's reported inset
    // does that while the surface (fill, border, shadow) keeps reaching the
    // edge. Zero unless the page opts into `viewport-fit=cover`. Pinned —
    // the device's inset, not spacing.
    if (fillSafeArea) {
      raw[_dockedEdgePaddingProperty(side)] =
          'env(${_dockedSafeAreaInsetVariable(side)}, '
          '${pinnedLengthCss(0)})';
    }
    if (segment != null) {
      // Docked to the segment's own edges instead of the viewport's. The
      // geometry is the browser's (`env(viewport-segment-*)`), so the panel
      // follows the fold exactly; only which segment is decided by the rule.
      // The edge the panel slides in from is the viewport's as well as the
      // segment's, so the slide is unchanged.
      String edge(String name) => foldLayout!.segmentEnvCss(segment, name);
      final right = 'calc(100% - ${edge('left')} - ${edge('width')})';
      final bottom = 'calc(100% - ${edge('top')} - ${edge('height')})';
      raw.addAll(switch (side) {
        .left => {
          'left': edge('left'),
          'top': edge('top'),
          'bottom': bottom,
          'max-width': edge('width'),
        },
        .right => {
          'right': right,
          'top': edge('top'),
          'bottom': bottom,
          'max-width': edge('width'),
        },
        .top => {
          'top': edge('top'),
          'left': edge('left'),
          'right': right,
          'max-height': edge('height'),
        },
        .bottom => {
          'bottom': bottom,
          'left': edge('left'),
          'right': right,
          'max-height': edge('height'),
        },
      });
    }
    return Styles(raw: raw);
  }

  /// Composes the header row `<div>` Tailwind className — flex row,
  /// docked-edge 1px bottom divider. Colour defaults to the class (from
  /// `Divider`'s own shared default — #4815 디자이너 결정 #1, not the
  /// panel's own border token) and drops to an inline rule when
  /// [dividerColor] is overridden (same split as `panelBorderColor`
  /// above).
  String buildHeaderClassName() {
    final dividerColorClass = merged.dividerStyle?.color == null
        ? 'border-${CoreDividerStyle.defaultColor.tailwindColor}'
        : '';
    return [
      WebLayout.flex,
      WebLayout.itemsStart,
      WebLayout.justifyBetween,
      if (dividerThickness == null) 'border-b',
      dividerColorClass,
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the header row inline-CSS bundle — header padding via
  /// `toValue()`, plus the divider colour override (if any).
  Styles buildHeaderInlineStyles() {
    final raw = {
      'padding': headerPadding.toValue(),
      'gap': spaceCss(headerSpacing),
      // The Flutter twin's `Divider` is as tall as its thickness, so a
      // stated 0 draws no rule and takes no space on either platform.
      if (dividerThickness != null)
        'border-bottom-width': strokeWidthCss(dividerThickness),
      if (merged.dividerStyle?.color != null)
        'border-color': dividerColor.toValue(),
    };
    return Styles(raw: raw);
  }

  /// Composes the title wrapper `<div flex-1>` Tailwind className —
  /// inherits the `Text(title)` Text chain typography by default.
  String buildTitleWrapClassName() => WebLayout.flex1;

  /// Composes the title wrapper inline-CSS bundle — overlays the nested
  /// `titleStyle` slot on the design-system `defaultTitleStyle`
  /// (`onSurface` tone) and translates the result into `font-*` / `color`
  /// rules so the `Text(title)` chain inherits them via the CSS cascade.
  /// The `titleMedium` role typography is supplied by the `Text(title)`
  /// Text chain (the slot's token is carried but never emitted here);
  /// this bundle layers the resolved tone + any override on top
  /// (sb-text-style-repackage). Returns `null` when the overlay is empty.
  Styles? buildTitleWrapInlineStyles() {
    final style = CoreDrawerStyle.defaultTitleStyle.merge(
      merged.titleStyle,
    );
    final color = style.color;
    final raw = <String, String>{
      // Typography overrides (font-size / font-weight / line-height /
      // letter-spacing) flow through `toInlineCss`; `color` is dropped so
      // it emits separately via the theme-free `.toValue()` token path.
      ...style.toInlineCss(includeColor: false),
      // Web EMIT is theme-free — the token emits `rgb(var(--coui-X))`
      // (no `scheme.resolve`, a no-op on Web).
      'color': ?color?.toValue(),
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the heading column `<div>` className — title over
  /// description.
  String buildHeadingClassName() => WebLayout.flexCol;

  /// Composes the description `<div>` className — wraps long words, plus
  /// the role and tone classes.
  String buildDescriptionClassName() => [
    WebLayout.breakWords,
    descriptionEmit.className,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the description inline-CSS bundle — the emit's overlay, or
  /// nothing when the classes carry the whole style.
  Styles? buildDescriptionInlineStyles() {
    final inline = descriptionEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the grab-handle box `<div>` className — centres the pill
  /// and never gives up its room.
  String buildHandleClassName() => [
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    WebLayout.shrinkZero,
  ].join(' ');

  /// Composes the grab-handle box inline-CSS bundle — the space around
  /// the pill. The handle never pans the page under a touch.
  Styles buildHandleInlineStyles() => .new(
    raw: {'padding': spaceCss(dragHandleInset), 'touch-action': 'none'},
  );

  /// Composes the grab-handle pill className — the colour class on the
  /// token path.
  String buildHandlePillClassName() => dragHandleEmit.className;

  /// Composes the grab-handle pill inline-CSS bundle — length along the
  /// edge (vertical on a side drawer), thickness across it, corner, and a
  /// raw colour.
  Styles buildHandlePillInlineStyles() {
    final length = '${dragHandleWidth / kRemDivisor}rem';
    final thickness = '${dragHandleThickness / kRemDivisor}rem';
    return .new(
      raw: {
        'width': isHorizontal ? thickness : length,
        'height': isHorizontal ? length : thickness,
        'border-radius': dragHandleBorderRadius,
        ...?dragHandleEmit.inline,
      },
    );
  }

  /// Composes the footer row `<div>` Tailwind className — flex row pushed to
  /// the end, a hairline above it (the colour class from `Divider`'s own
  /// shared default, like the header rule), never giving up its room.
  String buildFooterClassName() => [
    WebLayout.flex,
    WebLayout.justifyEnd,
    WebLayout.shrinkZero,
    'border-t',
    if (merged.dividerStyle?.color == null)
      'border-${CoreDividerStyle.defaultColor.tailwindColor}',
  ].join(' ');

  /// Composes the footer row inline-CSS bundle — its padding, and the rule's
  /// stated colour or thickness when the caller gave one.
  Styles buildFooterInlineStyles() => .new(
    raw: {
      'padding': footerPadding.toValue(),
      if (dividerThickness != null)
        'border-top-width': strokeWidthCss(dividerThickness),
      if (merged.dividerStyle?.color != null)
        'border-color': dividerColor.toValue(),
    },
  );

  /// Composes the panel-content `<div>` Tailwind className — flex-1
  /// fill, scroll overflow. Padding is emitted inline.
  String buildContentClassName() =>
      '${WebLayout.flex1} ${WebLayout.overflowAuto}';

  /// Composes the panel-content inline-CSS bundle — content padding via
  /// `toValue()`, and, on a draggable panel whose body content fits along
  /// the slide axis, the touch handed to the panel's drag: the body is a
  /// scroll container, so a touch on it would otherwise pan it.
  Styles buildContentInlineStyles() => .new(
    raw: {
      'padding': panelPadding.toValue(),
      if (draggable && bodyFits) 'touch-action': 'none',
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDrawer(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: Styles(
        raw: {
          // Not design tokens — UA popover style resets. The widget
          // promotes this root into the browser top layer (Popover
          // API) and the UA popover stylesheet would otherwise apply
          // fit-content sizing, auto margins, a solid border, padding,
          // canvas colours and overflow:auto. Author declarations win
          // over UA popover styles at normal specificity; identical
          // no-ops when the promotion is unavailable.
          'width': '100%',
          'height': '100%',
          'margin': spaceCss(0),
          'border': 'none',
          'padding': spaceCss(0),
          'background': 'transparent',
          'overflow': 'visible',
          'color': 'inherit',
          // While a swipe scrubs the panel the whole overlay must be
          // transparent to the pointer — the viewport-covering root
          // would otherwise become the event target and starve the
          // gesture surface underneath of its move events (DOM targets
          // the topmost element under the cursor; there is no implicit
          // capture).
          if (openProgress != null) 'pointer-events': 'none',
        },
      ),
    ),
    barrier: WebElementChrome(
      className: buildBarrierClassName(),
      inlineStyles: buildBarrierInlineStyles(),
    ),
    panel: WebElementChrome(
      className: buildPanelClassName(),
      inlineStyles: buildPanelInlineStyles(),
    ),
    header: WebElementChrome(
      className: buildHeaderClassName(),
      inlineStyles: buildHeaderInlineStyles(),
    ),
    titleWrap: WebElementChrome(
      className: buildTitleWrapClassName(),
      inlineStyles: buildTitleWrapInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    footer: WebElementChrome(
      className: buildFooterClassName(),
      inlineStyles: buildFooterInlineStyles(),
    ),
    closeButtonStyle: closeButtonStyle,
    heading: WebElementChrome(className: buildHeadingClassName()),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    handle: WebElementChrome(
      className: buildHandleClassName(),
      inlineStyles: buildHandleInlineStyles(),
    ),
    handlePill: WebElementChrome(
      className: buildHandlePillClassName(),
      inlineStyles: buildHandlePillInlineStyles(),
    ),
    sideRow: const WebElementChrome(
      className: '${WebLayout.flex} ${WebLayout.flex1} ${WebLayout.minHZero}',
    ),
    sideBody: const WebElementChrome(
      className:
          '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.flex1} '
          '${WebLayout.minWZero}',
    ),
  );
}

/// Returns the two `border-<edge>-<corner>-radius` longhand property
/// names for the panel's docked edge — the panel emits the resolved
/// radius on every corner via the `border-radius` shorthand, then
/// zeroes these two so the docked side sits flush to the viewport
/// edge. No corner-value reach-in (single-signature: the shorthand
/// already carries the resolved radius).
List<String> _dockedCornerRadiusProperties(CoreDrawerSide side) =>
    switch (side) {
      .left => const [
        'border-top-left-radius',
        'border-bottom-left-radius',
      ],
      .right => const [
        'border-top-right-radius',
        'border-bottom-right-radius',
      ],
      .top => const [
        'border-top-left-radius',
        'border-top-right-radius',
      ],
      .bottom => const [
        'border-bottom-left-radius',
        'border-bottom-right-radius',
      ],
    };

/// Returns the CSS property name for the panel's single docked-edge
/// border width (`border-right-width` for a left drawer, etc.).
String _dockedEdgeWidthProperty(CoreDrawerSide side) => switch (side) {
  .left => 'border-right-width',
  .right => 'border-left-width',
  .top => 'border-bottom-width',
  .bottom => 'border-top-width',
};

/// Returns the CSS padding property on the panel's docked edge
/// (`padding-bottom` for a bottom sheet, etc.) — the edge
/// `CoreDrawerContract.fillSafeArea` pads by the safe-area inset.
String _dockedEdgePaddingProperty(CoreDrawerSide side) => switch (side) {
  .left => 'padding-left',
  .right => 'padding-right',
  .top => 'padding-top',
  .bottom => 'padding-bottom',
};

/// Returns the `env()` safe-area inset name for the panel's docked edge.
String _dockedSafeAreaInsetVariable(CoreDrawerSide side) => switch (side) {
  .left => 'safe-area-inset-left',
  .right => 'safe-area-inset-right',
  .top => 'safe-area-inset-top',
  .bottom => 'safe-area-inset-bottom',
};

/// Closed-state translate value — the panel's off-screen position
/// and the exit transform when the drag crosses the dismiss
/// threshold.
/// The panel translate at swipe progress [progress] (0 = closed,
/// 1 = docked) — a percentage interpolation of [_closedTranslate].
String _scrubTranslate(CoreDrawerSide side, double progress) {
  final remaining = (1 - progress.clamp(0.0, 1.0)) * kPercentScale;
  return switch (side) {
    .left => 'translateX(-$remaining%)',
    .right => 'translateX($remaining%)',
    .top => 'translateY(-$remaining%)',
    .bottom => 'translateY($remaining%)',
  };
}

String _closedTranslate(CoreDrawerSide side) => switch (side) {
  .left => 'translateX(-100%)',
  .right => 'translateX(100%)',
  .top => 'translateY(-100%)',
  .bottom => 'translateY(100%)',
};

/// Live transform applied while a drag is in progress — translates
/// the panel by [dragDelta] along the slide axis.
String _dragTranslate({
  required bool isHorizontal,
  required double dragDelta,
}) {
  final px = '${dragDelta / kRemDivisor}rem';
  return isHorizontal ? 'translateX($px)' : 'translateY($px)';
}

/// The panel stretched by [scale] along its slide axis. Keeps the idle
/// `translateX(0) translateY(0)` in front, so a transition back to rest
/// pairs the functions one for one and the scale is what is interpolated.
String _stretchTransform({required bool isHorizontal, required double scale}) =>
    isHorizontal
    ? 'translateX(0) translateY(0) scaleX($scale)'
    : 'translateX(0) translateY(0) scaleY($scale)';

/// The edge a panel is docked to, as a `transform-origin` — the point its
/// stretch is anchored at.
String _dockOrigin(CoreDrawerSide side) => switch (side) {
  .left => 'left center',
  .right => 'right center',
  .top => 'center top',
  .bottom => 'center bottom',
};
