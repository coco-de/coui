import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedBottomActionBar
// ═══════════════════════════════════════════════════

/// Resolver output for `BottomActionBar`.
///
/// ```text
/// Semantics (group)
///   └─ SurfaceBlur (blur · saturation · sheen · refraction)   // glass only
///        └─ Container (backgroundColor, top border: divider*)
///             └─ SafeArea (bottom only)
///                  └─ Padding (padding)
///                       └─ Column (spacing)
///                            ├─ DefaultTextStyle (descriptionTextStyle ·
///                            │    descriptionTextAlign) → description  // optional
///                            └─ primaryAction · secondaryAction        // vertical
///                               Row of Expanded cells                  // horizontal
/// ```
///
/// Every value has had the merge chain, the default fallback, token
/// resolution, density and `scaling` applied — the widget reads them as
/// they are.
class ResolvedBottomActionBar {
  /// Creates a [ResolvedBottomActionBar].
  const ResolvedBottomActionBar({
    required this.backgroundColor,
    required this.padding,
    required this.spacing,
    required this.dividerColor,
    required this.dividerWidth,
    required this.descriptionTextStyle,
    required this.descriptionTextAlign,
    required this.summaryLabelTextStyle,
    required this.summaryValueTextStyle,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.refraction,
  });

  /// The surface fill — the share a theme-wide material leaves of it is
  /// already folded into its alpha.
  final Color backgroundColor;

  /// Inset around the actions, before the bottom safe area is added to its
  /// bottom edge. Kept directional-capable: a start / end inset resolves
  /// against the ambient text direction.
  final EdgeInsetsGeometry padding;

  /// Space between the note and the actions, and between the actions
  /// (post-density, post-scaling).
  final double spacing;

  /// Colour of the hairline above the bar — transparent while the active
  /// material draws its own edge.
  final Color dividerColor;

  /// Thickness of the hairline above the bar (post-geometry,
  /// post-scaling).
  final double dividerWidth;

  /// Ambient text style of the note slot.
  final TextStyle descriptionTextStyle;

  /// Horizontal alignment of the note's text.
  final TextAlign descriptionTextAlign;

  /// Resolved paint-ready text style of the summary's caption.
  final TextStyle summaryLabelTextStyle;

  /// Resolved paint-ready text style of the summary's figure.
  final TextStyle summaryValueTextStyle;

  /// Backdrop blur sigma from a theme-wide material treatment, or `null`
  /// when the surface is an opaque fill.
  final double? surfaceBlur;

  /// Chroma lift riding the same material treatment as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the bar, or `null`
  /// for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// The active material's bend, or `null` when it states none.
  final CoreSurfaceRefraction? refraction;
}

/// Resolves the chrome of a `BottomActionBar`.
///
/// ```text
/// CoreBottomActionBarStyle.default*
///   → CoreBottomActionBarTheme.style
///   → widget.bottomActionBarStyle
/// ```
ResolvedBottomActionBar resolveBottomActionBar(
  BuildContext context, {
  CoreBottomActionBarStyle? bottomActionBarStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreBottomActionBarStyle(), [
    theme.coreComponentTheme?.bottomActionBar?.style,
    bottomActionBarStyle,
  ]);

  // ─── Material ─────────────────────────────────────────
  // The bar is mounted over a body that scrolls beneath it, so it takes the
  // floating role of a style that states two materials — and the only one
  // of a style that states one. A style with no material leaves every value
  // below null and the bar an opaque fill.
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
      merged.backgroundColor ?? CoreBottomActionBarStyle.defaultBackgroundColor;
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundToken
            : backgroundToken.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final authoredDividerColor = scheme
      .resolve(
        merged.dividerColor ?? CoreBottomActionBarStyle.defaultDividerColor,
      )
      .toValue();
  // A material that draws its own edge takes the hairline's colour — but only
  // where the bar draws a surface to carry that edge. A fill-less bar gets no
  // material (no `SurfaceBlur`, and no surface marker on Web), so its stated
  // hairline stays: suppressing it would leave the bar with no edge at all.
  final dividerColor = backgroundColor.a > 0
      ? resolveSurfaceStroke(
          theme,
          authoredDividerColor,
          role: CoreSurfaceRole.functional,
        )
      : authoredDividerColor;

  // ─── Dimensions ───────────────────────────────────────
  // `toGeometry`, not `toValue`: a caller may state the inset as start / end,
  // and `toValue` refuses to flatten it.
  final padding =
      (merged.padding ?? CoreBottomActionBarStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final spacing =
      theme.geometry.space(
        merged.spacing ?? CoreBottomActionBarStyle.defaultSpacing,
      ) *
      scaling;
  final dividerWidth = theme.geometry.stroke(
    merged.dividerWidth ?? CoreBottomActionBarStyle.defaultDividerWidth,
    scaling: scaling,
  );

  // ─── Note ─────────────────────────────────────────────
  final descriptionTextStyle = CoreBottomActionBarStyle
      .defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);
  final descriptionTextAlign =
      (merged.descriptionTextAlign ??
              CoreBottomActionBarStyle.defaultDescriptionTextAlign)
          .toValue();

  // ─── Summary ──────────────────────────────────────────
  final summaryLabelTextStyle = CoreBottomActionBarStyle
      .defaultSummaryLabelTextStyle
      .merge(merged.summaryLabelTextStyle)
      .toValue(theme: theme);
  final summaryValueTextStyle = CoreBottomActionBarStyle
      .defaultSummaryValueTextStyle
      .merge(merged.summaryValueTextStyle)
      .toValue(theme: theme);

  return ResolvedBottomActionBar(
    backgroundColor: backgroundColor,
    padding: padding,
    spacing: spacing,
    dividerColor: dividerColor,
    dividerWidth: dividerWidth,
    descriptionTextStyle: descriptionTextStyle,
    descriptionTextAlign: descriptionTextAlign,
    summaryLabelTextStyle: summaryLabelTextStyle,
    summaryValueTextStyle: summaryValueTextStyle,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    refraction: refraction,
  );
}
