import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedScaffold
// ═══════════════════════════════════════════════════

/// Resolver output for [Scaffold].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreScaffoldStyle.defaultX` / `defaultsByVariant` static const
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreScaffoldStyle.defaultX           // design system default
///   → CoreScaffoldStyle.defaultsByVariant[variant]
///   → theme.coreComponentTheme.scaffold.style
///   → theme.coreComponentTheme.scaffold.variantStyles[variant]
///   → widget.scaffoldStyle
/// ```
class ResolvedScaffold {
  /// Creates a [ResolvedScaffold].
  const ResolvedScaffold({
    required this.backgroundColor,
    required this.headerBackgroundColor,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.footerBackgroundColor,
    required this.headerBorderColor,
    required this.headerBorderWidth,
    required this.fabPadding,
    this.ownsHeaderMaterial = true,
    this.appBarRailPadding = CoreScaffoldStyle.defaultAppBarRailPadding,
    this.appBarRailPopupStyle,
    this.appBarRailWidth = CoreToolbarGroupContract.glassVerticalActionMinSize,
  });

  /// Effective scaffold body background colour.
  final Color backgroundColor;

  /// Floating glass headers delegate the material to their controls.
  final bool ownsHeaderMaterial;

  /// Effective header section background colour.
  final Color headerBackgroundColor;

  /// Effective footer section background colour.
  final Color footerBackgroundColor;

  /// Effective header bottom-border colour.
  final Color headerBorderColor;

  /// Backdrop blur the active surface style asks the header for.
  ///
  /// Only the header carries the material. The page background is the
  /// outermost fill with nothing behind it, and the footer sits below the
  /// content rather than over it — Web marks the same one slot.
  ///
  /// A caveat worth knowing before reading a screenshot: with the default
  /// `floatingHeader: false` the header is a `Column` sibling painted
  /// *before* the body, so the backdrop this samples is the flat page fill
  /// and the blur changes nothing. It pays off when the header floats over
  /// the content. The translucency it pairs with is visible either way,
  /// which is why the two travel together.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Effective header bottom-border thickness (logical px, scaling
  /// applied).
  final double headerBorderWidth;

  /// Effective padding around a floating action button (scaling
  /// applied).
  final EdgeInsets fabPadding;

  /// Physical screen-edge clearances for the adaptive app-bar rail.
  final CoreEdgeInsets appBarRailPadding;

  /// Scaled control seat; falls back to a row if the system strip is too thin.
  final double appBarRailWidth;

  /// Optional capsule material and chrome unique to the vertical rail.
  final CorePopupStyle? appBarRailPopupStyle;
}

// ═══════════════════════════════════════════════════
// resolveScaffold — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScaffold] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreScaffoldStyle.defaultX` / `defaultsByVariant` static const
/// fallback so the widget reads only fully-resolved Flutter-typed
/// values.
ResolvedScaffold resolveScaffold(
  BuildContext context, {
  required CoreScaffoldVariant variant,
  CoreScaffoldStyle? scaffoldStyle,
  bool floatingHeader = false,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final scaffoldTheme = theme.coreComponentTheme?.scaffold;

  // Variant chrome — defaultsByVariant single source of truth.
  final chrome = CoreScaffoldStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles → widget.
  final merged = resolveStyleChain(const CoreScaffoldStyle(), [
    scaffoldTheme?.style,
    scaffoldTheme?.variantStyles?[variant],
    scaffoldStyle,
  ]);

  // ─── Stage 1 RESOLVE — dimensional (Core values) ──────
  final headerBorderWidth = theme.geometry.stroke(
    merged.headerBorderWidth ?? CoreScaffoldStyle.defaultHeaderBorderWidth,
    scaling: scaling,
  );
  final fabPadding =
      ((merged.fabPadding ?? CoreScaffoldStyle.defaultFabPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // ─── Stage 2 EMIT — colours (Flutter: scheme.resolve(c).toValue()) ──
  final backgroundColor = scheme
      .resolve(merged.backgroundColor ?? chrome.backgroundColor)
      .toValue();
  // A theme-wide material treatment reaches the app bar the same way it
  // reaches a card — an opaque bar above translucent panels reads as the
  // preset being broken rather than unapplied.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final clearFloatingHeader =
      floatingHeader &&
      material?.type == SurfaceType.glass &&
      merged.headerBackgroundColor == null;
  final surfaceOpacity = material?.opacityIn(theme);
  final headerBackgroundToken =
      merged.headerBackgroundColor ?? chrome.headerBackgroundColor;
  final headerBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? headerBackgroundToken
            : headerBackgroundToken.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final footerBackgroundColor = scheme
      .resolve(merged.footerBackgroundColor ?? chrome.footerBackgroundColor)
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border. This one sat outside the guard because its call was split
  // across lines, not because it was exempt.
  final headerBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          merged.headerBorderColor ??
              CoreScaffoldStyle.defaultHeaderBorderColor,
        )
        .toValue(),
    role: CoreSurfaceRole.functional,
  );

  return ResolvedScaffold(
    backgroundColor: backgroundColor,
    headerBackgroundColor: clearFloatingHeader
        ? const Color(0x00000000)
        : headerBackgroundColor,
    ownsHeaderMaterial: !clearFloatingHeader,
    surfaceBlur: material?.blurRadius,
    surfaceSaturation: material?.saturation,
    surfaceBackdropBrightness: material?.backdropBrightnessIn(theme),
    surfaceSheen: resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional),
    footerBackgroundColor: footerBackgroundColor,
    headerBorderColor: headerBorderColor,
    headerBorderWidth: headerBorderWidth,
    fabPadding: fabPadding,
    appBarRailPadding:
        merged.appBarRailPadding ?? CoreScaffoldStyle.defaultAppBarRailPadding,
    appBarRailPopupStyle: merged.appBarRailPopupStyle,
    appBarRailWidth:
        CoreToolbarGroupContract.glassVerticalActionMinSize * scaling,
  );
}

/// Maps a [CoreScaffoldFabLocation] to its Flutter [Alignment].
Alignment alignmentForFabLocation(CoreScaffoldFabLocation location) {
  return switch (location) {
    .endFloat => .bottomRight,
    .centerFloat => .bottomCenter,
    .startFloat => .bottomLeft,
  };
}
