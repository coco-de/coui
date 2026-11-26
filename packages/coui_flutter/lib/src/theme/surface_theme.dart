import 'package:coui_flutter/coui_flutter.dart';

/// Overrides only the material axis for a component or subtree.
///
/// Colours, typography, density and component styles remain inherited. Use
/// [CoreSurfaceStyleId.defaultStyle] to explicitly remove an inherited glass
/// material. Accessibility preferences and the app's quality tier always take
/// precedence: a local material never draws what the surrounding theme has
/// given up.
class SurfaceTheme extends StatelessWidget {
  /// Applies [surfaceStyle] to [child] without changing other theme axes.
  const SurfaceTheme({
    required this.surfaceStyle,
    required this.child,
    super.key,
  });

  /// Material preset for this subtree.
  final CoreSurfaceStyleId surfaceStyle;

  /// The subtree receiving the material.
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: resolveSurfaceTheme(context, surfaceStyle),
    child: child,
  );
}

/// Resolves a local material without reapplying the other theme axes.
ThemeData resolveSurfaceTheme(
  BuildContext context,
  CoreSurfaceStyleId? surfaceStyle,
) {
  final base = Theme.of(context);
  if (surfaceStyle == null) return base;
  final recipe = resolveThemeRecipe(surfaceStyle: surfaceStyle);
  final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
  // The tier the app's own surfaces are drawn at. A local material is built
  // from a recipe of its own, so it has to go without what they go without —
  // a glass card in a theme that gave up glass is the card that would keep
  // the one backdrop pass the device could not afford.
  const ladder = CoreQualityLadder.standard;
  final tier = ladder.effective(
    base.surfaceQuality,
    reduceTransparency: base.reduceTransparency,
  );
  CoreSurfaceToken? accessible(CoreSurfaceToken? token) {
    final settled = ladder.settle(tier, token);
    if (settled == null) return null;
    return highContrast ? settled.copyWith(drawsOwnEdge: false) : settled;
  }

  final surface = accessible(recipe.surface);
  return base.copyWith(
    surfaceBlur: () => surface?.blurRadius,
    surfaceOpacity: () => surface?.opacity.resolve(base.coreBrightness) ?? 1,
    surfaceSaturation: () => surface?.saturationFor(base.coreBrightness),
    surfaceBackdropBrightness: () =>
        surface?.backdropBrightness.resolve(base.coreBrightness),
    surfaceSheen: () => surface?.sheen,
    surfaceDrawsOwnEdge: () => surface?.drawsOwnEdge ?? false,
    functionalSurface: () => accessible(recipe.surfaceFor(.functional)),
    nestedSurfaces: () => recipe.nestedSurfaces?.map(
      (role, steps) =>
          MapEntry(role, steps.map((s) => accessible(s)!).toList()),
    ),
    surfaceRefraction: () =>
        highContrast ? null : ladder.settleRefraction(tier, recipe.refraction),
    // Cleared as well as set: a subtree of another style keeps none of the
    // app style's cloud or shade, and `copyWith` takes a getter that
    // returns null for exactly that. Both ride the backdrop pass, so a tier
    // that goes without the pass goes without them.
    surfaceFrost: () =>
        highContrast ||
            base.reduceTransparency ||
            ladder.withholds(tier, CoreQualityEffect.backdropPass)
        ? null
        : recipe.frost?.atBrightness(base.coreBrightness),
    surfaceBodyShade: () {
      final shade = recipe.bodyShade?.atBrightness(base.coreBrightness);
      if (highContrast ||
          base.reduceTransparency ||
          ladder.withholds(tier, CoreQualityEffect.backdropPass) ||
          shade == null ||
          shade.strength <= 0) {
        return null;
      }

      return shade;
    },
    overlayMorph: () => recipe.overlayMorph,
  );
}
