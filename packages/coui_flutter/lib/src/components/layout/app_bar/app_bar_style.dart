import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedAppBar
// ═══════════════════════════════════════════════════

/// Resolver output for [AppBar].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreAppBarStyle.defaultX` / `defaultsByVariant` static
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreAppBarStyle.defaultX             // design system default
///   → CoreAppBarStyle.defaultsByVariant[variant]
///   → theme.coreComponentTheme.appBar.style
///   → theme.coreComponentTheme.appBar.variantStyles[variant]
///   → widget.appBarStyle
/// ```
///
/// Widget tree (`app_bar.dart` decides which branches render):
///
/// ```text
/// DecoratedBox (backgroundColor / divider border / elevated shadow)
///   └─ SizedBox (height)
///        ├─ standard | compact | dense | prominent:
///        │    Padding (padding)
///        │      └─ Row (spacing)
///        │           ├─ leading Row (actionSpacing)
///        │           ├─ Flexible → Padding (titlePadding)
///        │           │    └─ centre column         // titleTextStyle
///        │           └─ trailing Row (actionSpacing)
///        └─ medium:
///             Column
///               ├─ SizedBox (topRowHeight) → Padding (padding)
///               │    └─ Row (spacing) [leading, Spacer, trailing]
///               └─ Expanded → Padding (titlePadding)
///                    └─ Align (bottom) → centre column
/// ```
class ResolvedAppBar {
  /// Creates a [ResolvedAppBar].
  const ResolvedAppBar({
    required this.height,
    required this.topRowHeight,
    required this.backgroundColor,
    required this.padding,
    required this.spacing,
    required this.actionSpacing,
    required this.titleTextStyle,
    required this.titlePadding,
    required this.dividerColor,
    required this.dividerWidth,
    required this.elevatedShadow,
    this.material,
    this.surfaceSheen,
    this.refraction,
    this.actionCapsuleStyle,
  });

  /// Effective total bar height (logical px, scaling applied).
  final double height;

  /// Effective functional material, including nesting and accessibility.
  final CoreSurfaceToken? material;

  /// Resolved edge highlight.
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Impeller refraction request after local material resolution.
  final CoreSurfaceRefraction? refraction;

  /// Native capsule style forwarded to the shared toolbar surface.
  /// Null keeps the ordinary bar layout.
  final CorePopupStyle? actionCapsuleStyle;

  /// Effective medium top-row height (logical px, scaling applied).
  /// Consumed only by the medium render branch.
  final double topRowHeight;

  /// Effective bar surface colour.
  final Color backgroundColor;

  /// Effective horizontal bar inset (scaling applied) — the root row for
  /// standard / compact / dense / prominent, the top row for medium.
  final EdgeInsets padding;

  /// Effective gap between the leading / title / actions clusters
  /// (logical px, scaling applied). Mirrors Flutter `Row.spacing`.
  final double spacing;

  /// Effective gap between adjacent action widgets inside a cluster
  /// (logical px, scaling applied). Mirrors Flutter `Row.spacing`.
  final double actionSpacing;

  /// Paint-ready title typography (role + colour resolved through the
  /// active scheme). Merged over the caller's title widget via
  /// `DefaultTextStyle.merge`.
  final TextStyle titleTextStyle;

  /// Effective title-block inset (scaling applied).
  final EdgeInsets titlePadding;

  /// Effective bottom hairline colour.
  final Color dividerColor;

  /// Effective bottom hairline thickness (logical px, geometry + scaling
  /// applied).
  final double dividerWidth;

  /// Paint-ready elevated drop-shadow stack (drawn only while
  /// `elevated` is on).
  final List<BoxShadow> elevatedShadow;
}

