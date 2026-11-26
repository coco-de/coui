import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Table] and [ResizableTable].
///
/// Single struct the widget reads — the nested-merge chain
/// (`CoreTableTheme.style` → `widget.theme.style` → `widget.tableStyle`)
/// plus design-system defaults, fallback and token conversion are all
/// applied once by [resolveTable]. Every chrome field is a plain,
/// ready-to-paint value (`Color` / `double` / `BorderRadius` /
/// `EdgeInsetsGeometry`); the nested text slots are folded into
/// paint-ready [TextStyle]s (typography role + slot override composed)
/// so the widget only binds the state-resolved foreground colour.
class ResolvedTable {
  /// Creates a [ResolvedTable].
  const ResolvedTable({
    required this.backgroundColor,
    required this.rowBackgroundColor,
    required this.rowAlternateBackgroundColor,
    required this.frozenCellBackgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.outerBorderWidth,
    required this.borderRadius,
    required this.headerCellPadding,
    required this.bodyCellPadding,
    required this.headerBackgroundColor,
    required this.frozenHeaderBackgroundColor,
    required this.footerBackgroundColor,
    required this.rowHoverColor,
    required this.rowSelectedColor,
    required this.headerHeight,
    required this.rowHeight,
    required this.resizerHoverColor,
    required this.resizerDragColor,
    required this.resizerThickness,
    required this.headerTextStyle,
    required this.cellTextStyle,
    required this.headerForegroundColor,
    required this.headerDisabledForegroundColor,
    required this.cellForegroundColor,
    required this.cellDisabledForegroundColor,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.boxShadow,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Table container background color. `null` keeps the container
  /// transparent (no explicit fill painted).
  final Color? backgroundColor;

  /// Body row base background color. `null` when no override is set —
  /// the widget then falls back to [backgroundColor] (or transparent).
  final Color? rowBackgroundColor;

  /// Even-body-row zebra-stripe background color. `null` when no
  /// override is set (no zebra stripe painted; the row keeps its base
  /// background).
  final Color? rowAlternateBackgroundColor;

  /// Explicit background color for frozen (sticky) body cells. `null`
  /// when no override is set — the widget then falls back to
  /// [rowBackgroundColor] / [backgroundColor] (still opaque by default,
  /// so frozen cells cover scrolling content without bleed-through; this
  /// field only wins when the caller wants a *distinct* frozen tint).
  /// Mirrors the Web resolver's `frozenCellBgOverride` 1:1 — override
  /// only, no design-system default.
  final Color? frozenCellBackgroundColor;

  /// Row / header separator colour; the outer box, when
  /// [outerBorderWidth] draws one, reads the same colour.
  final Color borderColor;

  /// Row / header separator width (logical px, already scaled).
  final double borderWidth;

  /// Outer box border width (logical px, already scaled). `0` draws no
  /// box — the widget leaves the border `null` rather than painting a
  /// zero-width hairline.
  final double outerBorderWidth;

  /// Table container border radius (already scaled).
  final BorderRadius borderRadius;

  /// Header cell padding (already scaled).
  final EdgeInsetsGeometry headerCellPadding;

  /// Body / footer cell padding (already scaled).
  final EdgeInsetsGeometry bodyCellPadding;

  /// Header row background color. Transparent under the design-system
  /// default (the header reads as the top of the surface it sits on).
  final Color headerBackgroundColor;

  /// Background a *frozen* (sticky) header cell paints:
  /// [headerBackgroundColor] when it has a fill, else the frozen-cell base
  /// (the explicit `frozenCellBackgroundColor`, else
  /// `CoreTableStyle.defaultFrozenCellBackgroundColor`) so a clear header
  /// still covers the rows scrolling under it.
  final Color frozenHeaderBackgroundColor;

  /// Footer row background color.
  final Color footerBackgroundColor;

  /// Row background on hover.
  final Color rowHoverColor;

  /// Row background when selected.
  final Color rowSelectedColor;

  /// Header row min-height (logical px, already scaled). `null` lets the
  /// grid track sizing drive the natural header height.
  final double? headerHeight;

  /// Body row min-height (logical px, already scaled). `null` lets the
  /// grid track sizing drive the natural row height.
  final double? rowHeight;

  /// Resizer handle color on hover.
  final Color resizerHoverColor;

  /// Resizer handle color during drag.
  final Color resizerDragColor;

  /// Resizer handle thickness (logical px, already scaled).
  final double resizerThickness;

  /// Paint-ready header cell text style — the `labelMedium` typography
  /// role with the per-instance `headerTextStyle` slot override folded on
  /// top. The slot's `color` is resolved
  /// separately into [headerForegroundColor] /
  /// [headerDisabledForegroundColor] so the widget never re-runs colour
  /// resolution; it binds the foreground via `copyWith(color: ...)` only.
  final TextStyle headerTextStyle;

  /// Paint-ready body / footer cell text style — the `labelLarge`
  /// typography role with the per-instance `cellTextStyle` slot override
  /// folded on top. Colour handled the same way as [headerTextStyle]
  /// (see [cellForegroundColor]).
  final TextStyle cellTextStyle;

  /// Paint-ready header cell foreground colour for enabled cells —
  /// `headerTextStyle.color` override resolved against the scheme, else
  /// the flat `foregroundColor` override, else the colour of
  /// `CoreTableStyle.defaultHeaderTextStyle`.
  final Color headerForegroundColor;

  /// Paint-ready header cell foreground colour for disabled cells —
  /// `headerTextStyle.color` override (no opacity applied) when set, else
  /// the scheme's `onSurface` scaled by the disabled opacity.
  final Color headerDisabledForegroundColor;

  /// Paint-ready body / footer cell foreground colour for enabled cells —
  /// `cellTextStyle.color` override resolved against the scheme, else the
  /// scheme's `onSurface`.
  final Color cellForegroundColor;

  /// Paint-ready body / footer cell foreground colour for disabled cells —
  /// `cellTextStyle.color` override (no opacity applied) when set, else
  /// the scheme's `onSurface` scaled by the disabled opacity.
  final Color cellDisabledForegroundColor;

  /// Virtual-scroll viewport width (logical px). `null` disables
  /// horizontal virtual scroll.
  final double? viewportWidth;

  /// Virtual-scroll viewport height (logical px). `null` disables
  /// vertical virtual scroll.
  final double? viewportHeight;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// This surface draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// Backdrop blur sigma for the container, `null` when the active theme
  /// states no material or the table paints no fill of its own to blur
  /// behind — see [backgroundColor].
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;
}

/// Resolves [ResolvedTable] for the given [context] — single entry point.
///
/// Merge chain (Epic #1302 nested-merge):
/// `CoreTableTheme.style` → `widgetTheme.style` → `tableStyle`. The
/// `theme.coreComponentTheme` lookup, the design-system fallback and the
/// token → plain-value conversion are all encapsulated here so the widget
/// `build` never touches them directly.
ResolvedTable resolveTable(
  BuildContext context, {
  CoreTableTheme? widgetTheme,
  CoreTableStyle? tableStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final cs = theme.colorScheme;
  final scheme = cs;
  final tableTheme = theme.coreComponentTheme?.table;

  final merged = resolveStyleChain(const CoreTableStyle(), [
    tableTheme?.style,
    widgetTheme?.style,
    tableStyle,
  ]);

  // ── Stage 1 RESOLVE + Stage 2 EMIT (colours) ────────────────────────
  // Every chrome colour settles to a `CoreColor` (`merged.X ?? default`)
  // then bakes to a Flutter `Color` via `scheme.resolve(...).toValue()`.
  // Background / row-base / zebra colours have no design default (the
  // table stays transparent / unstriped unless overridden), so they stay
  // nullable and only resolve when an override is present.

  // Container background — instance/theme override wins; otherwise the
  // container stays transparent (body cells fall back to the surface
  // colour below for frozen-cell layering).
  //
  // surface:content — a face in the content layer, per its own doc.
  // `co_table.dart` states no fill of its own on purpose (see the comment
  // above its `DecoratedBox`), so the material has something to make
  // translucent only once a caller actually paints one — gated on the
  // fill exactly like every other optional-background surface on this
  // axis (see the "fill-less panel" cases in `surface_material_pair_test`).
  final material = merged.backgroundColor != null
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);
  final backgroundColor = merged.backgroundColor == null
      ? null
      : scheme
            .resolve(
              surfaceOpacity == null
                  ? merged.backgroundColor!
                  : merged.backgroundColor!.scaleAlpha(surfaceOpacity),
            )
            .toValue();
  final hasFill = backgroundColor != null && backgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(theme, role: .content)
      : null;

  // Body row base background — explicit override only. `null` lets the
  // widget pick `backgroundColor` (or transparent) as the base.
  final rowBackgroundColor = merged.rowBackgroundColor != null
      ? scheme.resolve(merged.rowBackgroundColor!).toValue()
      : null;

  // Even-body-row zebra-stripe background — explicit override only.
  // `null` keeps every body row on its base background (no stripe).
  final rowAlternateBackgroundColor = merged.rowAlternateBackgroundColor != null
      ? scheme.resolve(merged.rowAlternateBackgroundColor!).toValue()
      : null;

  // Frozen (sticky) body-cell background — explicit override only,
  // mirrors the Web resolver's `frozenCellBgOverride` 1:1. `null` lets
  // the widget fall back to `rowBackgroundColor` / `backgroundColor`.
  final frozenCellBackgroundColor = merged.frozenCellBackgroundColor != null
      ? scheme.resolve(merged.frozenCellBackgroundColor!).toValue()
      : null;

  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a table that skips this keeps a border its siblings have
  // dropped.
  final borderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(merged.borderColor ?? CoreTableStyle.defaultBorderColor)
        .toValue(),
    role: .content,
  );

  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreTableStyle.defaultBorderWidth,
    scaling: scaling,
  );

