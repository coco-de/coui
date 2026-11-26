import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';

/// Where [ThemeData.lerp] switches a field it cannot interpolate from the
/// first theme to the second.
///
/// Every snapped field — brightness included — switches on this one
/// threshold, so a crossfade frame never pairs one theme's colours with
/// the other's typography or geometry.
///
/// `lerp(a, b, t) == lerp(b, a, 1 - t)` holds for every `t` except
/// exactly this value. A step function cannot be symmetric at its own
/// step: `t < 0.5` picks `b` from one side and `a` from the other, and
/// `t <= 0.5` only moves the disagreement. At exactly 0.5 a snapped field
/// is, by definition, the second argument's.
const _kLerpThreshold = 0.5;

/// Per-axis scaling factors for a platform — radius, size and text —
/// that [scale] multiplies into a [ThemeData].
class AdaptiveScaling {
  /// Creates a scaling that applies [scaling] to all three axes.
  const AdaptiveScaling([double scaling = 1])
    : this.only(
        radiusScaling: scaling,
        sizeScaling: scaling,
        textScaling: scaling,
      );

  /// Creates a scaling with a separate factor per axis. Each defaults to
  /// `1`, which leaves that axis unchanged.
  const AdaptiveScaling.only({
    this.radiusScaling = 1,
    this.sizeScaling = 1,
    this.textScaling = 1,
  });

  /// Linearly interpolates each axis factor between [a] and [b].
  factory AdaptiveScaling.lerp(
    AdaptiveScaling a,
    AdaptiveScaling b,
    double t,
  ) {
    return AdaptiveScaling.only(
      radiusScaling: lerpDouble(a.radiusScaling, b.radiusScaling, t)!,
      sizeScaling: lerpDouble(a.sizeScaling, b.sizeScaling, t)!,
      textScaling: lerpDouble(a.textScaling, b.textScaling, t)!,
    );
  }

  /// No scaling on any axis — the default for desktop and the other
  /// non-mobile platforms (see [AdaptiveScaler.defaultScaling]).
  static const desktop = AdaptiveScaling();

  /// No scaling on any axis — the default for iOS and Android (see
  /// [AdaptiveScaler.defaultScaling]), so a phone renders at the size the
  /// desktop and the web do. An app that wants larger sizing on phones passes
  /// its own factor, e.g. `AdaptiveScaling(1.25)`.
  static const mobile = AdaptiveScaling();

  /// Multiplier [scale] applies to [ThemeData.radiusScaling].
  final double radiusScaling;

  /// Multiplier [scale] applies to [ThemeData.scaling], the factor
  /// resolvers multiply into dimensional values.
  final double sizeScaling;

  /// Multiplier [scale] applies to [ThemeData.typography] and
  /// [ThemeData.iconTheme].
  final double textScaling;

  /// Returns [typography] with [textScaling] multiplied in — the type scale
  /// [scale] gives a theme, and the same instance when the factor is `1`.
  CoreTypography scaleTypography(CoreTypography typography) =>
      textScaling == 1 ? typography : typography.scale(textScaling);

  /// Returns [theme] with each factor other than `1` multiplied in.
  ///
  /// A factor of `1` leaves its fields untouched rather than multiplying
  /// by one.
  ThemeData scale(ThemeData theme) {
    return theme.copyWith(
      typography: textScaling == 1
          ? null
          : () => scaleTypography(theme.typography),
      iconTheme: textScaling == 1
          ? null
          : () => theme.iconTheme.scale(textScaling),
      radiusScaling: radiusScaling == 1
          ? null
          : () => theme.radiusScaling * radiusScaling,
      scaling: sizeScaling == 1 ? null : () => theme.scaling * sizeScaling,
    );
  }
}

/// Re-provides the ambient [Theme] to [child] with [scaling] applied
/// (see [AdaptiveScaling.scale]).
class AdaptiveScaler extends StatelessWidget {
  /// Creates a scaler that applies [scaling] to the ambient theme for
  /// [child].
  const AdaptiveScaler({
    required this.child,
    required this.scaling,
    super.key,
  });

  /// The default scaling for the platform of the [Theme] above [context]
  /// — [defaultScaling] of [Theme.of].
  static AdaptiveScaling defaultScalingOf(BuildContext context) {
    final theme = Theme.of(context);

    return defaultScaling(theme);
  }

  /// The default scaling for [theme]'s platform: [AdaptiveScaling.mobile]
  /// on iOS and Android, [AdaptiveScaling.desktop] everywhere else.
  static AdaptiveScaling defaultScaling(ThemeData theme) {
    switch (theme.platform) {
      case .iOS:
      case .android:
        return .mobile;

      case .fuchsia:
      case .linux:
      case .macOS:
      case .windows:
        return .desktop;
    }
  }

  /// The factors applied to the ambient theme.
  final AdaptiveScaling scaling;

  /// The subtree that reads the scaled theme.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A `TypographyTierScope` below tells which tier the subtree is at by
    // the sizes of the scale around it, against the published ones. Those
    // sizes are multiplied here, so the published ones are multiplied the
    // same way — or a scope in this subtree would match none of them, take
    // the multiplied scale for one the subtree authored, and leave it at the
    // viewport's tier.
    final tiers = AppTypographyTiers.maybeOf(context);

    return Theme(
      data: scaling.scale(theme),
      child: tiers == null
          ? child
          : AppTypographyTiers(
              mobile: scaling.scaleTypography(tiers.mobile),
              tablet: scaling.scaleTypography(tiers.tablet),
              desktop: scaling.scaleTypography(tiers.desktop),
              child: child,
            ),
    );
  }
}

