import 'package:coui_flutter/coui_flutter.dart';

/// Resolved window style values after applying the nested-merge chain
/// (`CoreWindowStyle.defaultX` > `CoreWindowTheme.style` >
/// `widget.windowStyle`).
///
/// Every field is paint-ready (concrete `Color` / `BorderRadius` /
/// `EdgeInsets` / `double` with scaling already folded in) so the widget
/// reads `resolved.X` straight into the paint site — no `scheme.resolve`,
/// `.toValue()`, merge, or token fallback in the widget body.
class ResolvedWindow {
  /// Creates a [ResolvedWindow].
  const ResolvedWindow({
    required this.titleBarHeight,
    required this.resizeThickness,
    required this.snapBarTileSpacing,
    required this.snapBarPadding,
    required this.snapBarPaddingInsets,
    required this.snapPreviewBorderRadius,
    required this.snapBarBorderRadius,
    required this.snapTileBorderRadius,
    required this.snapTileInnerBorderRadius,
    required this.snapBarShadow,
    required this.snapBarBorderColor,
    required this.snapBarBackgroundColor,
    required this.snapPreviewBorderColor,
    required this.snapPreviewBackgroundColor,
    required this.snapPreviewBlurSigma,
    required this.snapTileBorderColor,
    required this.snapTileBorderWidth,
    required this.snapTileIdleBackgroundColor,
    required this.snapTileHoverBackgroundColor,
    required this.unfocusedTitleStyle,
    required this.snapBarBorderWidth,
    required this.snapBarHeight,
    required this.snapBarTopOffset,
    required this.snapBarHiddenOffset,
    required this.snapBarAnimation,
    required this.snapTileSpacing,
    required this.windowTransition,
    required this.minimizedScale,
    required this.closeAnimationScaleMin,
    required this.closeAnimationScaleMax,
    required this.panelStyleFloating,
    required this.panelStyleMaximized,
  });

  /// Title bar height in logical pixels (already includes the caller's
  /// requested scaling — callers should *not* multiply again).
  final double titleBarHeight;

  /// Thickness of each of the 8 resize hit regions in logical pixels
  /// (already includes scaling).
  ///
  /// The pre-scaling value is a widget-plane behaviour parameter
  /// (`Window.resizeThickness` — a hit region paints nothing); the
  /// resolver only folds `theme.scaling` into it, because the size
  /// factor is an EMIT step and widgets never multiply by `scaling`
  /// (`resolver/scaling-and-gap.md` Anti-Pattern C).
  final double resizeThickness;

  /// Spacing between adjacent snap-bar tiles in logical pixels (already
  /// includes scaling). Applied as native `Row.spacing`.
  final double snapBarTileSpacing;

  /// Raw domain inner padding of the snap-bar banner, forwarded into the
  /// nested `CoreOutlinedContainerStyle.padding` slot whose own resolver
  /// applies `theme.scaling` (so this value carries NO scaling).
  final CoreEdgeInsets snapBarPadding;

  /// Paint-ready inner padding of the snap-preview blur container in
  /// logical pixels (scaling already applied — callers should *not*
  /// multiply again). Mirrors [snapBarPadding] for the paint site that
  /// needs a Flutter `EdgeInsets` instead of forwarding the raw domain
  /// value into a nested `CoreXxxStyle.padding` slot.
  final EdgeInsets snapBarPaddingInsets;

  /// Paint-ready border radius for the floating snap-preview overlay
  /// (merged from `CoreWindowStyle.defaultSnapPreviewBorderRadius`).
  final BorderRadius snapPreviewBorderRadius;

  /// Raw domain border radius of the snap-bar banner container (merged
  /// from `CoreWindowStyle.defaultSnapBarBorderRadius`), forwarded into the
  /// nested `CoreOutlinedContainerStyle.borderRadius` slot whose own
  /// resolver applies the theme geometry.
  final CoreBorderRadius snapBarBorderRadius;

  /// Paint-ready corner of a snap-bar tile on the preset's outer edge
  /// (merged from `CoreWindowStyle.defaultSnapTileBorderRadius`).
  final BorderRadius snapTileBorderRadius;

  /// Paint-ready corner of a snap-bar tile on an edge it shares with a
  /// sibling tile (merged from
  /// `CoreWindowStyle.defaultSnapTileInnerBorderRadius`).
  final BorderRadius snapTileInnerBorderRadius;

  /// Raw drop shadow of the snap-bar banner (merged from
  /// `CoreWindowStyle.defaultSnapBarShadow`), forwarded into the nested
  /// `CoreOutlinedContainerStyle.boxShadow` slot whose own resolver tints it
  /// and applies the scheme's shadow strength.
  final List<CoreShadowLayer> snapBarShadow;