  // The outer box has its own width so the row separators keep theirs.
  // `stroke(0)` stays 0 under every surface style — the floor raises
  // widths that are drawn, never an absent line.
  final outerBorderWidth = theme.geometry.stroke(
    merged.outerBorderWidth ?? CoreTableStyle.defaultOuterBorderWidth,
    scaling: scaling,
  );

  final borderRadiusCore =
      merged.borderRadius ?? CoreTableStyle.defaultBorderRadius;
  final borderRadius = _scaleRadius(
    borderRadiusCore.toValue(geometry: theme.geometry),
    scaling,
  );

  final headerBackgroundColor = scheme
      .resolve(
        merged.headerBackgroundColor ??
            CoreTableStyle.defaultHeaderBackgroundColor,
      )
      .toValue();

  final frozenHeaderBackgroundColor = headerBackgroundColor.a > 0
      ? headerBackgroundColor
      : scheme
            .resolve(
              merged.frozenCellBackgroundColor ??
                  CoreTableStyle.defaultFrozenCellBackgroundColor,
            )
            .toValue();

  final footerBackgroundColor = scheme
      .resolve(
        merged.footerBackgroundColor ??
            CoreTableStyle.defaultFooterBackgroundColor,
      )
      .toValue();

  final rowHoverColor = scheme
      .resolve(merged.rowHoverColor ?? CoreTableStyle.defaultRowHoverColor)
      .toValue();