/// The theme CoUI widgets read through [Theme.of]: the resolved colour
/// scheme, typography, scaling and the active style's surface material.
///
/// Usually built from a platform-neutral [CoreThemeData] with
/// [ThemeData.fromCore], so Flutter derives its theme from the same
/// definitions coui_web does.
@immutable
class ThemeData {
  /// Creates a theme from explicit fields. Every field has a default, so
  /// only the ones that differ need to be passed.
  const ThemeData({
    this.colorScheme = const ResolvedColorScheme.tokenized(),
    this.coreComponentTheme,
    this.designSystem = .coui,
    this.iconTheme = const IconThemeProperties(),
    TargetPlatform? platform,
    this.radiusScaling = 1,
    this.scaling = 1,
    this.reduceTransparency = false,
    this.surfaceQuality = CoreQualityTier.defaultTier,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.surfaceSaturation,
    this.surfaceBackdropBrightness,
    this.surfaceSheen,
    this.surfaceDrawsOwnEdge = false,
    this.overlayMorph,
    this.surfaceRefraction,
    this.surfaceFrost,
    this.surfaceBodyShade,
    this.functionalSurface,
    this.nestedSurfaces,
    this.geometry = const CoreSurfaceGeometryConstraint(),
    this.typography = CoreTypography.coui,
    this.tapSoundEnabled = true,
  }) : _platform = platform;

  /// Creates a theme for a dark colour scheme.
  ///
  /// Takes the same parameters, with the same defaults, as the unnamed
  /// constructor: a theme's [brightness] is read from its [colorScheme],
  /// not from which constructor built it.
  const ThemeData.dark({
    this.colorScheme = const ResolvedColorScheme.tokenized(),
    this.coreComponentTheme,
    this.designSystem = .coui,
    this.iconTheme = const IconThemeProperties(),
    TargetPlatform? platform,
    this.radiusScaling = 1,
    this.scaling = 1,
    this.reduceTransparency = false,
    this.surfaceQuality = CoreQualityTier.defaultTier,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.surfaceSaturation,
    this.surfaceBackdropBrightness,
    this.surfaceSheen,
    this.surfaceDrawsOwnEdge = false,
    this.overlayMorph,
    this.surfaceRefraction,
    this.surfaceFrost,
    this.surfaceBodyShade,
    this.functionalSurface,
    this.nestedSurfaces,
    this.geometry = const CoreSurfaceGeometryConstraint(),
    this.typography = CoreTypography.coui,
    this.tapSoundEnabled = true,
  }) : _platform = platform;

  /// Creates a [ThemeData] from a [CoreThemeData] (coui_core).
  ///
  /// This ensures Flutter themes are derived from the same core
  /// definitions used by coui_web and docs_site.
  /// ```dart
  /// final theme = ThemeData.fromCore(CoreThemePresets.light);
  /// ```
  factory ThemeData.fromCore(
    CoreThemeData core, {
    CoreComponentTheme? coreComponentTheme,
    IconThemeProperties iconTheme = const IconThemeProperties(),
    TargetPlatform? platform,
    double? surfaceBlur,
    double? surfaceOpacity,
    double? surfaceSaturation,
    double? surfaceBackdropBrightness,
    CoreSurfaceEdgeSheen? surfaceSheen,
    bool? surfaceDrawsOwnEdge,
    CoreSurfaceToken? functionalSurface,
    Map<CoreSurfaceRole, List<CoreSurfaceToken>>? nestedSurfaces,
  }) {
    // Apply core scaling factors to platform-specific tokens.
    final scaledIconTheme = core.textScaling != 1.0
        ? iconTheme.scale(core.textScaling)
        : iconTheme;

    // Apply textScaling to the typography token scale.
    final scaledCoreTypography = core.textScaling != 1.0
        ? core.typography.scale(core.textScaling)
        : core.typography;

    // Resolve the colour scheme through the active design-system adapter —
    // the Flutter theme-resolution path for the multi-DS axis. The CoUI
    // baseline adapter is a pass-through, so a `.coui` theme is unchanged.
    final resolvedColorScheme = core.designSystem.adapter.resolveColorScheme(
      core.colorScheme,
      core.brightness,
    );

    return ThemeData(
      colorScheme: resolvedColorScheme,
      coreComponentTheme: coreComponentTheme,
      designSystem: core.designSystem,
      iconTheme: scaledIconTheme,
      platform: platform,
      radiusScaling: core.radiusScaling,
      scaling: core.sizeScaling,
      // `core.defaultSurface` already carries these two values; asking the
      // caller to pass them again is how a theme ends up describing an
      // opaque surface while its own surface token says glass. Explicit
      // arguments still win, so a caller can override for one theme without
      // rewriting the token.
      surfaceBlur: surfaceBlur ?? core.defaultSurface?.blurRadius,
      surfaceOpacity:
          surfaceOpacity ??
          core.defaultSurface?.opacity.resolve(core.brightness),
      // Same reasoning, and the same failure if skipped: a theme built
      // from a glass token would blur without saturating, so the two
      // seats — this one and `applySurfaceStyle` — would draw different
      // glass from the same recipe.
      surfaceSaturation:
          surfaceSaturation ??
          core.defaultSurface?.saturationFor(core.brightness),
      // Resolved here rather than carried: the flat field is the number a
      // renderer takes, and this constructor already knows which mode it is
      // building for. `core.brightness` is the same value the colour scheme
      // was resolved through two lines up.
      surfaceBackdropBrightness:
          surfaceBackdropBrightness ??
          core.defaultSurface?.backdropBrightness.resolve(core.brightness),
      surfaceSheen: surfaceSheen ?? core.defaultSurface?.sheen,
      surfaceDrawsOwnEdge:
          surfaceDrawsOwnEdge ?? core.defaultSurface?.drawsOwnEdge ?? false,
      // A theme built straight from a token draws no role distinction —
      // it has one material and every surface gets it. `applySurfaceStyle`
      // is where a preset's second material arrives.
      functionalSurface: functionalSurface,
      nestedSurfaces: nestedSurfaces,
      geometry: core.geometry,
      typography: scaledCoreTypography,
      // Projected explicitly, like every field above it. This factory is
      // a selective copy, not a spread — a Core field with no line here
      // never reaches a widget, and the axis would look wired from the
      // authoring side while every control kept making a sound.
      tapSoundEnabled: core.tapSoundEnabled,
    );
  }

