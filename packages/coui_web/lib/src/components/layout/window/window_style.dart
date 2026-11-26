import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Resolved window-navigator style after the nested-merge chain
/// (`CoreWindowStyle.defaultX` > `CoreWindowTheme.style` >
/// `widget.windowStyle`).
///
/// DOM shape (navigator root):
///
/// ```text
/// root (<div>)                              // navigator root (relative w-full h-full overflow-hidden)
///   ├─ background child (optional)
///   ├─ <div data-co-window>                 // per-window absolute container (positioned by co_window)
///   │     ├─ WindowPanel
///   │     └─ resizer<edge> (8)              // see ResolvedWindowResizer
///   ├─ snapPreview (<div>)                  // dragging snap-preview overlay
///   └─ snapBar (<div>)                      // floating snap bar
///        └─ snapBarContainer (<div>)        // bar background
///             └─ snapTile (<div>) (...)     // see ResolvedWindowSnapTile
/// ```
///
/// `root`, `snapPreview`, `snapBarContainer` are exposed as
/// `WebElementChrome` slots so the widget never composes the chrome
/// itself. Per-edge resizer chrome and per-tile snap chrome have their
/// own per-instance resolvers ([resolveWindowResizer] /
/// [resolveWindowSnapTile]) because they carry runtime state (edge,
/// hovering) that varies between instances.
///
/// The behavioural dimensional metrics (`titleBarHeight`) are NOT
/// carried here — they are layout / hit-test scalars read by the
/// navigator's stateful drag-snap detection, not paint chrome. The
/// widget reads them from the merge chain via [resolveWindowMetrics]
/// (the number_ticker separate-resolver pattern). The resize hit-region
/// thickness is not even that: it paints nothing, so it is a widget
/// parameter (`Window.resizeThickness`).
class ResolvedWindow implements WebResolvedChrome {
  /// Creates a [ResolvedWindow].
  const ResolvedWindow({
    required this.root,
    required this.snapPreview,
    required this.snapBarContainer,
    required this.snapBarContent,
  });

  /// Paint-ready chrome for the navigator root `<div>` —
  /// `relative w-full h-full overflow-hidden` Tailwind classes.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the snap-preview overlay `<div>` —
  /// semi-transparent surface fill + outline border + rounded field
  /// corners + backdrop blur. Positioning / sizing / z-index / pointer
  /// events stay in `co_window` because they depend on the runtime
  /// snap rectangle.
  final WebElementChrome snapPreview;

  /// Paint-ready chrome for the snap-bar container `<div>` (the
  /// background of the floating bar that drops down from the top of
  /// the navigator). Carries the padding + rounded corners + border +
  /// surface background box.
  final WebElementChrome snapBarContainer;

  /// Paint-ready chrome for the bar's content row `<div>` (the preset
  /// tile groups) — flex row + stretch + gap + full height. Kept as a
  /// separate slot so the widget can fade the CONTENT with the bar's
  /// expansion (Flutter drives the same content opacity from its
  /// translate tween) without fading the container box itself.
  final WebElementChrome snapBarContent;
}

