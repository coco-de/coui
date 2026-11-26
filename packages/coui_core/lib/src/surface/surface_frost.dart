import 'package:coui_core/src/surface/surface_dissolve.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// The cloud a frosted glass lays over the content behind it: a second,
/// much heavier blur of the backdrop, composited into the body at an
/// opacity.
///
/// ## What it is that the surface's own blur is not
///
/// The surface's blur (`CoreSurfaceToken.blurRadius`) is the glass losing
/// focus: the content behind it is the same content, softened. (Elsewhere in
/// this kit the word "frost" is used loosely for that blur; in this type it
/// means only the second thing.) A frost is laid over that — a blur far wider
/// than the first, so wide that nothing in it is recognisable — and what the
/// eye reads is the two together: a pale, shapeless cloud with a faint copy of
/// the content still showing through it. Text under such a surface reads as
/// ghosts rather than as out-of-focus text.
///
/// The share between the two is [opacity]. At `1` the cloud replaces the
/// content and the surface's own blur is invisible; below it the backdrop
/// keeps `1 − opacity` of its contrast against the cloud.
///
/// ```text
/// body     = material( opacity · cloud + (1 − opacity) · backdrop )
/// cloud    = the backdrop blurred by [sigma]
/// material = the surface's own blur, chroma lift and dimming
/// ```
/// Per channel, 0–1.
///
/// The cloud is laid over the backdrop first and the material then acts on
/// the mix, on both seats: Flutter draws the cloud as a second backdrop pass
/// under the material's, the Web as a filter at the head of the same
/// `backdrop-filter` list. [mix] is the part in the parentheses, and the one
/// both are tested against; neither is allowed to disagree about what the
/// mix of the two is. (The material's steps are affine on an opaque backdrop
/// short of clamping, so a pixel read after them compares with [mix] of the
/// pixels read after them.)
///
/// ## What it costs
///
/// **One extra backdrop pass per surface that draws it.** That is the whole
/// reason it is opt-in and the whole reason it is a named term rather than a
/// bigger blur radius: a surface cannot state "a copy of the content shows
/// through at 27%" with one blur. Nothing is measured here about what that
/// costs on a given device; an app that turns it on for every surface on a
/// screen pays for every one of them. A surface nested in another draws no
/// backdrop pass of its own (see `CoreSurfaceRecipe.nestedSurfaces`), so it
/// draws no frost either.
///
/// Dropped, like every term that rides the backdrop pass, by the
/// reduce-transparency fallback, and — because a cloud is decoration over
/// content a user has asked to see more plainly — by high contrast and
/// forced colours.
///
/// ## Why the opacity is per mode
///
/// Same reason the fill is a pair (`CoreSurfaceOpacity`): a cloud that
/// reads right over a light page washes a dark one out or buries it. The
/// dark opacity is a deviation rather than a second required number, for
/// the reason `CoreSurfaceToken.saturationInDarkMode` gives: one value has
/// always been right for both modes until a material says otherwise.
///
/// ## What is deliberately not here
///
/// A tonal clamp and a luminance weight on the cloud (the native material
/// leans the cloud lighter over bright content and darker over dark). Both
/// act on the backdrop through its own luminance *before* it is averaged: the
/// weight is a weighted mean, which blurs the weighted colour and the weight
/// separately and divides one by the other. The Web has a proven handle for a
/// *point* operation on luminance (`CoreSurfaceBodyShade`), but a weighted
/// mean also needs that division, and the filter primitives offer none except
/// a table lookup over 8-bit intermediates, which was neither built nor
/// measured. An axis starts when both seats have a measured handle, so the
/// terms are left out rather than shipped on one seat.
@immutable
class CoreSurfaceFrost {
  /// Creates a frost.
  ///
  /// Both numbers are required: a frost with a blur and no opacity would
  /// have to invent one, and an invented opacity is a look decision hidden
  /// in a default.
  const CoreSurfaceFrost({
    required this.sigma,
    required this.opacity,
    this.opacityInDarkMode,
  }) : assert(
         sigma > 0 && sigma <= maxSigma,
         'The cloud is a Gaussian: zero is no blur, so there is no cloud, and '
         'past the cap it folds to a flat average and reads as a tinted '
         'panel rather than as a material.',
       ),
       assert(
         opacity > 0 && opacity <= 1,
         'The opacity is a share of the cloud over the copy. Zero is no '
         'frost at all (state none instead) and past one is more cloud than '
         'there is.',
       ),
       assert(
         opacityInDarkMode == null ||
             (opacityInDarkMode > 0 && opacityInDarkMode <= 1),
         'The dark share is bounded like the light one, for the same reason.',
       );