  /// Interpolates between [a] and [b] for an animated theme change.
  ///
  /// Colours, the scaling factors, the icon sizes and the surface material's
  /// scalars interpolate. Every field with no midpoint — typography, the
  /// design system, the component theme, the platform, the style-axis
  /// carriers and the booleans — switches from [a] to [b] at one shared
  /// threshold, so every snapped field changes on the same frame.
  factory ThemeData.lerp(ThemeData a, ThemeData b, double t) {
    // A token-only scheme — the default — carries slot names, not colours,
    // and colour interpolation needs the numbers. Resolve each side against
    // the palette a widget falls back to when it paints an unresolved
    // token, so the crossfade starts and ends on the colours that were on
    // screen. Without this, an animated theme change over a token-only
    // scheme throws mid-animation.
    CoreColorScheme paintable(CoreColorScheme scheme) =>
        scheme.resolveTokensAgainst(CoreThemePresets.lightColorScheme);

    final colorScheme = CoreColorScheme.lerp(
      paintable(a.colorScheme),
      paintable(b.colorScheme),
      t,
    ).resolved(lerpBrightness(a, b, t));

    // A step of the quality tier is never animated. Interpolating the blur,
    // the fill and the saturation between two tiers would be a crossfade of
    // the very effects the step gives up, run at the moment the device could
    // not afford them — and one more motion for a person who asked for none.
    // So a pair of themes that differ in tier takes the material of `b` from
    // the first frame, and the animation carries whatever else differs.
    final snapsMaterial = a.surfaceQuality != b.surfaceQuality;
    bool atB() => snapsMaterial || t >= _kLerpThreshold;

    return ThemeData(
      colorScheme: colorScheme,
      coreComponentTheme: t < _kLerpThreshold
          ? a.coreComponentTheme
          : b.coreComponentTheme,
      designSystem: t < _kLerpThreshold ? a.designSystem : b.designSystem,
      iconTheme: IconThemeProperties.lerp(a.iconTheme, b.iconTheme, t),
      platform: t < _kLerpThreshold ? a.platform : b.platform,
      radiusScaling: lerpDouble(a.radiusScaling, b.radiusScaling, t)!,
      scaling: lerpDouble(a.scaling, b.scaling, t)!,
      surfaceBlur: snapsMaterial
          ? b.surfaceBlur
          : lerpDouble(a.surfaceBlur, b.surfaceBlur, t),
      reduceTransparency: t < _kLerpThreshold
          ? a.reduceTransparency
          : b.reduceTransparency,
      surfaceQuality: b.surfaceQuality,
      surfaceOpacity: snapsMaterial
          ? b.surfaceOpacity
          : lerpDouble(a.surfaceOpacity, b.surfaceOpacity, t),
      surfaceSaturation: snapsMaterial
          ? b.surfaceSaturation
          : lerpDouble(a.surfaceSaturation, b.surfaceSaturation, t),
      surfaceBackdropBrightness: snapsMaterial
          ? b.surfaceBackdropBrightness
          : lerpDouble(
              a.surfaceBackdropBrightness,
              b.surfaceBackdropBrightness,
              t,
            ),
      // Snapped for the same reason `geometry` is, one field below:
      // absence is a state, not a number. A band fading in from "no band"
      // would have to start somewhere, and the only somewhere available
      // is a zero-width band of some colour — which reads as a value the
      // style never stated.
      surfaceSheen: atB() ? b.surfaceSheen : a.surfaceSheen,
      // Travels with the sheen it describes. Omitted, it silently fell back
      // to `false` for the whole crossfade, so a surface that draws its own
      // edge band lost the band until the animation finished.
      surfaceDrawsOwnEdge: atB()
          ? b.surfaceDrawsOwnEdge
          : a.surfaceDrawsOwnEdge,
      // Snapped, not interpolated. The constraint's scalars are a cap and a
      // floor, and both are nullable — an absent cap means "no cap", which
      // has no numeric midpoint with a cap of zero. Interpolating would read
      // an absent bound as zero and clamp the whole transition to the
      // hardest possible geometry. The other style-axis carriers
      // (typography, component theme) snap here for the same reason.
      // Snapped like the other style-axis carriers. A morph is a spring,
      // not a scalar; halfway between two springs is not a spring anyone
      // authored, and a theme crossfade is not the moment to invent one.
      overlayMorph: t < _kLerpThreshold ? a.overlayMorph : b.overlayMorph,
      // Snapped with the other style-axis carriers. A halfway bezel is a
      // third displacement map to bake for a frame nobody looks at.
      surfaceRefraction: atB() ? b.surfaceRefraction : a.surfaceRefraction,
      // Snapped for the same reason: a halfway frost is a third pass to
      // build for a frame nobody looks at, and a halfway shade is a number
      // between two looks. Both are material the tier takes away with the
      // pass they ride, so they follow the rest of the material.
      surfaceFrost: atB() ? b.surfaceFrost : a.surfaceFrost,
      surfaceBodyShade: atB() ? b.surfaceBodyShade : a.surfaceBodyShade,
      functionalSurface: atB() ? b.functionalSurface : a.functionalSurface,
      nestedSurfaces: atB() ? b.nestedSurfaces : a.nestedSurfaces,
      geometry: t < _kLerpThreshold ? a.geometry : b.geometry,
      typography: t < _kLerpThreshold ? a.typography : b.typography,
      // Snapped because a bool has no midpoint, and present at all
      // because this rebuilds the theme from scratch: a field omitted
      // here silently reverts to the default for the whole crossfade,
      // so an app that turned the sound off would hear it again only
      // while a theme transition is running.
      tapSoundEnabled: t < _kLerpThreshold
          ? a.tapSoundEnabled
          : b.tapSoundEnabled,
    );
  }

  /// The colour scheme widgets paint with.
  final ResolvedColorScheme colorScheme;

  /// Component theme configuration for all UI components.
  /// Cross-platform component theme overrides for * components.
  ///
  /// Provides per-component style defaults (skeleton, badge, etc.)
  /// that * widgets read via [Theme.of(context)].
  final CoreComponentTheme? coreComponentTheme;

  /// Active design system.
  ///
  /// [ThemeData.fromCore] resolves the colour scheme through this system's
  /// [DesignSystemAdapter] (`designSystem.adapter`), so M3E / Liquid Glass
  /// derive their scheme tokens while the CoUI baseline passes through
  /// unchanged.
  final DesignSystem designSystem;