  /// Raw domain outline colour of the snap-bar banner container,
  /// forwarded into the nested `CoreOutlinedContainerStyle.borderColor`
  /// slot whose own resolver applies `scheme.resolve` (from
  /// `CoreWindowStyle.defaultSnapBarBorderColor` — same token the Web
  /// resolver emits, so a style override recolours both platforms).
  final CoreColor snapBarBorderColor;

  /// Raw domain surface fill of the snap-bar banner container, forwarded
  /// into the nested `CoreOutlinedContainerStyle.backgroundColor` slot
  /// (from `CoreWindowStyle.defaultSnapBarBackgroundColor`).
  final CoreColor snapBarBackgroundColor;

  /// Paint-ready outline colour of the floating snap-preview overlay
  /// border (from `CoreWindowStyle.defaultSnapPreviewBorderColor`).
  final Color snapPreviewBorderColor;

  /// Paint-ready semi-transparent surface fill of the snap-preview
  /// overlay (from `CoreWindowStyle.defaultSnapPreviewBackgroundColor`,
  /// opacity baked in).
  final Color snapPreviewBackgroundColor;

  /// Paint-ready outline colour of each snap-bar tile border (from
  /// `CoreWindowStyle.defaultSnapTileBorderColor`).
  final Color snapTileBorderColor;

  /// Snap-bar tile border width (logical px, geometry-bent + scaling
  /// pre-applied — `_SnapHoverState` paints this directly via
  /// `Border.all`, so unlike `snapBarBorderWidth` this is not
  /// raw-forwarded into a self-resolving child).
  final double snapTileBorderWidth;

  /// Paint-ready surface fill of a snap-bar tile at rest (from
  /// `CoreWindowStyle.defaultSnapTileBackgroundColor`).
  final Color snapTileIdleBackgroundColor;

  /// Paint-ready fill of a snap-bar tile while hovered (from
  /// `CoreWindowStyle.defaultSnapTileHoverBackgroundColor`).
  final Color snapTileHoverBackgroundColor;

  /// Gaussian σ of the snap-preview ghost's backdrop blur (from
  /// `CoreWindowStyle.defaultSnapPreviewBlurSigma`). Deliberately NOT
  /// scaled — a blur radius is a visual effect, not a layout length,
  /// and the Web mirror emits the same σ as raw CSS px.
  final double snapPreviewBlurSigma;

  /// Raw domain title-text overlay for every window EXCEPT the frontmost
  /// one, forwarded into the nested `CoreWindowPanelStyle.titleStyle`
  /// slot whose own resolver performs the token EMIT (from
  /// `CoreWindowStyle.defaultUnfocusedTitleStyle` — colour-only, so the
  /// panel's title typography role/weight stay intact).
  final CoreTextStyle unfocusedTitleStyle;

  /// Raw domain border width of the snap-bar banner container,
  /// forwarded into the nested `CoreOutlinedContainerStyle.borderWidth`
  /// slot (from `CoreWindowStyle.defaultSnapBarBorderWidth`).
  final double snapBarBorderWidth;

  /// Snap-bar banner height in logical pixels (pre-scaling — forwarded
  /// into the nested `CoreOutlinedContainerStyle.height` slot whose own
  /// resolver applies `theme.scaling`).
  final double snapBarHeight;

  /// Top offset of the expanded snap-bar banner (already scaled).
  final double snapBarTopOffset;

  /// Resting "peek" pose of the hidden snap-bar as a fraction of its
  /// height (−1 = fully hidden, 0 = fully shown); also the start of
  /// the content fade-in. Fractions carry no unit — no scaling.
  final double snapBarHiddenOffset;

  /// Snap-bar drop-down show/hide animation duration.
  final Duration snapBarAnimation;

  /// Inner gap between abutting snap-bar tiles (already scaled).
  final double snapTileSpacing;

  /// Window open / close / maximize transition duration.
  final Duration windowTransition;

  /// Scale of the window while minified during a drag-snap (unitless).
  final double minimizedScale;

  /// Lower bound of the close-animation scale tween (unitless).
  final double closeAnimationScaleMin;

  /// Upper bound of the close-animation scale tween (unitless).
  final double closeAnimationScaleMax;

  /// Raw domain chrome for the composed `WindowPanel` while FLOATING or
  /// partially snapped — nested slot raw-forwarded into the panel whose
  /// own resolver settles the final chrome.
  final CoreWindowPanelStyle panelStyleFloating;

  /// Raw domain panel chrome while FULL-maximized — the merged
  /// [panelStyleFloating] with the corner radius forced to zero (the
  /// frame sits flush with every desktop edge). Widget selects between
  /// the two by the runtime maximize state.
  final CoreWindowPanelStyle panelStyleMaximized;
}