/// Resolves the effective window style — single entry point.
///
/// Merge chain (Epic #1302 nested-merge):
/// `CoreWindowStyle.defaultX` → `CoreWindowTheme.style` →
/// `widget.windowStyle`. The `coreComponentTheme` lookup is encapsulated
/// here so the widget `build` never touches it directly. The
/// closure-local element builders compose every chrome slot once and
/// store the results on the resolved output so the widget reads them
/// straight back.
ResolvedWindow resolveWindow(
  BuildContext context, {
  CoreWindowStyle? windowStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.window;

  // Merge chain: theme.style → widget.windowStyle. Each non-null field
  // on the right wins.
  final merged = resolveStyleChain(const CoreWindowStyle(), [
    coreTheme?.style,
    windowStyle,
  ]);

  // Radius / gap / padding are always emitted inline through the single
  // `(merged.X ?? default)` signature (Epic #1603) so the override path
  // and the default path share one CSS surface — never a Tailwind radius
  // / gap / padding utility class branch.
  final snapPreviewBorderRadius =
      (merged.snapPreviewBorderRadius ??
              CoreWindowStyle.defaultSnapPreviewBorderRadius)
          .toValue();
  final snapBarBorderRadius =
      (merged.snapBarBorderRadius ?? CoreWindowStyle.defaultSnapBarBorderRadius)
          .toValue();
  // The banner's own cast, emitted through the same converter the window
  // frame's shadow uses. The trailing `kSurfaceRimVar` layer is the rim a
  // casting surface takes under claymorphism — the bar is a marked surface
  // (`webSurfaceMarkerFor` below) and states its own shadow, so it carries
  // that layer the way its Flutter twin's `OutlinedContainer` does.
  final snapBarCast = emitShadow(
    merged.snapBarShadow ?? CoreWindowStyle.defaultSnapBarShadow,
    base: const CoreColor.token(CoreColors.shadow).toValue(),
  );
  final snapBarShadow = '$snapBarCast, $kSurfaceRimVar';
  final snapBarTileSpacing =
      merged.snapBarTileSpacing ?? CoreWindowStyle.defaultSnapBarTileSpacing;
  final snapBarPadding =
      (merged.snapBarPadding ?? CoreWindowStyle.defaultSnapBarPadding)
          .toValue();
  final snapPreviewBlurSigma =
      merged.snapPreviewBlurSigma ??
      CoreWindowStyle.defaultSnapPreviewBlurSigma;
  final snapBarHeight =
      merged.snapBarHeight ?? CoreWindowStyle.defaultSnapBarHeight;
  final snapBarBorderWidth =
      merged.snapBarBorderWidth ?? CoreWindowStyle.defaultSnapBarBorderWidth;

  // Colour chrome flows through the single `emitColor(merged.X, default,
  // target)` entry point — token-bound values emit a Tailwind class
  // (`border-outline` / `bg-surface/40` …), raw overrides emit inline —
  // so Web never reaches `cs.<token>` directly and the snap surfaces stay
  // 1:1:1:1:1:1 with `CoreWindowStyle.defaultX`.
  final snapPreviewBorder = emitColor(
    merged.snapPreviewBorderColor,
    CoreWindowStyle.defaultSnapPreviewBorderColor,
    .border,
  );
  final snapPreviewBackground = emitColor(
    merged.snapPreviewBackgroundColor,
    CoreWindowStyle.defaultSnapPreviewBackgroundColor,
    .background,
  );
  final snapBarBorder = emitColor(
    merged.snapBarBorderColor,
    CoreWindowStyle.defaultSnapBarBorderColor,
    .border,
  );
  final snapBarBackground = emitColor(
    merged.snapBarBackgroundColor,
    CoreWindowStyle.defaultSnapBarBackgroundColor,
    .background,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the navigator root `<div>` chrome — relative positioning
  /// context that clips all floating windows and overlays. `isolation:
  /// isolate` opens a stacking context so the window/snap-bar z-indexes
  /// compete only among themselves — without it they escape into the
  /// page's root stacking context and paint over the host app's own
  /// layered chrome (e.g. a sticky site header).
  WebElementChrome buildRootChrome() => const .new(
    className:
        '${WebLayout.relative} ${WebLayout.wFull} ${WebLayout.hFull} '
        '${WebLayout.overflowHidden}',
    inlineStyles: Styles(raw: {'isolation': 'isolate'}),
  );

  /// Composes the snap-preview overlay `<div>` chrome — semi-transparent
  /// surface fill with field-rounded corners, outline border and
  /// backdrop blur; matches the Flutter `_BlurContainer`. Colour comes
  /// from the `emitColor` results (class XOR inline); border radius is
  /// emitted inline via the single `(merged ?? default).toValue()`
  /// signature. Positioning and sizing flow through `co_window` because
  /// they depend on the runtime snap rectangle.
  WebElementChrome buildSnapPreviewChrome() => .new(
    className: [
      '${WebLayout.absolute} border',
      snapPreviewBorder.className,
      snapPreviewBackground.className,
    ].where((c) => c.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {
        ...?snapPreviewBorder.inline,
        ...?snapPreviewBackground.inline,
        'border-radius': snapPreviewBorderRadius,
        // σ is a Gaussian blur radius shared verbatim with Flutter
        // `ImageFilter.blur(sigma)` — a blur, not a layout length, so
        // it deliberately does not track the accessibility text scale.
        // Inline (single emit path) — no preset class, so the value
        // stays overridable through `CoreWindowStyle.snapPreviewBlurSigma`.
        'backdrop-filter':
            'blur(${snapPreviewBlurSigma}px)', // design-token: viewport-pixel
      },
    ),
  );

  /// Composes the snap-bar container `<div>` chrome — outline border +
  /// surface background (from the `emitColor` results), plus inline
  /// padding / radius emitted through the single `(merged ?? default)`
  /// signature. The tile row layout lives on the content slot.
  WebElementChrome buildSnapBarContainerChrome() => .new(
    className: [
      snapBarBorder.className,
      snapBarBackground.className,
      // Marks the bar as a component surface, so a material preset
      // reaches it. Its Flutter twin gets the same treatment by
      // composing `OutlinedContainer(role: .functional)`. Unconditional
      // — the fill always resolves to a real, opaque design token
      // (`CoreWindowStyle.defaultSnapBarBackgroundColor`), never a
      // transparent sentinel. Role `functional` — a floating drag
      // affordance over content, not a content-layer panel.
      ...webSurfaceMarkerFor(.functional),
    ].where((c) => c.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {
        ...?snapBarBorder.inline,
        ...?snapBarBackground.inline,
        'padding': snapBarPadding,
        'border-radius': snapBarBorderRadius,
        'box-shadow': snapBarShadow,
        // Stroke width flows through the single `(merged ?? default)`
        // inline signature (same slot the Flutter `OutlinedContainer`
        // stroke reads), so an override rewidths both platforms.
        'border-style': 'solid',
        'border-width': strokeWidthCss(snapBarBorderWidth),
        ...surfaceBleedVar(strokeWidthCss(snapBarBorderWidth)),
        // Explicit border-box height so the bar's OUTER height matches
        // the Flutter `OutlinedContainer(height:)` exactly — without it
        // the bar grew to content + padding + border (2px taller).
        'height': '${snapBarHeight}px', // design-token: viewport-pixel
        // The other half of the surface marker above.
        ...surfaceFillVar(
          merged.snapBarBackgroundColor ??
              CoreWindowStyle.defaultSnapBarBackgroundColor,
        ),
      },
    ),
  );

  /// Composes the bar's content row `<div>` chrome — the flex layout +
  /// gap for the preset tile groups (runtime opacity stays in the
  /// widget since it tracks the live expansion state).
  WebElementChrome buildSnapBarContentChrome() => .new(
    className: '${WebLayout.flexRowItemsStretch} ${WebLayout.hFull}',
    inlineStyles: Styles(
      raw: {'gap': spaceCss(snapBarTileSpacing)},
    ),
  );

  return ResolvedWindow(
    root: buildRootChrome(),
    snapPreview: buildSnapPreviewChrome(),
    snapBarContainer: buildSnapBarContainerChrome(),
    snapBarContent: buildSnapBarContentChrome(),
  );
}

/// Resolves the behavioural window metrics — the layout / hit-test /
/// motion scalars consumed by the navigator's stateful drag-snap
/// detection, the resize-handle layout loop and the CSS transition
/// strings (between builds), not paint chrome.
///
/// Walks the same merge chain as [resolveWindow]
/// (`CoreWindowStyle.defaultX` → `CoreWindowTheme.style` →
/// `widget.windowStyle`). Kept as a separate `resolveCo*` entry point so
/// [ResolvedWindow] stays pure paint-ready chrome (number_ticker
/// separate-resolver pattern). Web uses CSS px 1:1 so no scaling is
/// applied.
({
  double titleBarHeight,
  CoreEdgeInsets snapBarPadding,
  double snapBarHeight,
  double snapBarTopOffset,
  double snapBarHiddenOffset,
  Duration snapBarAnimation,
  String snapBarContentHeightCss,
  double snapTileSpacing,
  Duration windowTransition,
  double minimizedScale,
  double closeAnimationScaleMin,
  double closeAnimationScaleMax,
  CoreTextStyle unfocusedTitleStyle,
  CoreWindowPanelStyle panelStyleFloating,
  CoreWindowPanelStyle panelStyleMaximized,
})
resolveWindowMetrics(BuildContext context, {CoreWindowStyle? windowStyle}) {
  final coreTheme = context.theme.coreComponentTheme?.window;
  final merged = resolveStyleChain(const CoreWindowStyle(), [
    coreTheme?.style,
    windowStyle,
  ]);
  // Stage 1 RESOLVE — locals only; the return literal below stays a
  // bare mapping (resolver-pattern.md: no `??` / `.merge()` synthesis
  // inside the return block).
  final titleBarHeight =
      merged.titleBarHeight ?? CoreWindowStyle.defaultTitleBarHeight;
  // The ghost preview draws inset from the snap area by the same bar
  // padding — the Flutter mirror pads its `_BlurContainer` with this
  // slot, so the ghost floats inside the navigator frame instead of
  // sitting on its border.
  final snapBarPadding =
      merged.snapBarPadding ?? CoreWindowStyle.defaultSnapBarPadding;
  final snapBarHeight =
      merged.snapBarHeight ?? CoreWindowStyle.defaultSnapBarHeight;
  final snapBarTopOffset =
      merged.snapBarTopOffset ?? CoreWindowStyle.defaultSnapBarTopOffset;
  final snapBarHiddenOffset =
      merged.snapBarHiddenOffset ?? CoreWindowStyle.defaultSnapBarHiddenOffset;
  final snapBarAnimation =
      merged.snapBarAnimation ?? CoreWindowStyle.defaultSnapBarAnimation;
  final snapTileSpacing =
      merged.snapTileSpacing ?? CoreWindowStyle.defaultSnapTileSpacing;
  final windowTransition =
      merged.windowTransition ?? CoreWindowStyle.defaultWindowTransition;
  final minimizedScale =
      merged.minimizedScale ?? CoreWindowStyle.defaultMinimizedScale;
  final closeAnimationScaleMin =
      merged.closeAnimationScaleMin ??
      CoreWindowStyle.defaultCloseAnimationScaleMin;
  final closeAnimationScaleMax =
      merged.closeAnimationScaleMax ??
      CoreWindowStyle.defaultCloseAnimationScaleMax;
  final snapBarBorderWidth =
      merged.snapBarBorderWidth ?? CoreWindowStyle.defaultSnapBarBorderWidth;
  // Inner height available to the preset tile groups: the bar's
  // border-box height minus its padding and the border stroke the bar
  // chrome folds into the content inset on both edges — mirrors the
  // Flutter Row inside the padded `OutlinedContainer(height:)`.
  //
  // A CSS length, not a number: the bar's own `padding` rides the
  // spacing variables (the Flutter mirror bends the same `CoreEdgeInsets`
  // through the theme geometry) and its border the stroke variables, so
  // both are subtracted through them too — a Dart sum would size the
  // groups for the authored values while a density (or a stroke preset)
  // re-maps the ones the bar draws.
  final snapBarContentHeightCss =
      'calc(${snapBarHeight}px - ' // design-token: viewport-pixel
      '2 * ${strokeWidthCss(snapBarBorderWidth)} - '
      '${spaceCss(snapBarPadding.top)} - '
      '${spaceCss(snapBarPadding.bottom)})';
  // Unfocused-title overlay — raw-forwards into the nested
  // `CoreWindowPanelStyle.titleStyle` slot (Flutter mirror).
  final unfocusedTitleStyle = CoreWindowStyle.defaultUnfocusedTitleStyle.merge(
    merged.unfocusedTitleStyle,
  );
  // Panel-chrome bundles raw-forwarded into the nested `WindowPanel`
  // slot: the floating pose keeps the merged corner radius, a FULL
  // maximize squares it off (window flush with every desktop edge) and
  // wins over any per-instance `panelStyle.borderRadius` override — the
  // widget selects between the two already-resolved bundles.
  final panelStyleFloating = CoreWindowStyle.defaultPanelStyle.merge(
    merged.panelStyle,
  );
  // guard-nested-override: borderRadius — maximized flush-to-edge wins
  // over caller `panelStyle.borderRadius`; there is no dedicated
  // override path for this pose (maximized always squares off).
  final panelStyleMaximized = panelStyleFloating.copyWith(
    borderRadius: .zero,
  );
  return (
    titleBarHeight: titleBarHeight,
    snapBarPadding: snapBarPadding,
    snapBarHeight: snapBarHeight,
    snapBarTopOffset: snapBarTopOffset,
    snapBarHiddenOffset: snapBarHiddenOffset,
    snapBarAnimation: snapBarAnimation,
    snapBarContentHeightCss: snapBarContentHeightCss,
    snapTileSpacing: snapTileSpacing,
    windowTransition: windowTransition,
    minimizedScale: minimizedScale,
    closeAnimationScaleMin: closeAnimationScaleMin,
    closeAnimationScaleMax: closeAnimationScaleMax,
    unfocusedTitleStyle: unfocusedTitleStyle,
    panelStyleFloating: panelStyleFloating,
    panelStyleMaximized: panelStyleMaximized,
  );
}

// ═══════════════════════════════════════════════════
// Per-edge resizer chrome
// ═══════════════════════════════════════════════════

/// Resolved per-edge resize-handle chrome for one of the 8 resize hit
/// regions on a window frame.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // 1 of 8 resize hit regions (absolute + cursor + position)
/// ```
class ResolvedWindowResizer implements WebResolvedChrome {
  /// Creates a [ResolvedWindowResizer].
  const ResolvedWindowResizer({required this.root});

  /// Paint-ready chrome for the resize-handle `<div>` — `absolute
  /// select-none` Tailwind classes plus per-edge inline positioning
  /// (`top` / `bottom` / `left` / `right` / `width` / `height`) and
  /// the matching `cursor`.
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedWindowResizer] for one of the 8 resize edges of
/// a floating window.
///
/// [positionCss] is the per-edge anchoring map (computed from the edge
/// + thickness in `co_window`); [cursor] is the matching CSS cursor
/// (`n-resize`, `nw-resize`, …). The resolver folds both into the
/// `root` `WebElementChrome` so the widget reads `resolved.root.*`
/// straight back into `div(...)`.
ResolvedWindowResizer resolveWindowResizer({
  required Map<String, String> positionCss,
  required String cursor,
}) {
  return ResolvedWindowResizer(
    root: WebElementChrome(
      className: '${WebLayout.absolute} select-none',
      inlineStyles: Styles(
        raw: {
          ...positionCss,
          'cursor': cursor,
        },
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Per-tile snap-bar tile chrome
// ═══════════════════════════════════════════════════

/// Resolved per-tile snap-bar tile chrome.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // 1 tile inside the floating snap bar
/// ```
class ResolvedWindowSnapTile implements WebResolvedChrome {
  /// Creates a [ResolvedWindowSnapTile].
  const ResolvedWindowSnapTile({required this.root});

  /// Paint-ready chrome for the snap-bar tile `<div>` — `absolute
  /// border` Tailwind classes plus per-tile inline positioning
  /// (`left` / `top` / `width` / `height`), per-corner border-radius,
  /// hover-driven background colour token, and pointer cursor.
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedWindowSnapTile] for one tile inside the floating
/// snap bar. Pre-composes the className (outline border + hover-driven
/// surface / secondary background token) and the inline-CSS positioning
/// + per-corner radius + cursor so the widget reads
/// `resolved.root.*` straight back into `div(...)`.
///
/// The per-corner `*Tight` booleans (true when the corner abuts another
/// tile) pick the tight field radius
/// ([CoreWindowStyle.defaultSnapPreviewBorderRadius]) versus the loose
/// banner radius ([CoreWindowStyle.defaultSnapBarBorderRadius]); the
/// resolver folds them into a single [CoreBorderRadius] and emits the
/// CSS through the shared [CoreBorderRadiusToCss.toValue] util so token
/// corners flow through the `--coui-radius-N` CSS variables.
ResolvedWindowSnapTile resolveWindowSnapTile(
  BuildContext context, {
  required bool hovering,
  required String leftCss,
  required String topCss,
  required String widthCss,
  required String heightCss,
  required bool topLeftTight,
  required bool topRightTight,
  required bool bottomLeftTight,
  required bool bottomRightTight,
}) {
  final coreTheme = context.theme.coreComponentTheme?.window;
  final merged = resolveStyleChain(const CoreWindowStyle(), [coreTheme?.style]);

  // Border + idle/hover background flow through the single `emitColor`
  // entry point (class XOR inline) so Web never reaches `cs.<token>`
  // directly. The hover/idle select picks between two already-resolved
  // background emits — a pure runtime-state select, never a token reach-in.
  final tileBorder = emitColor(
    merged.snapTileBorderColor,
    CoreWindowStyle.defaultSnapTileBorderColor,
    .border,
  );
  final tileIdleBackground = emitColor(
    merged.snapTileBackgroundColor,
    CoreWindowStyle.defaultSnapTileBackgroundColor,
    .background,
  );
  final tileHoverBackground = emitColor(
    merged.snapTileHoverBackgroundColor,
    CoreWindowStyle.defaultSnapTileHoverBackgroundColor,
    .background,
  );
  final tileBackground = hovering ? tileHoverBackground : tileIdleBackground;
  final tileBorderWidth = strokeWidthCss(
    merged.snapTileBorderWidth ?? CoreWindowStyle.defaultSnapTileBorderWidth,
  );

  // Tight corner = abuts a sibling tile → the tile's inner radius; loose
  // corner = outer edge of the preset → the tile's outer radius. Both pull
  // from the single `(merged ?? default)` signature, the same fields the
  // Flutter tile reads. The per-corner tight/loose selection lives inside
  // the shared `CoreBorderRadiusToCss.pickCornersValue` util (no per-corner
  // reach-in in the resolver itself).
  final tight =
      merged.snapTileInnerBorderRadius ??
      CoreWindowStyle.defaultSnapTileInnerBorderRadius;
  final loose =
      merged.snapTileBorderRadius ??
      CoreWindowStyle.defaultSnapTileBorderRadius;
  final borderRadius = loose.pickCornersValue(
    tight: tight,
    topLeftTight: topLeftTight,
    topRightTight: topRightTight,
    bottomLeftTight: bottomLeftTight,
    bottomRightTight: bottomRightTight,
  );

  final className = [
    '${WebLayout.absolute} border',
    tileBorder.className,
    tileBackground.className,
  ].where((c) => c.isNotEmpty).join(' ');

  return ResolvedWindowSnapTile(
    root: WebElementChrome(
      className: className,
      inlineStyles: Styles(
        raw: {
          ...?tileBorder.inline,
          ...?tileBackground.inline,
          'left': leftCss,
          'top': topCss,
          'width': widthCss,
          'height': heightCss,
          'border-radius': borderRadius,
          'border-width': tileBorderWidth,
          'cursor': 'pointer',
        },
      ),
    ),
  );
}