  /// Geometry constraint contributed by the active surface style, carrying
  /// the app's density (`CoreSurfaceGeometryConstraint.density`).
  ///
  /// Identity unless a style or a density states otherwise. Resolvers read
  /// it where a Core geometry value becomes a Flutter one — a corner, an
  /// inset, a spacing value, a control row's height — so both axes reach
  /// every component through the conversion rather than through each
  /// component remembering to ask.
  final CoreSurfaceGeometryConstraint geometry;

  /// CoUI typography token scale (platform-neutral [CoreTypography]).
  ///
  /// Single source of truth for typography token resolution — mirrors
  /// [colorScheme] (`CoreColorScheme`) for the typography axis. Resolvers
  /// call `typography.resolve(textStyle)` for token-based
  /// `CoreTextStyle` lookup.
  final CoreTypography typography;

  /// Multiplier on corner radii — the radius axis of [AdaptiveScaling].
  final double radiusScaling;

  /// Multiplier resolvers apply to dimensional values — the size axis of
  /// [AdaptiveScaling].
  final double scaling;

  /// The icon size ladder. `CoUIApp` mounts its
  /// [IconThemeProperties.medium] step as the application's ambient
  /// `IconTheme`.
  final IconThemeProperties iconTheme;

  /// Fill opacity of the content-layer material, or null when the active
  /// style states none.
  ///
  /// Already resolved for this theme's mode: the recipe states the fill as a
  /// per-mode pair, and the seat that builds the theme collapses it against
  /// the brightness it is building for.
  ///
  /// Null is not `1.0`: with this, [surfaceBlur] and [surfaceSheen] all
  /// null the theme states no material at all, while a material stated by
  /// one of the other two and silent here draws opaque.
  final double? surfaceOpacity;

  /// Backdrop blur of the content-layer material, or null when the active
  /// style states none.
  final double? surfaceBlur;

  /// Accessibility policy retained for local material overrides.
  final bool reduceTransparency;

  /// The tier the surfaces under this theme are drawn at.
  ///
  /// Already folded in: the material fields above are what this tier leaves
  /// of the style's, so a resolver reads them and never this. It is retained
  /// for the one reader that has to apply it again — a local material
  /// override ([resolveSurfaceTheme]), which builds its material from a
  /// recipe of its own and must go without what the app's surfaces go
  /// without.
  ///
  /// A reduce-transparency preference is already the lowest tier here,
  /// because the one seat that writes this field (`applySurfaceStyle`) takes
  /// the preference before the tier it was handed.
  final CoreQualityTier surfaceQuality;

  /// Chroma lift applied to whatever shows through a translucent surface.
  ///
  /// Null means the active style states no material, which is not the
  /// same as stating identity — a style that says `1.0` has decided the
  /// backdrop is not amplified, and one that says nothing has left the
  /// surface as its component drew it, with no backdrop pass at all.
  final double? surfaceSaturation;

  /// How far the active style dims what shows through a surface, or null
  /// for no material.
  ///
  /// Null and `1.0` differ the same way they do for [surfaceSaturation]:
  /// `1.0` is a style that decided not to dim, null is a style that stated
  /// no material at all.
  final double? surfaceBackdropBrightness;

  /// Light running along a translucent surface's edges, or null for none.
  ///
  /// Decoration on top of the component's own border, never a
  /// replacement for it — the liquid-glass a11y contract declares
  /// `boundaryMechanism: .stroke`, and that stays true only because this
  /// band adds an edge rather than becoming one.
  final CoreSurfaceEdgeSheen? surfaceSheen;

  /// Whether the active surface material draws this surface's own edge.
  ///
  /// When true a component's resting stroke would be a second boundary on
  /// the same pixels, so the resolvers suppress its colour. Written by the
  /// style seat, never by a component — and never under high contrast,
  /// where the ordinary stroke is the only edge that survives.
  final bool surfaceDrawsOwnEdge;

  /// The morph an anchored overlay runs while it opens, or null for none.
  ///
  /// Written by the style seat, never by a component. A component reading
  /// the surface style directly would be the only component that supports
  /// the axis; reading a resolved value here means every overlay composed
  /// on the engine gets it at once.
  final CoreMorphSpring? overlayMorph;

  /// How strongly the active material bends what is behind a surface's
  /// edge, or null for a material that does not bend at all.
  ///
  /// A request rather than a map: each surface still builds its own
  /// displacement from its own rectangle, which is work it already did
  /// when the request came from a caller instead.
  final CoreSurfaceRefraction? surfaceRefraction;

  /// The cloud a surface lays over its own blur — a second, heavier blur of
  /// the backdrop mixed back over it — or null for a material that draws
  /// none (`CoreSurfaceFrost`).
  ///
  /// Already the share for [coreBrightness]: the style seat collapses the
  /// authored per-mode share into one number, the way it does for
  /// [surfaceSaturation] and [surfaceBackdropBrightness], so a surface
  /// reads it without asking which palette it is in. Null as well under
  /// high contrast and reduced transparency, where the seat takes it away.
  ///
  /// Costs one extra backdrop pass per surface that draws it. The one place
  /// that decides whether a surface pays for it is `resolveSurfaceFrost`.
  final CoreSurfaceFrost? surfaceFrost;

  /// How far a bright backdrop is pulled down under a surface, by its own
  /// luminance, or null for a material that does none
  /// (`CoreSurfaceBodyShade`).
  ///
  /// Collapsed to the strength for [coreBrightness] like [surfaceFrost], and
  /// null under high contrast and reduced transparency.
  final CoreSurfaceBodyShade? surfaceBodyShade;

  /// The material a surface that floats above the content layer draws,
  /// or null when the active style draws no distinction.
  ///
  /// Null is not "floating surfaces get nothing" — [surfaceFor] resolves
  /// it to the content-layer material, which is what makes the role free
  /// for the styles that do not use it.
  final CoreSurfaceToken? functionalSurface;