  final rowSelectedColor = scheme
      .resolve(
        merged.rowSelectedColor ?? CoreTableStyle.defaultRowSelectedColor,
      )
      .toValue();

  final resizerHoverColor = scheme
      .resolve(
        merged.resizerHoverColor ??
            merged.resizerColor ??
            CoreTableStyle.defaultResizerHoverColor,
      )
      .toValue();

  final resizerDragColor = scheme
      .resolve(
        merged.resizerDragColor ??
            merged.resizerColor ??
            CoreTableStyle.defaultResizerDragColor,
      )
      .toValue();

  final resizerThickness =
      (merged.resizerThickness ?? CoreTableStyle.defaultResizerThickness) *
      scaling;

  // Header / body row min-height — override only (no design default; the
  // grid track sizing drives the natural height). Scaled so the min-height
  // tracks the text-scale factor alongside padding / radius.
  final headerHeight = merged.headerHeight != null
      ? merged.headerHeight! * scaling
      : null;
  final rowHeight = merged.rowHeight != null
      ? merged.rowHeight! * scaling
      : null;

  // Per-cell padding branches — header reads `headerPadding`, body /
  // footer read `cellPadding`. Both fall back to the design default.
  final headerCellPadding =
      ((merged.headerPadding ?? CoreTableStyle.defaultHeaderPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final bodyCellPadding =
      ((merged.cellPadding ?? CoreTableStyle.defaultCellPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // Cell foreground colours (paint-ready). The slot override (`color` on
  // the header / cell text style) wins, else the flat top-level
  // [CoreTableStyle.foregroundColor] / [CoreTableStyle.disabledForegroundColor]
  // override, else the design-system defaults (`defaultForegroundColor`
  // enabled / `defaultDisabledForegroundColor` disabled) drive the
  // colour. Every branch runs through `scheme.resolve(...)` so the
  // widget reads a ready Flutter `Color` and never re-resolves a
  // `CoreColor` itself.
  Color foreground(
    CoreColor? override, {
    required bool disabled,
    CoreColor? enabledDefault,
  }) {
    final value =
        override ??
        (disabled
            ? (merged.disabledForegroundColor ??
                  CoreTableStyle.defaultDisabledForegroundColor)
            : (merged.foregroundColor ??
                  enabledDefault ??
                  CoreTableStyle.defaultForegroundColor));
    return scheme.resolve(value).toValue();
  }

  final headerForegroundColor = foreground(
    merged.headerTextStyle?.color,
    disabled: false,
    enabledDefault: CoreTableStyle.defaultHeaderTextStyle.color,
  );
  final headerDisabledForegroundColor = foreground(
    merged.headerTextStyle?.color,
    disabled: true,
  );
  final cellForegroundColor = foreground(
    merged.cellTextStyle?.color,
    disabled: false,
  );
  final cellDisabledForegroundColor = foreground(
    merged.cellTextStyle?.color,
    disabled: true,
  );

  // Paint-ready cell text styles. The design-system defaults
  // (`CoreTableStyle.defaultHeaderTextStyle` / `defaultCellTextStyle`)
  // carry the `labelMedium` / `labelLarge` typography roles; the
  // per-instance slot override folds on via `default.merge(slot)
  // .toValue(theme:)` (Stage 2 EMIT). The colour is bound per cell by the
  // widget (enabled / disabled) from the foreground colours above, so the
  // colour on these styles is overwritten with `copyWith(color:)`.
  final headerTextStyle = CoreTableStyle.defaultHeaderTextStyle
      .merge(merged.headerTextStyle)
      .toValue(theme: theme);
  final cellTextStyle = CoreTableStyle.defaultCellTextStyle
      .merge(merged.cellTextStyle)
      .toValue(theme: theme);

  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedTable(
    boxShadow: boxShadow,
    backgroundColor: backgroundColor,
    rowBackgroundColor: rowBackgroundColor,
    rowAlternateBackgroundColor: rowAlternateBackgroundColor,
    frozenCellBackgroundColor: frozenCellBackgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    outerBorderWidth: outerBorderWidth,
    borderRadius: borderRadius,
    headerCellPadding: headerCellPadding,
    bodyCellPadding: bodyCellPadding,
    headerBackgroundColor: headerBackgroundColor,
    frozenHeaderBackgroundColor: frozenHeaderBackgroundColor,
    footerBackgroundColor: footerBackgroundColor,
    rowHoverColor: rowHoverColor,
    rowSelectedColor: rowSelectedColor,
    headerHeight: headerHeight,
    rowHeight: rowHeight,
    resizerHoverColor: resizerHoverColor,
    resizerDragColor: resizerDragColor,
    resizerThickness: resizerThickness,
    headerTextStyle: headerTextStyle,
    cellTextStyle: cellTextStyle,
    headerForegroundColor: headerForegroundColor,
    headerDisabledForegroundColor: headerDisabledForegroundColor,
    cellForegroundColor: cellForegroundColor,
    cellDisabledForegroundColor: cellDisabledForegroundColor,
    viewportWidth: merged.viewportWidth,
    viewportHeight: merged.viewportHeight,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}

BorderRadius _scaleRadius(BorderRadius radius, double scaling) {
  return BorderRadius.only(
    topLeft: radius.topLeft * scaling,
    topRight: radius.topRight * scaling,
    bottomLeft: radius.bottomLeft * scaling,
    bottomRight: radius.bottomRight * scaling,
  );
}
