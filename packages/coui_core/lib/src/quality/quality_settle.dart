import 'package:coui_core/src/quality/quality_tier.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:coui_core/src/surface/surface_token.dart';

/// What a [CoreQualityLadder] does to a material.
///
/// An extension in a file of its own, not part of the ladder's: the ladder is
/// data about tiers and effects, and the one place a recipe's refraction is
/// stated is the recipe (`surface_refraction_axis_boundary_test`). The ladder
/// never names the request; it removes the one it is handed.
extension CoreQualityLadderSettle on CoreQualityLadder {
  /// [material] as a surface at [tier] draws it: unchanged unless [tier]
  /// goes without the backdrop pass, and then without its transparency.
  ///
  /// Returns [material] itself when nothing changes, so a seat that settles
  /// every material it hands out costs nothing at the top rung and a theme
  /// that states no quality compares equal to what it was before.
  CoreSurfaceToken? settle(CoreQualityTier tier, CoreSurfaceToken? material) {
    if (material == null ||
        !material.usesTransparency ||
        !withholds(tier, CoreQualityEffect.backdropPass)) {
      return material;
    }

    return material.withoutTransparency();
  }

  /// [refraction] as a surface at [tier] draws it: null when [tier] goes
  /// without the bend.
  CoreSurfaceRefraction? settleRefraction(
    CoreQualityTier tier,
    CoreSurfaceRefraction? refraction,
  ) => withholds(tier, CoreQualityEffect.refraction) ? null : refraction;
}