  /// What each role's material becomes once a surface sits inside
  /// another one, by depth. Null means the active style does not change
  /// with nesting.
  ///
  /// The last entry is the floor — see `CoreSurfaceRecipe.nestedSurfaces`
  /// for why nesting needs one at all.
  final Map<CoreSurfaceRole, List<CoreSurfaceToken>>? nestedSurfaces;

  /// Whether a tap plays the platform's click sound.
  ///
  /// Read by `Clickable`, the kit's only emitter of that sound, so
  /// turning it off here silences every control composed on it —
  /// including the ones CoUI builds for itself, which a caller has no
  /// parameter to reach. Mirrors [CoreThemeData.tapSoundEnabled], and is
  /// deliberately a different name from `enableFeedback` (press chrome).
  final bool tapSoundEnabled;

  final TargetPlatform? _platform;

  /// The current platform.
  TargetPlatform get platform => _platform ?? defaultTargetPlatform;

  /// Brightness derived from the active color scheme.
  ///
  /// Heuristic: a scheme is considered dark when its resolved `surface`
  /// colour has a luminance below 0.5. Unresolved tokens (the default
  /// `CoreColorScheme.tokenized()`) resolve via
  /// [CoreThemePresets.lightColorScheme] (the designer light palette).
  Brightness get brightness {
    const luminanceMidpoint = 0.5;
    final surface = colorScheme.surface;
    final resolved = colorScheme.resolve(surface);
    final color = resolved.toValue();
    return color.computeLuminance() < luminanceMidpoint ? .dark : .light;
  }

  /// The same answer in the platform-neutral vocabulary.
  ///
  /// Exists because the values a theme resolves *from* are stated in
  /// `coui_core`, which has no `dart:ui`. Derived from [brightness] rather
  /// than measured again — two luminance heuristics for one question is how
  /// a theme comes to disagree with itself about which mode it is in.
  CoreBrightness get coreBrightness => brightness == Brightness.dark
      ? CoreBrightness.dark
      : CoreBrightness.light;

  /// Returns a copy with the given fields replaced.
  ///
  /// Each argument is a getter rather than a value, so a nullable field can
  /// be set back to null: an omitted getter keeps the current value, and a
  /// getter that returns null clears it.
  ThemeData copyWith({
    ValueGetter<CoreColorScheme>? colorScheme,
    ValueGetter<CoreComponentTheme>? coreComponentTheme,
    ValueGetter<CoreTypography>? typography,
    ValueGetter<DesignSystem>? designSystem,
    ValueGetter<IconThemeProperties>? iconTheme,
    ValueGetter<TargetPlatform>? platform,
    ValueGetter<double>? radiusScaling,
    ValueGetter<double>? scaling,
    ValueGetter<bool>? reduceTransparency,
    ValueGetter<CoreQualityTier>? surfaceQuality,
    // `double?`, matching the field. A material that states no backdrop
    // pass says so with null, and a slot that cannot carry null forces
    // the seat to coerce it to zero — which made this theme claim a pass
    // its recipe never stated.
    ValueGetter<double?>? surfaceBlur,
    ValueGetter<double>? surfaceOpacity,
    // Nullable type arguments, like `surfaceBlur` above and unlike
    // `surfaceOpacity`. A getter of `double` has no way to say "no
    // material", so a value switched on by one style cannot be switched
    // off by a later `copyWith` — `null` means the style states none, and
    // stating none has to stay expressible.
    //
    // `surfaceOpacity` is the one that still carries that limitation, and
    // it is the least harmful place for it: an absent fill and a fully
    // opaque one paint the same pixels, so the two answers are not
    // distinguishable on screen the way an absent blur and a zero blur
    // were.
    ValueGetter<double?>? surfaceSaturation,
    ValueGetter<double?>? surfaceBackdropBrightness,
    ValueGetter<CoreSurfaceEdgeSheen?>? surfaceSheen,
    ValueGetter<bool>? surfaceDrawsOwnEdge,
    ValueGetter<CoreMorphSpring?>? overlayMorph,
    ValueGetter<CoreSurfaceRefraction?>? surfaceRefraction,
    ValueGetter<CoreSurfaceFrost?>? surfaceFrost,
    ValueGetter<CoreSurfaceBodyShade?>? surfaceBodyShade,
    ValueGetter<CoreSurfaceToken?>? functionalSurface,
    ValueGetter<Map<CoreSurfaceRole, List<CoreSurfaceToken>>?>? nestedSurfaces,
    ValueGetter<CoreSurfaceGeometryConstraint>? geometry,
    ValueGetter<bool>? tapSoundEnabled,
  }) {
    return ThemeData(
      colorScheme: colorScheme == null
          ? this.colorScheme
          : colorScheme().resolved(
              brightness == .dark ? .dark : .light,
            ),
      coreComponentTheme: coreComponentTheme == null
          ? this.coreComponentTheme
          : coreComponentTheme(),
      designSystem: designSystem == null ? this.designSystem : designSystem(),
      iconTheme: iconTheme == null ? this.iconTheme : iconTheme(),
      platform: platform == null ? _platform : platform(),
      radiusScaling: radiusScaling == null
          ? this.radiusScaling
          : radiusScaling(),
      scaling: scaling == null ? this.scaling : scaling(),
      reduceTransparency: reduceTransparency == null
          ? this.reduceTransparency
          : reduceTransparency(),
      surfaceQuality: surfaceQuality == null
          ? this.surfaceQuality
          : surfaceQuality(),
      surfaceBlur: surfaceBlur == null ? this.surfaceBlur : surfaceBlur(),
      surfaceOpacity: surfaceOpacity == null
          ? this.surfaceOpacity
          : surfaceOpacity(),
      surfaceSaturation: surfaceSaturation == null
          ? this.surfaceSaturation
          : surfaceSaturation(),
      surfaceBackdropBrightness: surfaceBackdropBrightness == null
          ? this.surfaceBackdropBrightness
          : surfaceBackdropBrightness(),
      surfaceSheen: surfaceSheen == null ? this.surfaceSheen : surfaceSheen(),
      surfaceDrawsOwnEdge: surfaceDrawsOwnEdge == null
          ? this.surfaceDrawsOwnEdge
          : surfaceDrawsOwnEdge(),
      overlayMorph: overlayMorph == null ? this.overlayMorph : overlayMorph(),
      surfaceRefraction: surfaceRefraction == null
          ? this.surfaceRefraction
          : surfaceRefraction(),
      surfaceFrost: surfaceFrost == null ? this.surfaceFrost : surfaceFrost(),
      surfaceBodyShade: surfaceBodyShade == null
          ? this.surfaceBodyShade
          : surfaceBodyShade(),
      functionalSurface: functionalSurface == null
          ? this.functionalSurface
          : functionalSurface(),
      nestedSurfaces: nestedSurfaces == null
          ? this.nestedSurfaces
          : nestedSurfaces(),
      geometry: geometry == null ? this.geometry : geometry(),
      typography: typography == null ? this.typography : typography(),
      tapSoundEnabled: tapSoundEnabled == null
          ? this.tapSoundEnabled
          : tapSoundEnabled(),
    );
  }