/// Resolves the effective window style — single entry point.
///
/// Merge chain (Epic #1302 nested-merge):
/// `CoreWindowStyle.defaultX` → `CoreWindowTheme.style` →
/// `widget.windowStyle`. The `theme.coreComponentTheme` lookup is
/// encapsulated here so the widget `build` never touches it directly.
ResolvedWindow resolveWindow(
  BuildContext context, {
  double resizeThickness = CoreWindowContract.defaultResizeThickness,
  CoreWindowStyle? windowStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.window;
  final scaling = theme.scaling;

  // Merge chain: theme.style → widget.windowStyle. Each non-null field
  // on the right wins.
  final merged = resolveStyleChain(const CoreWindowStyle(), [
    coreTheme?.style,
    windowStyle,
  ]);

  // Dimensional locals fold `* scaling` at their definition site so the
  // return literal stays a bare mapping (resolver-pattern.md: no synthesis,
  // including `* scaling`, in the return block).
  final titleBarHeight =
      (merged.titleBarHeight ?? CoreWindowStyle.defaultTitleBarHeight) *
      scaling;
  // Behaviour value in, paint-ready extent out: the hit-region thickness
  // arrives from `Window.resizeThickness` and only gets the density
  // multiplier here.
  final resizeExtent = resizeThickness * scaling;
  final snapBarTileSpacing =
      theme.geometry.space(
        merged.snapBarTileSpacing ?? CoreWindowStyle.defaultSnapBarTileSpacing,
      ) *
      scaling;
  final snapBarPadding =
      merged.snapBarPadding ?? CoreWindowStyle.defaultSnapBarPadding;
  final snapBarPaddingInsets =
      snapBarPadding.toValue(geometry: theme.geometry) * scaling;

  // Border radii — paint-ready `BorderRadius` (no scaling on radius; the
  // legacy navigator path never scaled the snap corners).
  final snapPreviewBorderRadius =
      (merged.snapPreviewBorderRadius ??
              CoreWindowStyle.defaultSnapPreviewBorderRadius)
          .toValue(geometry: theme.geometry);
  final snapBarBorderRadius =
      merged.snapBarBorderRadius ?? CoreWindowStyle.defaultSnapBarBorderRadius;
  final snapTileBorderRadius =
      (merged.snapTileBorderRadius ??
              CoreWindowStyle.defaultSnapTileBorderRadius)
          .toValue(geometry: theme.geometry);
  final snapTileInnerBorderRadius =
      (merged.snapTileInnerBorderRadius ??
              CoreWindowStyle.defaultSnapTileInnerBorderRadius)
          .toValue(geometry: theme.geometry);
  final snapBarShadow =
      merged.snapBarShadow ?? CoreWindowStyle.defaultSnapBarShadow;

  // Snap-bar banner chrome — Stage 1 RESOLVE only (raw `CoreColor`):
  // the values raw-forward into the nested `CoreOutlinedContainerStyle`
  // slots, whose own resolver performs the token EMIT. Same Core tokens
  // the Web resolver consumes via `emitColor`, closing the
  // 1:1:1:1:1:1 chain for `snapBarBorderColor` / `snapBarBackgroundColor`.
  final snapBarBorderColor =
      merged.snapBarBorderColor ?? CoreWindowStyle.defaultSnapBarBorderColor;
  final snapBarBackgroundColor =
      merged.snapBarBackgroundColor ??
      CoreWindowStyle.defaultSnapBarBackgroundColor;

  // Snap-surface chrome colours — Flutter EMIT
  // (`scheme.resolve(token).toValue()`) so a `CoreWindowStyle` override
  // wins and the snap surfaces stay 1:1:1:1:1:1 with the Web resolver's
  // `emitColor(merged.X, default, target)` path.
  final snapPreviewBorderColor = scheme
      .resolve(
        merged.snapPreviewBorderColor ??
            CoreWindowStyle.defaultSnapPreviewBorderColor,
      )
      .toValue();
  final snapPreviewBackgroundColor = scheme
      .resolve(
        merged.snapPreviewBackgroundColor ??
            CoreWindowStyle.defaultSnapPreviewBackgroundColor,
      )
      .toValue();
  final snapTileBorderColor = scheme
      .resolve(
        merged.snapTileBorderColor ??
            CoreWindowStyle.defaultSnapTileBorderColor,
      )
      .toValue();
  final snapTileBorderWidth = theme.geometry.stroke(
    merged.snapTileBorderWidth ?? CoreWindowStyle.defaultSnapTileBorderWidth,
    scaling: scaling,
  );
  final snapTileIdleBackgroundColor = scheme
      .resolve(
        merged.snapTileBackgroundColor ??
            CoreWindowStyle.defaultSnapTileBackgroundColor,
      )
      .toValue();
  final snapTileHoverBackgroundColor = scheme
      .resolve(
        merged.snapTileHoverBackgroundColor ??
            CoreWindowStyle.defaultSnapTileHoverBackgroundColor,
      )
      .toValue();

  // Unfocused-title overlay — Stage 1 RESOLVE only (raw `CoreTextStyle`):
  // raw-forwards into the nested `CoreWindowPanelStyle.titleStyle` slot,
  // whose own resolver performs the token EMIT.
  final unfocusedTitleStyle = CoreWindowStyle.defaultUnfocusedTitleStyle.merge(
    merged.unfocusedTitleStyle,
  );

  // Blur σ — effect radius, not a layout length: no scaling (Web parity).
  final snapPreviewBlurSigma =
      merged.snapPreviewBlurSigma ??
      CoreWindowStyle.defaultSnapPreviewBlurSigma;

  // Snap-bar geometry / animation poses — the height stays raw
  // (forwarded into the nested `CoreOutlinedContainerStyle.height` slot
  // whose own resolver scales); the top offset is a translate distance
  // this widget paints directly, so it scales here. Fractions and
  // durations carry no unit.
  final snapBarBorderWidth =
      merged.snapBarBorderWidth ?? CoreWindowStyle.defaultSnapBarBorderWidth;
  final snapBarHeight =
      merged.snapBarHeight ?? CoreWindowStyle.defaultSnapBarHeight;
  final snapBarTopOffset =
      (merged.snapBarTopOffset ?? CoreWindowStyle.defaultSnapBarTopOffset) *
      scaling;
  final snapBarHiddenOffset =
      merged.snapBarHiddenOffset ?? CoreWindowStyle.defaultSnapBarHiddenOffset;
  final snapBarAnimation =
      merged.snapBarAnimation ?? CoreWindowStyle.defaultSnapBarAnimation;
  final snapTileSpacing =
      theme.geometry.space(
        merged.snapTileSpacing ?? CoreWindowStyle.defaultSnapTileSpacing,
      ) *
      scaling;
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

  // Composed-panel chrome — Stage 1 RESOLVE only (partial nested
  // style, raw-forwarded; the panel resolver fills its own defaults).
  // The maximized bundle forces the radius to zero ON TOP of the merge
  // so the flush-to-edge look wins over a per-instance radius override.
  final panelStyleFloating = CoreWindowStyle.defaultPanelStyle.merge(
    merged.panelStyle,
  );
  // guard-nested-override: borderRadius — maximized flush-to-edge wins
  // over caller `panelStyle.borderRadius`; there is no dedicated
  // override path for this pose (maximized always squares off).
  final panelStyleMaximized = panelStyleFloating.copyWith(
    borderRadius: .zero,
  );

  return ResolvedWindow(
    titleBarHeight: titleBarHeight,
    resizeThickness: resizeExtent,
    snapBarTileSpacing: snapBarTileSpacing,
    snapBarPadding: snapBarPadding,
    snapBarPaddingInsets: snapBarPaddingInsets,
    snapPreviewBorderRadius: snapPreviewBorderRadius,
    snapBarBorderRadius: snapBarBorderRadius,
    snapTileBorderRadius: snapTileBorderRadius,
    snapTileInnerBorderRadius: snapTileInnerBorderRadius,
    snapBarShadow: snapBarShadow,
    snapBarBorderColor: snapBarBorderColor,
    snapBarBackgroundColor: snapBarBackgroundColor,
    snapPreviewBorderColor: snapPreviewBorderColor,
    snapPreviewBackgroundColor: snapPreviewBackgroundColor,
    snapPreviewBlurSigma: snapPreviewBlurSigma,
    snapTileBorderColor: snapTileBorderColor,
    snapTileBorderWidth: snapTileBorderWidth,
    snapTileIdleBackgroundColor: snapTileIdleBackgroundColor,
    snapTileHoverBackgroundColor: snapTileHoverBackgroundColor,
    unfocusedTitleStyle: unfocusedTitleStyle,
    snapBarBorderWidth: snapBarBorderWidth,
    snapBarHeight: snapBarHeight,
    snapBarTopOffset: snapBarTopOffset,
    snapBarHiddenOffset: snapBarHiddenOffset,
    snapBarAnimation: snapBarAnimation,
    snapTileSpacing: snapTileSpacing,
    windowTransition: windowTransition,
    minimizedScale: minimizedScale,
    closeAnimationScaleMin: closeAnimationScaleMin,
    closeAnimationScaleMax: closeAnimationScaleMax,
    panelStyleFloating: panelStyleFloating,
    panelStyleMaximized: panelStyleMaximized,
  );
}
