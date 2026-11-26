/// What the per-element surface runtime reads from the stylesheet.
///
/// The runtime that bakes a surface's displacement map and writes its rim's
/// sweep works from the *preset's* recipe — it is client code and cannot see
/// `ThemeConfig.surfaceTunings`, which is a build-time decision. What a
/// tuning changes about those two things therefore arrives the way every
/// tuned value reaches the browser: as numbers in the stylesheet, which the
/// runtime reads back off the surface it is about to measure (the sheet
/// states them, and only where they differ from the preset).
///
/// Kept apart from the DOM code so the part that decides what those numbers
/// mean is plain Dart a test can run: the browser half is one
/// `getPropertyValue` per name.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/web_constants.dart';

/// The stylesheet's statements about one surface, each null when it states
/// nothing and the preset's answer stands.
class SurfaceRuntimeInputs {
  /// Creates inputs from already-parsed values.
  const SurfaceRuntimeInputs({
    this.rimAngle,
    this.rimAngleInDarkMode,
    this.refractionModel,
  });

  /// Reads the inputs off a surface through [property], which returns the
  /// computed value of a custom property by name (the empty string for one
  /// the surface does not have, as `getPropertyValue` does).
  factory SurfaceRuntimeInputs.read(String Function(String name) property) =>
      SurfaceRuntimeInputs(
        rimAngle: double.tryParse(property(kWebSurfaceRimAngleVar).trim()),
        rimAngleInDarkMode: double.tryParse(
          property(kWebSurfaceRimAngleDarkVar).trim(),
        ),
        refractionModel: _modelNamed(
          property(kWebSurfaceRefractionModelVar).trim(),
        ),
      );

  /// The direction the rim is lit from in the light palette, in degrees.
  final double? rimAngle;

  /// The direction the rim is lit from in the dark palette, in degrees.
  final double? rimAngleInDarkMode;

  /// The law the rim bends light by.
  final CoreRefractionModel? refractionModel;

  /// Whether the stylesheet states nothing, so the preset is the answer.
  bool get isEmpty =>
      rimAngle == null && rimAngleInDarkMode == null && refractionModel == null;

  /// The rim to sweep, once for each palette: the light one, and the dark one
  /// only when it is lit from another direction.
  ///
  /// The runtime cannot re-measure when the mode changes — a theme switch
  /// writes a document attribute and rebuilds nothing — so it writes both
  /// sweeps once and the stylesheet's dark rules choose. A dark sweep equal
  /// to the light one is not written: the dark rules fall back to the light
  /// one, which is the same light.
  ({CoreSurfaceEdgeBevel light, CoreSurfaceEdgeBevel? dark}) rimsFor(
    CoreSurfaceEdgeBevel authored,
  ) {
    final light = rimAngle ?? authored.lightAngleFor(CoreBrightness.light);
    final dark =
        rimAngleInDarkMode ?? authored.lightAngleFor(CoreBrightness.dark);

    return (
      light: authored.relit(angle: light),
      dark: dark == light ? null : authored.relit(angle: dark),
    );
  }

  /// The request to bend by: the preset's, under the law the stylesheet
  /// states if it states one.
  CoreSurfaceRefraction refractionFor(CoreSurfaceRefraction authored) {
    final model = refractionModel;

    return model == null ? authored : authored.copyWith(model: model);
  }
}

CoreRefractionModel? _modelNamed(String name) {
  for (final model in CoreRefractionModel.values) {
    if (model.name == name) return model;
  }

  return null;
}