  /// The material a surface of [role] draws under the active style.
  ///
  /// The one place a role becomes a material on this platform. Resolvers
  /// call this with the role their component declared; nothing else
  /// branches on it, which is what keeps the axis out of component code.
  ///
  /// The material comes out **as this theme draws it**: a term the material
  /// states for one mode only (the chroma lift in dark, the angle the edge
  /// light comes from in dark) is already the number for this theme's mode,
  /// and nothing is left to ask. That is what lets every resolver read
  /// `material.saturation` and `resolveSurfaceSheen` read the wall without
  /// each of them remembering which palette it is under. The terms authored
  /// as pairs (the fill, the dimming) stay pairs and are resolved by their
  /// readers, as they always were.
  CoreSurfaceToken? surfaceFor(CoreSurfaceRole role, {int depth = 0}) {
    final base = role == CoreSurfaceRole.functional && functionalSurface != null
        ? functionalSurface
        : _contentMaterial;
    if (depth <= 0) return _inThisMode(base);

    final steps = nestedSurfaces?[role];
    if (steps == null || steps.isEmpty) return _inThisMode(base);

    // Clamped, not indexed past the end. The last entry is the floor: a
    // surface five deep keeps what a surface three deep got, rather than
    // thinning into a material that is not there.
    return _inThisMode(
      steps[depth - 1 < steps.length ? depth - 1 : steps.length - 1],
    );
  }

  /// [token] collapsed to this theme's mode, or [token] itself when it
  /// states nothing per mode.
  ///
  /// The mode of a theme is derived from its palette on every ask, so the
  /// check for "does it matter" comes first and every material that never
  /// states a per-mode term — which is every shipped one — costs a handful of
  /// null checks.
  CoreSurfaceToken? _inThisMode(CoreSurfaceToken? token) =>
      token == null || !token.statesByMode
      ? token
      : token.atBrightness(coreBrightness);

  /// The content-layer material, assembled from the flat fields.
  ///
  /// The flat fields stay authoritative rather than being mirrored by a
  /// second token, and this is why: `surfaceOpacity` and its siblings are
  /// public, and `copyWith(surfaceOpacity: …)` is how a caller retunes one
  /// term of the material without restating the rest. A stored twin would
  /// go stale against exactly that call — measured, not feared: it left a
  /// navigation bar opaque under a theme that had asked for 70%, and the
  /// only thing that said so was a test reading the painted fill.
  ///
  /// So there is one source and this reassembles from it. Null when the
  /// theme states no material at all, which is every style but glass.
  CoreSurfaceToken? get _contentMaterial {
    final blur = surfaceBlur;
    final opacity = surfaceOpacity;
    final sheen = surfaceSheen;
    if (blur == null && opacity == null && sheen == null) return null;

    return CoreSurfaceToken(
      // Derived rather than carried: nothing downstream reads `type` —
      // it exists for `toString` — and deriving it keeps this from being
      // a seventh field the flats would have to carry.
      type: (blur ?? 0) > 0 || (opacity ?? 1) < 1
          ? SurfaceType.glass
          : SurfaceType.flat,
      // Already resolved on the way in, like the brightness below: the flat
      // field is the number for this theme's mode, so the pair this
      // reassembles says the same number twice.
      opacity: CoreSurfaceOpacity.same(
        opacity ?? CoreSurfaceOpacity.opaqueValue,
      ),
      blurRadius: blur,
      saturation: surfaceSaturation ?? CoreSurfaceToken.identitySaturation,
      // Already resolved on the way in, so the pair this rebuilds says the
      // same number twice. Reassembling it as a pair keeps the token's one
      // shape rather than giving the flat path a second one.
      backdropBrightness: CoreBackdropBrightness.same(
        surfaceBackdropBrightness ?? CoreSurfaceToken.identityBrightness,
      ),
      sheen: sheen,
      // The token asserts that a surface claiming its own edge draws a
      // band. A hand-built theme can set the flag and no band, and that
      // combination must not blow up here — it is the caller's to fix,
      // not this getter's to crash on.
      drawsOwnEdge: surfaceDrawsOwnEdge && sheen != null,
    );
  }