// ═══════════════════════════════════════════════════
// resolveAppBar — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAppBar] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreAppBarStyle.defaultX` / `defaultsByVariant` static
/// fallback so the widget reads only fully-resolved Flutter-typed
/// values.
ResolvedAppBar resolveAppBar(
  BuildContext context, {
  required CoreAppBarVariant variant,
  CoreAppBarStyle? appBarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final appBarTheme = theme.coreComponentTheme?.appBar;

  // Variant chrome — defaultsByVariant single source of truth.
  final vs = CoreAppBarStyle.defaultsByVariant[variant]!;

  // Merge chain — theme.style → theme.variantStyles → widget.
  final merged = resolveStyleChain(const CoreAppBarStyle(), [
    appBarTheme?.style,
    appBarTheme?.variantStyles?[variant],
    appBarStyle,
  ]);

  final materialTheme = resolveSurfaceTheme(context, merged.surfaceStyle);
  final glassChrome = merged.surfaceStyle != null
      ? merged.surfaceStyle == CoreSurfaceStyleId.liquidGlass
      : materialTheme.functionalSurface?.type == SurfaceType.glass;

  // ─── Stage 1 RESOLVE + Stage 2 EMIT — dimensional (pre-scaled) ──
  final height = (merged.height ?? vs.height!) * scaling;
  final topRowHeight =
      (merged.topRowHeight ?? CoreAppBarStyle.defaultTopRowHeight) * scaling;
  final padding =
      ((merged.padding ?? vs.padding ?? CoreAppBarStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final spacing =
      theme.geometry.space(
        merged.spacing ?? vs.spacing ?? CoreAppBarStyle.defaultSpacing,
      ) *
      scaling;
  final actionSpacing =
      theme.geometry.space(
        merged.actionSpacing ??
            vs.actionSpacing ??
            CoreAppBarStyle.defaultActionSpacing,
      ) *
      scaling;
  final titlePadding =
      ((merged.titlePadding ?? vs.titlePadding!).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final dividerWidth = theme.geometry.stroke(
    merged.dividerWidth ?? CoreAppBarStyle.defaultDividerWidth,
    scaling: scaling,
  );

  // ─── Stage 2 EMIT — colours (Flutter: scheme.resolve(c).toValue()) ──
  final material = materialTheme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ??
            vs.backgroundColor ??
            CoreAppBarStyle.defaultBackgroundColor,
      )
      .toValue();
  final dividerColor = scheme
      .resolve(merged.dividerColor ?? CoreAppBarStyle.defaultDividerColor)
      .toValue();

  // ─── Stage 2 EMIT — title typography (.toValue(theme:)) ──
  final titleTextStyle = vs.titleStyle!
      .merge(merged.titleStyle)
      .toValue(theme: theme);

  // ─── Stage 2 EMIT — elevated shadow (scheme shadow tint) ──
  // Tinted with the scheme's `shadow` token (toast / button precedent)
  // and converted through the shared `CoreShadowLayersToFlutter`
  // adapter. Geometry is not multiplied by `scaling` — the Web
  // `box-shadow` never scales either (window-panel precedent).
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();
  final elevatedShadow =
      (merged.elevatedShadow ?? CoreAppBarStyle.defaultElevatedShadow).toValue(
        base: shadowBase,
        geometry: theme.geometry,
      );

  return ResolvedAppBar(
    actionCapsuleStyle: glassChrome
        ? CoreAppBarStyle.glassActionStyle.copyWith(
            surfaceStyle: merged.surfaceStyle,
            spacing: merged.actionSpacing,
          )
        : null,
    height: height,
    topRowHeight: topRowHeight,
    backgroundColor: backgroundColor.withValues(
      alpha: glassChrome
          ? (merged.backgroundColor == null ? 0 : backgroundColor.a)
          : backgroundColor.a * (material?.opacityIn(theme) ?? 1),
    ),
    material: material,
    surfaceSheen: resolveSurfaceSheen(
      materialTheme,
      role: CoreSurfaceRole.functional,
    ),
    refraction: materialTheme.surfaceRefraction,
    padding: padding,
    spacing: spacing,
    actionSpacing: actionSpacing,
    titleTextStyle: titleTextStyle,
    titlePadding: titlePadding,
    dividerColor: resolveSurfaceStroke(
      materialTheme,
      dividerColor,
      role: CoreSurfaceRole.functional,
    ),
    dividerWidth: dividerWidth,
    elevatedShadow: elevatedShadow,
  );
}
