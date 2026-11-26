import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `WindowPanel`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // outer frame (border, radius, surface, shadow, overflow:hidden)
///   ├─ titleBar (<div>)                     // height + padding + bg + gap
///   │     ├─ titleWrapper (<div>)           // flex-1 min-w-0
///   │     │     └─ title (<div>)            // typography + colour + truncate (when title present)
///   │     ├─ ?actions                        // caller-supplied
///   │     └─ controls (<div>)                // flex strip of control buttons
///   │           └─ Button ← CoreButtonStyle  // controlButtonStyle / closeButtonStyle
///   │                └─ Icon ← CoreIconStyle // controlIconStyle
///   └─ content (<div>)                       // flex-1 + padding + typography (when child + !isMinimized)
/// ```
///
/// `window_panel.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body. The control buttons are unified `Button(variant:
/// .plain)` compositions: the widget raw-forwards the nested
/// [controlButtonStyle] / [closeButtonStyle] / [controlIconStyle] slots
/// and selects the close slot by the runtime `isClose` flag.
class ResolvedWindowPanel implements WebResolvedChrome {
  /// Creates a [ResolvedWindowPanel].
  const ResolvedWindowPanel({
    required this.root,
    required this.titleBar,
    required this.titleWrapper,
    required this.title,
    required this.controls,
    required this.content,
    required this.controlButtonStyle,
    required this.closeButtonStyle,
    required this.controlIconStyle,
  });

  /// Paint-ready chrome for the outer panel `<div>` — flex column +
  /// outline border colour + surface background + the `md` shadow step +
  /// `overflow-hidden`, plus the inline `border-radius` (always emitted
  /// via `toValue()`) and the inline container `border-width` (px) so a
  /// per-instance override flows through 1:1:1:1.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the title bar row `<div>` — `flex
  /// items-center`, optional `bg-${surfaceContainer}` token class
  /// (dropped when the caller overrides `titleBarColor`), `shrink-0`.
  /// Inline styles carry the
  /// inner top radius (outer corners − container border-width), the
  /// height (inline rem) + gap (inline, through `spaceCss`), the
  /// horizontal padding, and the `background-color` override.
  final WebElementChrome titleBar;

  /// Paint-ready chrome for the title text wrapper `<div>` —
  /// `flex-1 min-w-0`.
  final WebElementChrome titleWrapper;

  /// Paint-ready chrome for the title text `<div>` — typography +
  /// colour Tailwind classes + truncate + select-none.
  final WebElementChrome title;

  /// Paint-ready chrome for the control buttons row `<div>` — flex
  /// strip with `items-center` plus the inter-button `gap` (always
  /// inline rem).
  final WebElementChrome controls;

  /// Paint-ready chrome for the content area `<div>` — `flex-1 +
  /// overflow-auto` + typography + colour Tailwind classes plus inline
  /// `padding` from the resolved content padding.
  final WebElementChrome content;

  /// Raw domain chrome for the non-close control buttons (minimize /
  /// maximize) — nested slot raw-forwarded into the unified
  /// `Button(variant: .plain)` whose own resolver performs the token
  /// EMIT (child-component-composition — the panel does not
  /// re-implement button chrome).
  final CoreButtonStyle controlButtonStyle;

  /// Raw domain chrome for the close control button — nested `Button`
  /// slot with the error-token emphasis.
  final CoreButtonStyle closeButtonStyle;

