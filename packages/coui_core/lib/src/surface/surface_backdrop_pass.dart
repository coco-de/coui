import 'package:coui_core/src/surface/surface_dissolve.dart';
import 'package:coui_core/src/surface/surface_frost.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:meta/meta.dart';

/// Everything one backdrop pass states, together: the blur, the chroma lift,
/// the dimming, the frost, the body shade and the bend.
///
/// A surface draws these as one pass — one thing laid over what is behind it,
/// not six effects that happen to be near each other — and a surface that is
/// fading in or out has to move all of them, by the same rule, or the glass
/// comes apart on the way (a bend with nothing blurred, a shade over a page no
/// panel covers). So the rule is stated once, over the whole: [dissolvedAt]
/// says what the pass draws at a progress of the fade, from nothing at 0 to
/// exactly the stated pass at 1. Which term follows which scale is
/// [CoreSurfaceDissolve]'s; this is where they are put together.
///
/// Platform-neutral on purpose: a seat that draws the pass reads the numbers
/// and decides nothing. Flutter builds its filters from them. The Web seat does
/// not read this value: a browser fades an element by the element's own
/// opacity, and the surface style guide says what that does to a glass panel.
@immutable
class CoreSurfaceBackdropPass {
  /// Creates the pass a surface states at rest.
  const CoreSurfaceBackdropPass({
    required this.blur,
    this.saturation,
    this.brightness,
    this.frost,
    this.refraction,
    this.bodyShade = 0,
  });

  /// The blur sigma, in logical pixels. Zero is no pass at all.
  final double blur;

  /// The chroma lift the pass applies, or null for none. `1` is the identity.
  final double? saturation;

  /// How far the pass dims what shows through, or null for none. `1` is the
  /// identity.
  final double? brightness;

  /// The cloud laid under the pass's own blur, or null for none.
  final CoreSurfaceFrost? frost;

  /// The bend at the rim and across the face, or null for none.
  final CoreSurfaceRefraction? refraction;

  /// How much of itself a white pixel loses under the pass, 0 to 1. Zero is
  /// no shade.
  final double bodyShade;

  /// This pass as it is drawn while its surface is [progress] of the way in or
  /// out of view.
  ///
  /// * the blur, the frost share, the body shade, and the bend's strength and
  ///   lens go from nothing to their stated value with
  ///   [CoreSurfaceDissolve.share] of the progress;
  /// * the chroma lift and the dimming go from the identity to their stated
  ///   value with it;
  /// * a term the pass does not state stays unstated — a surface with no
  ///   frost has none at any progress.
  ///
  /// Returns this very instance at a progress of 1, so a surface at rest
  /// builds the filters it always built.
  CoreSurfaceBackdropPass dissolvedAt(double progress) {
    if (progress >= 1) return this;
    final lift = saturation;
    final dim = brightness;

    return CoreSurfaceBackdropPass(
      blur: CoreSurfaceDissolve.scaled(blur, progress),
      saturation: lift == null
          ? null
          : CoreSurfaceDissolve.towardIdentity(lift, progress),
      brightness: dim == null
          ? null
          : CoreSurfaceDissolve.towardIdentity(dim, progress),
      frost: frost?.dissolvedAt(progress),
      refraction: refraction?.dissolvedAt(progress),
      bodyShade: CoreSurfaceDissolve.scaled(bodyShade, progress),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceBackdropPass &&
          blur == other.blur &&
          saturation == other.saturation &&
          brightness == other.brightness &&
          frost == other.frost &&
          refraction == other.refraction &&
          bodyShade == other.bodyShade;

  @override
  int get hashCode =>
      Object.hash(blur, saturation, brightness, frost, refraction, bodyShade);

  @override
  String toString() =>
      'CoreSurfaceBackdropPass(blur: $blur, saturation: $saturation, '
      'brightness: $brightness, frost: $frost, refraction: $refraction, '
      'bodyShade: $bodyShade)';
}
