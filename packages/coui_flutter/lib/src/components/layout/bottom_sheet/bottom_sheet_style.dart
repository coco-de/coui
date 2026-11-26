import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedBottomSheet
// ═══════════════════════════════════════════════════

/// Resolver output for `BottomSheet`.
///
/// ```text
/// Semantics (container)
///   └─ ConstrainedBox (maxHeight)
///        └─ SurfaceBlur (blur · saturation · sheen · refraction) // glass
///             └─ DecoratedBox (backgroundColor, borderRadius)
///                  └─ Column
///                       ├─ Padding (handlePadding) → handle bar  // opt.
///                       ├─ Padding (headerPadding)
///                       │    └─ Column
///                       │         ├─ Row (headerSpacing): title · close
///                       │         └─ Gap (titleGapStyle) · description
///                       ├─ Divider (dividerStyle)                // opt.
///                       └─ Flexible → body (content + footer)    // opt.
///                            ├─ Flexible → scroll view (contentPadding)
///                            │    └─ content
///                            └─ DecoratedBox (foreground top border:
///                                 footerOverflowBorder | footerRestBorder)
///                                 └─ Theme (footerBarStyle) → footer
/// ```
///
/// The two footer borders are the hairline's two state values; the widget
/// detects whether more content lies below the visible part and picks one.
///
/// Every value has had the merge chain, the default fallback, token
/// resolution, density and `scaling` applied — the widget reads them as
/// they are.
class ResolvedBottomSheet {
  /// Creates a [ResolvedBottomSheet].
  const ResolvedBottomSheet({
    required this.backgroundColor,
    required this.borderRadius,
    required this.handleWidth,
    required this.handleHeight,
    required this.handleColor,
    required this.handleBorderRadius,
    required this.handlePadding,
    required this.headerPadding,
    required this.headerSpacing,
    required this.titleGapStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
    required this.contentPadding,
    required this.closeButtonStyle,
    required this.dividerStyle,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.refraction,
    required this.maxHeight,
    required this.footerOverflowBorder,
    required this.footerRestBorder,
    required this.footerBarStyle,
  });

  /// The surface fill — the share a theme-wide material leaves of it is
  /// already folded into its alpha.
  final Color backgroundColor;

  /// Corners of the panel.
  final BorderRadius borderRadius;

  /// Width of the handle bar (post-scaling).
  final double handleWidth;

  /// Height of the handle bar (post-scaling).
  final double handleHeight;

  /// Colour of the handle bar.
  final Color handleColor;

  /// Corners of the handle bar.
  final BorderRadius handleBorderRadius;

  /// Inset around the handle bar.
  final EdgeInsetsGeometry handlePadding;

  /// Inset around the title row and the description.
  final EdgeInsetsGeometry headerPadding;

  /// Space between the title and the close button (post-density,
  /// post-scaling).
  final double headerSpacing;

  /// Gap between the title row and the description, raw-forwarded to `Gap`.
  final CoreGapStyle titleGapStyle;

  /// Ambient text style of the title slot.
  final TextStyle titleTextStyle;

  /// Ambient text style of the description slot.
  final TextStyle descriptionTextStyle;

  /// Inset around the content.
  final EdgeInsetsGeometry contentPadding;

  /// Chrome of the composed close `Button`, raw-forwarded.
  final CoreButtonStyle closeButtonStyle;

  /// Chrome of the composed `Divider`, raw-forwarded, or `null` for the
  /// divider's own defaults.
  final CoreDividerStyle? dividerStyle;

  /// Backdrop blur sigma from a theme-wide material treatment, or `null`
  /// when the surface is an opaque fill.
  final double? surfaceBlur;

  /// Chroma lift riding the same material treatment as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the sheet, or `null`
  /// for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// The active material's bend, or `null` when it states none.
  final CoreSurfaceRefraction? refraction;

  /// Tallest the sheet grows — the viewport's height times the stated
  /// factor. Infinite where no viewport height is known (none, or zero), in
  /// which case the sheet sizes to its content and does not scroll.
  final double maxHeight;

  /// The hairline above the footer while more content lies below — or
  /// [BorderSide.none] when the stated width is zero.
  final BorderSide footerOverflowBorder;

  /// The hairline above the footer while the content ends in view — none.
  final BorderSide footerRestBorder;

  /// The `BottomActionBar` theme style installed around the footer — the
  /// surrounding bar theme with the sheet's `footerBarStyle` folded in,
  /// raw-forwarded to the bar's own resolver.
  final CoreBottomActionBarStyle footerBarStyle;
}