  /// Raw domain control button icon geometry — nested `Icon` slot
  /// (colour inherits the button's per-state foreground).
  final CoreIconStyle controlIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves `ResolvedWindowPanel` for `WindowPanel` — single entry
/// point.
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreWindowPanelStyle.defaultX)
///   → theme.coreComponentTheme.windowPanel.style
///   → widget.windowPanelStyle
/// ```
///
/// `borderRadius` flows through as a 4-corner [CoreBorderRadius] so the
/// Web inline CSS preserves per-corner values via the `border-radius`
/// shorthand (always inline `toValue()`). The inner title-bar radius is
/// derived from the same effective radius so a per-instance override
/// stays 1:1:1:1 with the Flutter side.
ResolvedWindowPanel resolveWindowPanel(
  BuildContext context, {
  CoreWindowPanelStyle? windowPanelStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.windowPanel;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreWindowPanelStyle(), [
    coreTheme?.style,
    windowPanelStyle,
  ]);

  // ─── Stage 1 RESOLVE — settle every value to a single source ──
  // Radius / padding / gap / size all emit inline via `(merged.X ??
  // default)` — no class-drop branch (Epic #1603 single-signature gate).
  final borderRadius =
      merged.borderRadius ?? CoreWindowPanelStyle.defaultBorderRadius;
  final effectiveTitleBarHeight =
      merged.titleBarHeight ?? CoreWindowPanelStyle.defaultTitleBarHeight;
  final effectiveTitleBarPadding =
      merged.titleBarPadding ?? CoreWindowPanelStyle.defaultTitleBarPadding;
  final effectiveContentPadding =
      merged.contentPadding ?? CoreWindowPanelStyle.defaultContentPadding;
  final effectiveControlSpacing =
      merged.controlSpacing ?? CoreWindowPanelStyle.defaultControlSpacing;
  final effectiveContainerBorderWidth =
      merged.containerBorderWidth ??
      CoreWindowPanelStyle.defaultContainerBorderWidth;

  // ─── Nested control-button slots (Stage 1 RESOLVE only) ──
  // Partial `CoreButtonStyle` / `CoreIconStyle` raw-forwarded into the
  // unified `Button(variant: .plain)` / `Icon` whose own resolvers
  // perform the token EMIT (child-component-composition — the panel
  // does not re-implement button chrome).
  final controlButtonStyle = CoreWindowPanelStyle.defaultControlButtonStyle
      .merge(merged.controlButtonStyle);
  final closeButtonStyle = CoreWindowPanelStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final controlIconStyle = CoreWindowPanelStyle.defaultControlIconStyle.merge(
    merged.controlIconStyle,
  );

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. No
  // `scheme.resolve` (a no-op on Web) and no hardcoded `cs.X` /
  // `typography.X` interpolation.
  final surfaceEmit = emitColor(
    merged.surfaceColor,
    CoreWindowPanelStyle.defaultSurfaceColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    CoreWindowPanelStyle.defaultBorderColor,
    .border,
  );
  // Title bar background — the design-system default token (surface
  // container); an override (token or raw) flows through the same emit
  // decision.
  final titleBarEmit = emitColor(
    merged.titleBarColor,
    CoreWindowPanelStyle.defaultTitleBarColor,
    .background,
  );
  final titleEmit = emitTypography(
    merged.titleStyle,
    CoreWindowPanelStyle.defaultTitleStyle,
  );
  final contentEmit = emitTypography(
    merged.contentStyle,
    CoreWindowPanelStyle.defaultContentStyle,
  );
  // Frame drop shadow — geometry and base colour both resolve from the
  // Core single source (`CoreWindowPanelStyle.defaultShadow` /
  // `defaultShadowColor`) that the Flutter resolver consumes too,
  // emitted through the shared `CoreShadowLayersToCss` converter (always
  // inline, matching the draggable-panel precedent — no shadow preset
  // alias to hand-sync).
  final shadowColor =
      (merged.shadowColor ?? CoreWindowPanelStyle.defaultShadowColor).toValue();
  // The trailing `kSurfaceRimVar` layer is claymorphism's one defining
  // material statement (a rim) — this frame is a marked surface
  // (`webSurfaceMarkerFor` below), so its box-shadow must carry that
  // extra layer or the rim never reaches it (check_surface_fill_contract.sh).
  final cast = emitShadow(
    merged.shadow ?? CoreWindowPanelStyle.defaultShadow,
    base: shadowColor,
  );
  final boxShadow = '$cast, $kSurfaceRimVar';

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer panel `<div>` chrome — flex column + border /
  /// surface emit-family classes + drop shadow + `overflow-hidden`. The
  /// corner radius, the container border width and the box shadow are
  /// always emitted inline (`toValue()` / rem) so a per-instance override
  /// (or the design-system default) flows through 1:1:1:1:1:1 — the same
  /// `containerBorderWidth` also drives the inner title-bar radius shrink.
  WebElementChrome buildRootChrome() => .new(
    className: [
      '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.overflowHidden}',
      borderEmit.className,
      surfaceEmit.className,
      // Marks this frame as a component surface, so a material preset
      // reaches it. Its Flutter twin gets the same treatment by
      // composing `OutlinedContainer`. Unconditional — the fill always
      // resolves to a real, opaque design token
      // (`CoreWindowPanelStyle.defaultSurfaceColor`), never a
      // transparent sentinel, so there is no fill-less-frame risk.
      ...webSurfaceMarkerFor(.functional),
      // The frame clips its content and keeps a border — a material that draws
      // its own edge reaches its band over that line (`kWebSurfaceClipMarker`).
      if (effectiveContainerBorderWidth > 0) kWebSurfaceClipMarker,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {
        'border-radius': borderRadius.toValue(),
        'border-style': 'solid',
        'border-width': strokeWidthCss(effectiveContainerBorderWidth),
        if (effectiveContainerBorderWidth > 0)
          ...surfaceClipFold(strokeWidthCss(effectiveContainerBorderWidth)),
        'box-shadow': boxShadow,
        ...?borderEmit.inline,
        ...?surfaceEmit.inline,
        // The other half of the surface marker above.
        ...surfaceFillVar(
          merged.surfaceColor ?? CoreWindowPanelStyle.defaultSurfaceColor,
        ),
      },
    ),
  );

  /// Composes the title bar row `<div>` chrome — `flex items-center`,
  /// title-bar background emit-family class, `shrink-0`. Inline styles
  /// carry the inner top radius (outer corners
  /// − container border-width), the height (inline rem) + gap (inline,
  /// through `spaceCss` — no class-drop), horizontal padding, and any raw
  /// colour overrides.
  WebElementChrome buildTitleBarChrome() {
    // No divider under the bar — its fill sets it apart from the content.
    final className = <String>[
      WebLayout.flexItemsCenter,
      titleBarEmit.className,
      WebLayout.shrinkZero,
    ].where((cls) => cls.isNotEmpty).join(' ');

    // Inner radius = outer corner radius − container border width, top
    // corners only, clamped at 0 so a small radius never goes negative.
    // Derived from the effective (default-or-override) radius + the
    // effective container border width so designer overrides stay
    // 1:1:1:1:1:1 with Flutter `_innerTopRadius`. The corner reach-in
    // stays inside the `core_to_css` util (`innerTopValue`).
    final raw = {
      'border-radius': borderRadius.innerTopValue(
        effectiveContainerBorderWidth,
      ),
      'height': '${effectiveTitleBarHeight / kRemDivisor}rem',
      'gap': spaceCss(effectiveControlSpacing),
      'padding': effectiveTitleBarPadding.toValue(),
      ...?titleBarEmit.inline,
    };
    return .new(
      className: className,
      inlineStyles: Styles(raw: raw),
    );
  }

  /// Composes the title text wrapper `<div>` chrome — `flex-1 min-w-0`.
  WebElementChrome buildTitleWrapperChrome() =>
      const .new(className: '${WebLayout.flex1} ${WebLayout.minWZero}');

  /// Composes the title text `<div>` chrome — title typography
  /// (`emitTypography`, role class + colour + weight overlay) + `truncate`
  /// + `select-none`.
  WebElementChrome buildTitleChrome() => .new(
    className: [
      titleEmit.className,
      '${WebLayout.truncate} select-none',
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: titleEmit.inline == null
        ? null
        : Styles(raw: {...?titleEmit.inline}),
  );

  /// Composes the controls row `<div>` chrome — `flex items-center` plus
  /// the inter-button `gap` (always inline, through `spaceCss` — no
  /// class-drop, Epic #1603 single-signature gate).
  WebElementChrome buildControlsChrome() => .new(
    className: WebLayout.flexItemsCenter,
    inlineStyles: Styles(
      raw: {'gap': spaceCss(effectiveControlSpacing)},
    ),
  );

  /// Composes the content area `<div>` chrome — `flex-1 overflow-auto` +
  /// content typography (`emitTypography`) + inline `padding` shorthand
  /// from the resolved content padding (always inline).
  WebElementChrome buildContentChrome() => .new(
    className: [
      '${WebLayout.flex1} ${WebLayout.overflowAuto}',
      contentEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {
        'padding': effectiveContentPadding.toValue(),
        ...?contentEmit.inline,
      },
    ),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedWindowPanel(
    root: buildRootChrome(),
    titleBar: buildTitleBarChrome(),
    titleWrapper: buildTitleWrapperChrome(),
    title: buildTitleChrome(),
    controls: buildControlsChrome(),
    content: buildContentChrome(),
    controlButtonStyle: controlButtonStyle,
    closeButtonStyle: closeButtonStyle,
    controlIconStyle: controlIconStyle,
  );
}