  /// The Gaussian sigma of the cloud, in logical pixels — the unit the
  /// surface's own blur is stated in.
  final double sigma;

  /// The share of the cloud over the lightly blurred copy, 0 to 1, for both
  /// modes unless [opacityInDarkMode] states one of its own.
  final double opacity;

  /// The share while the dark palette is active, or null for the same share
  /// as [opacity].
  final double? opacityInDarkMode;

  /// The widest cloud an app may ask for — the surface blur's own ceiling,
  /// `CoreSurfaceTuning.maxSurfaceBlur`.
  static const double maxSigma = 64;

  /// One channel of the body before the material acts: [cloud] laid over
  /// [copy] — the backdrop beneath it — at [opacity].
  ///
  /// All three in the same channel scale. The single statement of the mix, so
  /// a test on either seat compares its pixels with this and not with a copy
  /// of the arithmetic.
  static double mix({
    required double cloud,
    required double copy,
    required double opacity,
  }) => (opacity * cloud) + ((1 - opacity) * copy);

  /// The share this frost lays down while drawing in [brightness].
  double opacityFor(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark
      ? opacityInDarkMode ?? opacity
      : opacity;

  /// Whether the share is stated per mode, so a seat can skip asking which
  /// mode it is in when it is not.
  bool get statesByMode => opacityInDarkMode != null;

  /// This frost as it draws in [brightness]: the share collapsed into
  /// [opacity], with no per-mode statement left.
  ///
  /// Returns this very instance when nothing is stated per mode, so a seat
  /// that collapses every frost it hands out allocates nothing for the
  /// styles that never ask.
  CoreSurfaceFrost atBrightness(CoreBrightness brightness) {
    if (!statesByMode) return this;

    return CoreSurfaceFrost(
      sigma: sigma,
      opacity: opacityFor(brightness),
    );
  }

  /// This frost as it is drawn while its surface is [progress] of the way in
  /// or out of view: the share of the cloud goes from nothing to its stated
  /// value with [CoreSurfaceDissolve.share] of the progress, and the cloud's
  /// own [sigma] stays what it is.
  ///
  /// Only the share moves because the cloud is a statement about how heavy the
  /// haze is, and a haze that thinned by narrowing would sharpen its own
  /// edges on the way out. At a share of nothing there is no frost — the
  /// constructor refuses an opacity of zero for that reason — so the answer
  /// is null.
  ///
  /// Returns this very instance at a progress of 1.
  CoreSurfaceFrost? dissolvedAt(double progress) {
    if (progress >= 1) return this;
    final share = CoreSurfaceDissolve.share(progress);
    if (share <= 0) return null;

    return CoreSurfaceFrost(
      sigma: sigma,
      opacity: opacity * share,
      opacityInDarkMode: opacityInDarkMode == null
          ? null
          : opacityInDarkMode! * share,
    );
  }

  /// Creates a copy with the given fields replaced.
  ///
  /// A null [opacityInDarkMode] keeps the one this has — to clear a dark
  /// statement, build a new frost.
  CoreSurfaceFrost copyWith({
    double? sigma,
    double? opacity,
    double? opacityInDarkMode,
  }) => CoreSurfaceFrost(
    sigma: sigma ?? this.sigma,
    opacity: opacity ?? this.opacity,
    opacityInDarkMode: opacityInDarkMode ?? this.opacityInDarkMode,
  );

  /// Serializes this frost to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'sigma': sigma,
    'opacity': opacity,
    if (opacityInDarkMode != null) 'opacityInDarkMode': opacityInDarkMode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceFrost &&
          sigma == other.sigma &&
          opacity == other.opacity &&
          opacityInDarkMode == other.opacityInDarkMode;

  @override
  int get hashCode => Object.hash(sigma, opacity, opacityInDarkMode);

  @override
  String toString() =>
      'CoreSurfaceFrost(sigma: $sigma, opacity: $opacity'
      '${opacityInDarkMode == null ? '' : ', dark: $opacityInDarkMode'})';
}