  /// The brightness [ThemeData.lerp] resolves its interpolated scheme
  /// against.
  ///
  /// Snapped on the same threshold as every other field [ThemeData.lerp]
  /// cannot interpolate. It picks the default palette for slots neither scheme
  /// sets; taken from `b` unconditionally, a light→dark crossfade would
  /// fill those from the dark palette while typography and geometry were
  /// still the light theme's.
  ///
  /// A separate seam because the value does not reach the screen today:
  /// both endpoints carry a [ResolvedColorScheme], so the interpolated
  /// scheme has no unset slot for this palette to fill, and a regression
  /// to "always `b`" renders identically. The rule is pinned here instead
  /// of by pixels.
  @visibleForTesting
  static CoreBrightness lerpBrightness(ThemeData a, ThemeData b, double t) =>
      t < _kLerpThreshold ? a.coreBrightness : b.coreBrightness;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeData &&
        other.colorScheme == colorScheme &&
        other.coreComponentTheme == coreComponentTheme &&
        other.typography == typography &&
        other.designSystem == designSystem &&
        other.radiusScaling == radiusScaling &&
        other.scaling == scaling &&
        other.iconTheme == iconTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur &&
        other.reduceTransparency == reduceTransparency &&
        other.surfaceQuality == surfaceQuality &&
        other.surfaceSaturation == surfaceSaturation &&
        other.surfaceBackdropBrightness == surfaceBackdropBrightness &&
        other.surfaceSheen == surfaceSheen &&
        // Both style-axis fields, and both easy to leave out. A theme the
        // axis wrote that compares equal to the one before it does not
        // rebuild — the value is computed correctly and never reaches the
        // screen, which is the failure mode the axis rules single out.
        other.surfaceDrawsOwnEdge == surfaceDrawsOwnEdge &&
        other.overlayMorph == overlayMorph &&
        other.surfaceRefraction == surfaceRefraction &&
        other.surfaceFrost == surfaceFrost &&
        other.surfaceBodyShade == surfaceBodyShade &&
        other.functionalSurface == functionalSurface &&
        // By value: the table is rebuilt for the same answer whenever the
        // app root builds under a tuning that states the light, and an
        // identity comparison would call every one of those a changed
        // theme and rebuild everything under it.
        CoreSurfaceRecipe.nestedSurfacesEqual(
          other.nestedSurfaces,
          nestedSurfaces,
        ) &&
        other.geometry == geometry &&
        other.tapSoundEnabled == tapSoundEnabled;
  }

  @override
  String toString() {
    return 'ThemeData(colorScheme: $colorScheme, '
        'radiusScaling: $radiusScaling, scaling: $scaling, '
        'iconTheme: $iconTheme, surfaceOpacity: $surfaceOpacity, '
        'surfaceBlur: $surfaceBlur)';
  }

  @override
  int get hashCode {
    // `hashAll`: `Object.hash` takes at most twenty fields.
    return Object.hashAll([
      colorScheme,
      coreComponentTheme,
      typography,
      designSystem,
      radiusScaling,
      scaling,
      iconTheme,
      surfaceOpacity,
      surfaceBlur,
      reduceTransparency,
      surfaceQuality,
      surfaceSaturation,
      surfaceBackdropBrightness,
      functionalSurface,
      CoreSurfaceRecipe.nestedSurfacesHash(nestedSurfaces),
      surfaceSheen,
      surfaceDrawsOwnEdge,
      overlayMorph,
      surfaceRefraction,
      surfaceFrost,
      surfaceBodyShade,
      geometry,
      tapSoundEnabled,
    ]);
  }
}

/// Theme widget that provides [ThemeData] to descendant widgets.
class Theme extends StatelessWidget {
  /// Creates a scope that provides [data] to [child].
  const Theme({required this.child, required this.data, super.key});

  /// The nearest [ThemeData] above [context].
  ///
  /// Asserts that a [Theme] scope is present; use [maybeOf] where one may
  /// not be.
  static ThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<_InheritedTheme>();
    assert(theme != null, 'No Theme found in context');

    return theme!.data;
  }

  /// The nearest [ThemeData] above [context], or `null` when no [Theme]
  /// scope is present.
  ///
  /// Unlike [of], this never asserts — use it for Theme-optional widgets
  /// that must also render outside a [Theme] (e.g. a low-level [Stacks]
  /// barrier whose only theme dependency is an optional per-component
  /// override).
  static ThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedTheme>()?.data;
  }

  /// The theme provided to the subtree.
  final ThemeData data;

  /// The subtree that reads [data].
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ThemeData>('data', data));
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(data: data, child: child);
  }
}

/// Internal InheritedWidget that holds the [ThemeData].
class _InheritedTheme extends InheritedTheme {
  const _InheritedTheme({required super.child, required this.data});

  final ThemeData data;

  @override
  bool updateShouldNotify(covariant _InheritedTheme oldWidget) {
    return oldWidget.data != data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ancestorTheme = context
        .findAncestorWidgetOfExactType<_InheritedTheme>();

    if (identical(this, ancestorTheme)) {
      return child;
    }

    return _InheritedTheme(data: data, child: child);
  }
}

/// A [Tween] between two [ThemeData]s, interpolated by [ThemeData.lerp].
class ThemeDataTween extends Tween<ThemeData> {
  /// Creates a tween from [begin] to [end]. A null [end] holds [begin].
  ThemeDataTween({required ThemeData super.begin, required super.end});

  @override
  ThemeData lerp(double t) {
    return end == null ? begin! : ThemeData.lerp(begin!, end!, t);
  }
}

/// A [Theme] that animates to a new [data] over [duration] instead of
/// switching at once.
class AnimatedTheme extends ImplicitlyAnimatedWidget {
  /// Creates a theme scope that animates changes of [data].
  const AnimatedTheme({
    required this.child,
    required this.data,
    required super.duration,
    super.curve,
    super.key,
  });

  /// The theme to animate toward.
  final ThemeData data;

  /// The subtree that reads the animated theme.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedTheme> createState() => _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data =
        visitor(
              _data,
              widget.data,
              (dynamic value) =>
                  ThemeDataTween(begin: value as ThemeData, end: null),
            )
            as ThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _data!.evaluate(animation);

    return Theme(data: theme, child: widget.child);
  }
}

/// The icon size ladder a theme carries, from [x4Small] (`6` by default)
/// to [x4Large] (`56` by default). [ThemeData.iconTheme] holds one, and
/// `CoUIApp` mounts its [medium] step as the application's ambient
/// `IconTheme`.
@immutable
class IconThemeProperties {
  /// Creates an icon size ladder. Each step defaults to its standard size.
  const IconThemeProperties({
    this.large = const IconThemeData(size: 24),
    this.medium = const IconThemeData(size: CoreIconStyle.defaultAmbientSize),
    this.small = const IconThemeData(size: 16),
    this.x2Large = const IconThemeData(size: 40),
    this.x2Small = const IconThemeData(size: 10),
    this.x3Large = const IconThemeData(size: 48),
    this.x3Small = const IconThemeData(size: 8),
    this.x4Large = const IconThemeData(size: 56),
    this.x4Small = const IconThemeData(size: 6),
    this.xLarge = const IconThemeData(size: 32),
    this.xSmall = const IconThemeData(size: 12),
  });