/// Resolves the chrome of a `BottomSheet`.
///
/// ```text
/// CoreBottomSheetStyle.default*
///   → CoreBottomSheetTheme.style
///   → widget.bottomSheetStyle
/// ```
ResolvedBottomSheet resolveBottomSheet(
  BuildContext context, {
  CoreBottomSheetStyle? bottomSheetStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreBottomSheetStyle(), [
    theme.coreComponentTheme?.bottomSheet?.style,
    bottomSheetStyle,
  ]);

  // ─── Material ─────────────────────────────────────────
  // The sheet rises over the page, so it takes the floating role of a style
  // that states two materials — and the only one of a style that states one.
  // A style with no material leaves every value below null and the sheet an
  // opaque fill.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = resolveSurfaceSheen(
    theme,
    role: CoreSurfaceRole.functional,
  );
  final refraction = theme.surfaceRefraction;

  // ─── Colours ──────────────────────────────────────────
  // The material's share multiplies the token's own alpha — it does not
  // replace it.
  final backgroundToken =
      merged.backgroundColor ?? CoreBottomSheetStyle.defaultBackgroundColor;
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundToken
            : backgroundToken.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final handleColor = scheme
      .resolve(merged.handleColor ?? CoreBottomSheetStyle.defaultHandleColor)
      .toValue();

  // ─── Dimensions ───────────────────────────────────────
  final borderRadius =
      (merged.borderRadius ?? CoreBottomSheetStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final handleWidth =
      (merged.handleWidth ?? CoreBottomSheetStyle.defaultHandleWidth) * scaling;
  final handleHeight =
      (merged.handleHeight ?? CoreBottomSheetStyle.defaultHandleHeight) *
      scaling;
  final handleBorderRadius =
      (merged.handleBorderRadius ??
              CoreBottomSheetStyle.defaultHandleBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final handlePadding =
      (merged.handlePadding ?? CoreBottomSheetStyle.defaultHandlePadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final headerPadding =
      (merged.headerPadding ?? CoreBottomSheetStyle.defaultHeaderPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final headerSpacing =
      theme.geometry.space(
        merged.headerSpacing ?? CoreBottomSheetStyle.defaultHeaderSpacing,
      ) *
      scaling;
  final contentPadding =
      (merged.contentPadding ?? CoreBottomSheetStyle.defaultContentPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;

  // ─── Nested slots (raw-forwarded to the composed components) ───
  final titleGapStyle = CoreBottomSheetStyle.defaultTitleGapStyle.merge(
    merged.titleGapStyle,
  );
  final closeButtonStyle = CoreBottomSheetStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final dividerStyle = merged.dividerStyle;

  // ─── Height ceiling ───────────────────────────────────
  // The viewport, not the parent's constraint: a sheet laid out where the
  // height is unbounded (a scroll view, a docs preview) still stops at a
  // finite height, so the content can scroll inside it.
  // A zero-height viewport (a view not yet laid out, a bare
  // `MediaQueryData()`) is as unknown as no viewport — capping at zero would
  // collapse the sheet.
  final viewportHeight = MediaQuery.maybeSizeOf(context)?.height ?? 0;
  final maxHeightFactor =
      merged.maxHeightFactor ?? CoreBottomSheetStyle.defaultMaxHeightFactor;
  final maxHeight = viewportHeight > 0
      ? viewportHeight * maxHeightFactor
      : double.infinity;

  // ─── Action area ──────────────────────────────────────
  final footerDividerColor = scheme
      .resolve(
        merged.footerDividerColor ??
            CoreBottomSheetStyle.defaultFooterDividerColor,
      )
      .toValue();
  final footerDividerWidth = theme.geometry.stroke(
    merged.footerDividerWidth ?? CoreBottomSheetStyle.defaultFooterDividerWidth,
    scaling: scaling,
  );
  // `BorderSide(width: 0)` paints a hairline in Flutter while a zero
  // `height` draws nothing on Web, so a zero width states no line at all.
  final footerOverflowBorder = footerDividerWidth > 0
      ? BorderSide(color: footerDividerColor, width: footerDividerWidth)
      : BorderSide.none;
  const footerRestBorder = BorderSide.none;
  final footerBarStyle = CoreBottomSheetContract.footerBarThemeStyle(
    theme.coreComponentTheme?.bottomActionBar,
    CoreBottomSheetStyle.defaultFooterBarStyle.merge(merged.footerBarStyle),
  );

  // ─── Text ─────────────────────────────────────────────
  final titleTextStyle = CoreBottomSheetStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final descriptionTextStyle = CoreBottomSheetStyle.defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);

  return ResolvedBottomSheet(
    backgroundColor: backgroundColor,
    borderRadius: borderRadius,
    handleWidth: handleWidth,
    handleHeight: handleHeight,
    handleColor: handleColor,
    handleBorderRadius: handleBorderRadius,
    handlePadding: handlePadding,
    headerPadding: headerPadding,
    headerSpacing: headerSpacing,
    titleGapStyle: titleGapStyle,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    contentPadding: contentPadding,
    closeButtonStyle: closeButtonStyle,
    dividerStyle: dividerStyle,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    refraction: refraction,
    maxHeight: maxHeight,
    footerOverflowBorder: footerOverflowBorder,
    footerRestBorder: footerRestBorder,
    footerBarStyle: footerBarStyle,
  );
}
