import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling for [WindowPanel].
///
/// Single struct the widget reads — the nested-merge chain
/// (`CoreWindowPanelStyle.defaultX` → `CoreWindowPanelTheme.style` →
/// `widget.windowPanelStyle`) is applied once by [resolveWindowPanel].
/// Every chrome colour / typography value is pre-resolved here (paint-
/// ready Flutter [Color] / [TextStyle]) so the widget never reads
/// `theme.colorScheme.*` / `theme.typography.*` directly.
class ResolvedWindowPanel {
  /// Creates a [ResolvedWindowPanel].
  const ResolvedWindowPanel({
    required this.borderRadius,
    required this.titleBarColor,
    required this.titleBarHeight,
    required this.titleBarPadding,
    required this.contentPadding,
    required this.controlSpacing,
    required this.containerBorderWidth,
    required this.boxShadow,
    required this.insetBoxShadow,
    required this.insetRadius,
    required this.containerStyle,
    required this.titleTextStyle,
    required this.contentTextStyle,
    required this.controlButtonStyle,
    required this.closeButtonStyle,
    required this.controlIconStyle,
  });

  /// Effective outer border radius.
  final BorderRadiusGeometry borderRadius;

  /// Effective title bar background colour.
  final Color titleBarColor;

  /// Title bar height (already scaled).
  final double titleBarHeight;

  /// Padding inside the title bar (already scaled).
  final EdgeInsets titleBarPadding;

  /// Content area padding (already scaled).
  final EdgeInsets contentPadding;

  /// Spacing between adjacent control buttons (already scaled).
  ///
  /// Consumed natively by `Row(spacing: …)` so the N control buttons sit
  /// on a single flex strip with equal inter-sibling spacing — no manual
  /// `SizedBox` interleave.
  final double controlSpacing;

  /// Effective container border width (already scaled) — drives both the
  /// outer frame border and the inner title-bar radius shrink.
  final double containerBorderWidth;

  /// Effective drop-shadow stack — the `md` step of the shadow scale unless
  /// the style states its own. Painted on a `DecoratedBox` **outside** the
  /// composed `OutlinedContainer` — the frame's own `shadowColor` is a
  /// style field, while `OutlinedContainer` casts from a hardcoded
  /// `CoreColors.shadow` base, so routing it through
  /// `containerStyle.boxShadow` would drop a tinted `shadowColor`.
  /// `containerStyle.boxShadow` is forced to an explicit empty stack so the
  /// composed primitive's own fallback cast does not double it.
  final List<BoxShadow> boxShadow;

  /// The active style's inset rim over the frame — empty under every style
  /// that states none.
  ///
  /// The frame casts its own shadow ([boxShadow]), so it takes the rim the
  /// way every casting panel does (`resolveSurfaceRim` gates on that
  /// stack). It cannot arrive through the composed `OutlinedContainer`: that
  /// primitive gates the rim on the stack *it* is handed, and the frame
  /// hands it an explicitly empty one so its shadow is not painted twice.
  /// The Web twin appends `kSurfaceRimVar` to the frame's own `box-shadow`.
  final List<BoxShadow> insetBoxShadow;

  /// The frame's painted corner, for [insetBoxShadow] to clip to — the
  /// radius the composed `OutlinedContainer` draws its box with (geometry
  /// bend and size scaling both applied), so the rim follows the box rather
  /// than [borderRadius]'s pre-scaling value.
  final BorderRadius insetRadius;

  /// Composed-`OutlinedContainer` chrome for the frame (fill / border /
  /// radius / material), pre-EMIT `CoreOutlinedContainerStyle`.
  /// `OutlinedContainer` runs the scheme-resolve / geometry / scaling
  /// bend itself — carrying Core values (not resolved Flutter ones)
  /// keeps that bend applied exactly once. Its own inner clip
  /// (`subtractByBorder`) replaces the previous manual `ClipRRect(
  /// _innerRadius(...))` — same border-minus-radius geometry, so the
  /// title bar's `_innerTopRadius` shaping stays redundant-but-harmless
  /// rather than load-bearing.
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready title text style — forwarded straight to
  /// `DefaultTextStyle(style: …)`. Font scaling is delegated to Flutter's
  /// `MediaQuery.textScaler`, so this style is not multiplied by
  /// `theme.scaling`.
  final TextStyle titleTextStyle;

  /// Paint-ready content area text style — forwarded straight to
  /// `DefaultTextStyle.merge(style: …)`.
  final TextStyle contentTextStyle;

  /// Raw domain chrome for the non-close control buttons — raw-forwarded
  /// into the unified `Button(variant: .plain)` whose own resolver
  /// settles the final chrome (child-component-composition).
  final CoreButtonStyle controlButtonStyle;

  /// Raw domain chrome for the close control button — raw-forwarded into
  /// the unified `Button(variant: .plain)`.
  final CoreButtonStyle closeButtonStyle;

  /// Raw domain control button icon geometry — raw-forwarded into `Icon`
  /// (colour inherits the button's per-state `IconTheme`).
  final CoreIconStyle controlIconStyle;
}

