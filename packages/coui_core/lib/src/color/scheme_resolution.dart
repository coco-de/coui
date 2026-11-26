import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/color/semantic_mapping_set.dart';
import 'package:coui_core/src/size/density.dart';
import 'package:coui_core/src/surface/surface_geometry_constraint.dart';
import 'package:coui_core/src/surface/surface_recipe.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/surface/surface_tuning.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Resolves an app's colour source into the scheme every component will
/// read, with all theme axes applied in one place.
///
/// This is the seat. Every axis that can change a colour lands here and
/// nowhere else — not in a component theme slot, not in a per-style bundle,
/// not as an extra level in a merge chain. The reason is that axes overlap:
/// a surface style has opinions about accent colour and so does high
/// contrast, and if they were applied in different layers then which one won
/// on a shared slot would depend on the order the two features happened to
/// be built in. Here the order is four lines of one function, so it can be
/// read, reviewed, and tested.
///
/// The order encodes one rule: **a result the user asked for beats a look
/// the app chose.** A surface style is decoration the app picked; high
/// contrast is a request from someone who could not otherwise read the
/// screen. So the style bends the palette first and high contrast gets the
/// last word on the slots it governs.
///
/// [source] is the palette already bound to the mapping that reads it —
/// `CouiColorPresets.source` for the CoUI look, a brand's
/// `CoreSemanticMappingSet.bind` otherwise.
///
/// Components never see any of this. They read the scheme that comes out.
CoreColorScheme resolveThemeSchemeFrom(
  CoreSchemeSource source, {
  required CoreBrightness brightness,
  bool highContrast = false,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreSurfaceTuning surfaceTuning = .none,
}) {
  final base = brightness == .dark ? source.dark() : source.light();

  // Decoration: the app's chosen surface style bends its own palette.
  //
  // The page tint is dropped outright under high contrast rather than
  // applied and then partly overridden. `raiseContrast` governs the slots
  // it knows about, and the page is not reliably one of them — so applying
  // the tint first left it standing on exactly the setting where an app's
  // chosen cast should yield. The Flutter theme fold already skips the
  // whole colour statement there; letting the two seats disagree is the
  // "which one wins depends on implementation order" failure this file
  // exists to prevent.
  final recipe = resolveThemeRecipe(
    surfaceStyle: surfaceStyle,
    surfaceTuning: surfaceTuning,
  );
  final constraint = highContrast
      ? recipe.colorConstraint.copyWith(stageTintChroma: 0)
      : recipe.colorConstraint;
  final styled = constraint.apply(base);

  // Accessibility: overrides the slots it governs, whatever the style did.
  // The raise is the SOURCE's raise — each mapping knows which of its slots
  // high contrast restates (CoUI's lays only the slots its high-contrast
  // table changes; the standard one re-states its accent families on the
  // darkest/lightest steps), so a raise from another mapping would
  // re-introduce values this one never had.
  return highContrast ? source.raiseContrast(styled, brightness) : styled;
}

/// [resolveThemeSchemeFrom] for a brand's generated [palette], read through
/// [mapping].
///
/// A palette alone cannot say what `primary` MEANS (a brand can keep
/// chromatic ramps but resolve the primary family to neutrals), so the pair
/// travels together — a caller passing a brand's palette passes that
/// brand's mapping with it.
CoreColorScheme resolveThemeScheme(
  PrimitiveColors palette, {
  required CoreBrightness brightness,
  bool highContrast = false,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreSurfaceTuning surfaceTuning = .none,
  CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
}) => resolveThemeSchemeFrom(
  mapping.bind(palette),
  brightness: brightness,
  highContrast: highContrast,
  surfaceStyle: surfaceStyle,
  surfaceTuning: surfaceTuning,
);

/// Resolves the geometry constraint every component will be measured
/// against, for the same reason and at the same place as the scheme above.
///
/// It is the *named seat* for every axis that bends geometry: the surface
/// style, the [density] and the [brightness] meet here, rather than each
/// being applied wherever its author happened to be working — the way two
/// geometry axes already went wrong, declared, wired through equality, and
/// read by nothing. The orders they apply in are stated once, on the value
/// this returns: density first, then the style, for a corner
/// (`CoreSurfaceGeometryConstraint.radius`); the style's opacity first,
/// then the brightness's strength, for a shadow
/// (`CoreSurfaceGeometryConstraint.shadow`).
///
/// [brightness] moves nothing but shadow alpha. It defaults to light, which
/// leaves every value as the style states it.
CoreSurfaceGeometryConstraint resolveThemeGeometry({
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreSurfaceTuning surfaceTuning = .none,
  CoreDensity density = .defaultDensity,
  CoreBrightness brightness = .light,
}) => resolveThemeRecipe(
  surfaceStyle: surfaceStyle,
  surfaceTuning: surfaceTuning,
).geometry.atDensity(density).atBrightness(brightness);

/// Which recipe is actually active, once the app has had its say.
///
/// The named seat for the *style* axis, in the same sense the two above are
/// the seats for colour and geometry: one place answers "what is this style,
/// here, now", and everything downstream reads the answer instead of
/// re-deriving it.
///
/// It exists because tuning has two consumers with different shapes. Flutter
/// folds the recipe into a `ThemeData`; Web needs the whole recipe to emit
/// its per-style CSS — the colour block, the geometry block, the surface
/// treatment, the forced-colours fallback. If each did its own
/// `of(id)`-then-tune, the two would be free to drift in what they applied
/// or in what order, and the drift would show up as one platform rendering a
/// tuning the other ignored.
///
/// An untuned app gets the preset instance itself back, not a copy of it.
CoreSurfaceRecipe resolveThemeRecipe({
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreSurfaceTuning surfaceTuning = .none,
}) => surfaceTuning.applyTo(CoreSurfaceRecipe.of(surfaceStyle));