  /// Interpolates each step between [a] and [b] with [IconThemeData.lerp].
  factory IconThemeProperties.lerp(
    IconThemeProperties a,
    IconThemeProperties b,
    double t,
  ) {
    return IconThemeProperties(
      large: IconThemeData.lerp(a.large, b.large, t),
      medium: IconThemeData.lerp(a.medium, b.medium, t),
      small: IconThemeData.lerp(a.small, b.small, t),
      x2Large: IconThemeData.lerp(a.x2Large, b.x2Large, t),
      x2Small: IconThemeData.lerp(a.x2Small, b.x2Small, t),
      x3Large: IconThemeData.lerp(a.x3Large, b.x3Large, t),
      x3Small: IconThemeData.lerp(a.x3Small, b.x3Small, t),
      x4Large: IconThemeData.lerp(a.x4Large, b.x4Large, t),
      x4Small: IconThemeData.lerp(a.x4Small, b.x4Small, t),
      xLarge: IconThemeData.lerp(a.xLarge, b.xLarge, t),
      xSmall: IconThemeData.lerp(a.xSmall, b.xSmall, t),
    );
  }

  /// Size `6` by default.
  final IconThemeData x4Small;

  /// Size `8` by default.
  final IconThemeData x3Small;

  /// Size `10` by default.
  final IconThemeData x2Small;

  /// Size `12` by default.
  final IconThemeData xSmall;

  /// Size `16` by default.
  final IconThemeData small;

  /// The step `CoUIApp` mounts as the application's ambient `IconTheme`, so
  /// its default is [CoreIconStyle.defaultAmbientSize] — the same value Web
  /// `CoUIWeb` mounts at its root.
  final IconThemeData medium;

  /// Size `24` by default.
  final IconThemeData large;

  /// Size `32` by default.
  final IconThemeData xLarge;

  /// Size `40` by default.
  final IconThemeData x2Large;

  /// Size `48` by default.
  final IconThemeData x3Large;

  /// Size `56` by default.
  final IconThemeData x4Large;

  /// Returns a copy with the given steps replaced. An omitted getter keeps
  /// the current step.
  IconThemeProperties copyWith({
    ValueGetter<IconThemeData>? large,
    ValueGetter<IconThemeData>? medium,
    ValueGetter<IconThemeData>? small,
    ValueGetter<IconThemeData>? x2Large,
    ValueGetter<IconThemeData>? x2Small,
    ValueGetter<IconThemeData>? x3Large,
    ValueGetter<IconThemeData>? x3Small,
    ValueGetter<IconThemeData>? x4Large,
    ValueGetter<IconThemeData>? x4Small,
    ValueGetter<IconThemeData>? xLarge,
    ValueGetter<IconThemeData>? xSmall,
  }) {
    return IconThemeProperties(
      large: large == null ? this.large : large(),
      medium: medium == null ? this.medium : medium(),
      small: small == null ? this.small : small(),
      x2Large: x2Large == null ? this.x2Large : x2Large(),
      x2Small: x2Small == null ? this.x2Small : x2Small(),
      x3Large: x3Large == null ? this.x3Large : x3Large(),
      x3Small: x3Small == null ? this.x3Small : x3Small(),
      x4Large: x4Large == null ? this.x4Large : x4Large(),
      x4Small: x4Small == null ? this.x4Small : x4Small(),
      xLarge: xLarge == null ? this.xLarge : xLarge(),
      xSmall: xSmall == null ? this.xSmall : xSmall(),
    );
  }

  /// Returns a copy with every step's size multiplied by [factor]. A step
  /// with no size is kept as it is.
  IconThemeProperties scale(double factor) {
    return IconThemeProperties(
      large: large.size == null
          ? large
          : large.copyWith(size: large.size! * factor),
      medium: medium.size == null
          ? medium
          : medium.copyWith(size: medium.size! * factor),
      small: small.size == null
          ? small
          : small.copyWith(size: small.size! * factor),
      x2Large: x2Large.size == null
          ? x2Large
          : x2Large.copyWith(size: x2Large.size! * factor),
      x2Small: x2Small.size == null
          ? x2Small
          : x2Small.copyWith(size: x2Small.size! * factor),
      x3Large: x3Large.size == null
          ? x3Large
          : x3Large.copyWith(size: x3Large.size! * factor),
      x3Small: x3Small.size == null
          ? x3Small
          : x3Small.copyWith(size: x3Small.size! * factor),
      x4Large: x4Large.size == null
          ? x4Large
          : x4Large.copyWith(size: x4Large.size! * factor),
      x4Small: x4Small.size == null
          ? x4Small
          : x4Small.copyWith(size: x4Small.size! * factor),
      xLarge: xLarge.size == null
          ? xLarge
          : xLarge.copyWith(size: xLarge.size! * factor),
      xSmall: xSmall.size == null
          ? xSmall
          : xSmall.copyWith(size: xSmall.size! * factor),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IconThemeProperties &&
        other.x4Small == x4Small &&
        other.x3Small == x3Small &&
        other.x2Small == x2Small &&
        other.xSmall == xSmall &&
        other.small == small &&
        other.medium == medium &&
        other.large == large &&
        other.xLarge == xLarge &&
        other.x2Large == x2Large &&
        other.x3Large == x3Large &&
        other.x4Large == x4Large;
  }

  @override
  String toString() {
    return 'IconThemeProperties(x4Small: $x4Small, x3Small: $x3Small, '
        'x2Small: $x2Small, xSmall: $xSmall, small: $small, '
        'medium: $medium, large: $large, xLarge: $xLarge, '
        'x2Large: $x2Large, x3Large: $x3Large, x4Large: $x4Large)';
  }

  @override
  int get hashCode {
    return Object.hash(
      x4Small,
      x3Small,
      x2Small,
      xSmall,
      small,
      medium,
      large,
      xLarge,
      x2Large,
      x3Large,
      x4Large,
    );
  }
}