/// Resolves [ResolvedWindowPanel] for [WindowPanel] — single entry
/// point.
///
/// Merge chain (Epic #1302 nested-merge):
/// `CoreWindowPanelStyle.defaultX` → `CoreWindowPanelTheme.style` →
/// `widget.windowPanelStyle`. The `theme.coreComponentTheme` lookup is
/// encapsulated here so the widget `build` never touches it directly.
ResolvedWindowPanel resolveWindowPanel(
  BuildContext context, {
  CoreWindowPanelStyle? windowPanelStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.windowPanel;
  final scheme = theme.colorScheme;

  // Merge chain: theme.style → widget.windowPanelStyle. Each non-null
  // field on the right wins.
  final merged = resolveStyleChain(const CoreWindowPanelStyle(), [
    coreTheme?.style,
    windowPanelStyle,
  ]);

  final effectiveBorderRadius =
      (merged.borderRadius ?? CoreWindowPanelStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      );

  final titleBarCore =
      merged.titleBarColor ?? CoreWindowPanelStyle.defaultTitleBarColor;
  final effectiveTitleBarColor = scheme.resolve(titleBarCore).toValue();

  // Dimensional locals fold `* scaling` at their definition site so the
  // return literal stays a bare mapping (resolver-pattern.md: no synthesis,
  // including `* scaling`, in the return block).
  final titleBarHeight =
      (merged.titleBarHeight ?? CoreWindowPanelStyle.defaultTitleBarHeight) *
      scaling;
  final titleBarPadding =
      (merged.titleBarPadding ?? CoreWindowPanelStyle.defaultTitleBarPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final contentPadding =
      (merged.contentPadding ?? CoreWindowPanelStyle.defaultContentPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final controlSpacing =
      theme.geometry.space(
        merged.controlSpacing ?? CoreWindowPanelStyle.defaultControlSpacing,
      ) *
      scaling;
  final containerBorderWidth = theme.geometry.stroke(
    merged.containerBorderWidth ??
        CoreWindowPanelStyle.defaultContainerBorderWidth,
    scaling: scaling,
  );

  // ─── Nested control-button slots (Stage 1 RESOLVE only) ──
  // Partial `CoreButtonStyle` / `CoreIconStyle` raw-forwarded into the
  // unified `Button` / `Icon` whose own resolvers perform the token EMIT.
  final controlButtonStyle = CoreWindowPanelStyle.defaultControlButtonStyle
      .merge(merged.controlButtonStyle);
  final closeButtonStyle = CoreWindowPanelStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final controlIconStyle = CoreWindowPanelStyle.defaultControlIconStyle.merge(
    merged.controlIconStyle,
  );

  // ─── Typography (default.merge(override).toValue(theme:) — Flutter EMIT) ──
  // Title / content roles carry their own colour token (onSurface), so the
  // colour comes from `.toValue(theme:)` materialising the slot's colour.
  final titleTextStyle = CoreWindowPanelStyle.defaultTitleStyle
      .merge(merged.titleStyle)
      .toValue(theme: theme);
  final contentTextStyle = CoreWindowPanelStyle.defaultContentStyle
      .merge(merged.contentStyle)
      .toValue(theme: theme);

  // Frame drop shadow — geometry and base colour both resolve from the
  // Core single source (`CoreWindowPanelStyle.defaultShadow` /
  // `defaultShadowColor`) that the Web resolver consumes too, converted
  // through the shared `CoreShadowLayersToFlutter` adapter. The colour
  // resolves to opaque black and each layer carries its own alpha, so the
  // shadow reads correctly on any surface and follows the scheme's shadow
  // strength (`geometry:` below). Geometry is not
  // multiplied by `scaling` — the Web `box-shadow` never scales either
  // (draggable-panel precedent), so scaling it here would diverge the
  // silhouette on mobile.
  final shadowColor = scheme
      .resolve(merged.shadowColor ?? CoreWindowPanelStyle.defaultShadowColor)
      .toValue();
  final frameStack = merged.shadow ?? CoreWindowPanelStyle.defaultShadow;
  final boxShadow = frameStack.toValue(
    base: shadowColor,
    geometry: theme.geometry,
  );
  // The rim, gated on the frame's own stack — the same gate every casting
  // panel's rim goes through.
  final insetBoxShadow = resolveSurfaceRim(context, stack: frameStack);
  final insetRadius = effectiveBorderRadius * scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ────────────────
  // The frame is the box `Card` / `Fieldset` compose, not a hand-rolled
  // decoration (Epic #4349) — passing Core values (not resolved ones)
  // keeps the scheme-resolve / geometry / scaling bend applied exactly
  // once, by `OutlinedContainer` itself. The frame's own shadow is
  // painted separately (see [ResolvedWindowPanel.boxShadow]'s doc), so
  // this bundle's `boxShadow` is forced to an explicit empty stack.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.surfaceColor ?? CoreWindowPanelStyle.defaultSurfaceColor,
    borderColor: merged.borderColor ?? CoreWindowPanelStyle.defaultBorderColor,
    borderRadius:
        merged.borderRadius ?? CoreWindowPanelStyle.defaultBorderRadius,
    borderWidth:
        merged.containerBorderWidth ??
        CoreWindowPanelStyle.defaultContainerBorderWidth,
    boxShadow: const [],
  );

  return ResolvedWindowPanel(
    borderRadius: effectiveBorderRadius,
    titleBarColor: effectiveTitleBarColor,
    titleBarHeight: titleBarHeight,
    titleBarPadding: titleBarPadding,
    contentPadding: contentPadding,
    controlSpacing: controlSpacing,
    containerBorderWidth: containerBorderWidth,
    boxShadow: boxShadow,
    insetBoxShadow: insetBoxShadow,
    insetRadius: insetRadius,
    containerStyle: containerStyle,
    titleTextStyle: titleTextStyle,
    contentTextStyle: contentTextStyle,
    controlButtonStyle: controlButtonStyle,
    closeButtonStyle: closeButtonStyle,
    controlIconStyle: controlIconStyle,
  );
}
