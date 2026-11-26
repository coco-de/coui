import 'package:coui_core/src/surface/surface_dissolve.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// How far a bright backdrop is pulled down under the glass, stated by the
/// luminance of the backdrop itself.
///
/// ## What it is that the dimming is not
///
/// `CoreBackdropBrightness` multiplies the backdrop by one number, so a
/// black page and a white page lose the same *fraction*, and a mid-grey
/// loses it too. The darker material does not behave like that. Over
/// mid-grey and above it reads darker than the backdrop, and a white page
/// comes out well below white, while dark content is barely touched. That
/// asks for a term that knows how bright each pixel is — not a multiplier,
/// a function of the pixel.
///
/// ```text
/// out = in · (1 − strength · luma²)        (per pixel, channels 0–1)
/// luma = 0.213 R + 0.715 G + 0.072 B       (the weights the chroma lift uses)
/// ```
///
/// So white loses [strength] of itself, a mid-grey (`luma 0.5`) a quarter of
/// that, and black nothing. The square is a look decision: a linear
/// dependence on luma darkens the mid-tones as much as it darkens the page,
/// and the squared one leaves them alone until the content is genuinely
/// bright.
///
/// ## Where it sits
///
/// On the backdrop pass, after the surface's own blur, chroma lift and
/// dimming, before the fill goes over it. Flutter's fragment program applies
/// it to the pixel it has just read; the Web applies it with a filter in the
/// same `backdrop-filter` list. It is a *point* operation — it needs no
/// geometry — so it commutes with the rim's bend, and neither seat has to
/// order the two against each other.
///
/// ## Why it is opt-in and per mode
///
/// Nothing in the shipped styles pulls a bright backdrop down by its own
/// luminance, so every default is "none". It is stated per mode because the
/// darker material needs it and the lighter one does not: [strength] is the
/// light value (`0` for none) and [strengthInDarkMode] the dark one.
///
/// ## What it costs
///
/// On Flutter it rides the fragment program the rim's bend already runs, so
/// it adds a few arithmetic operations to a pass that exists, and a surface
/// that states a shade but no bend mounts that program anyway. On the Web it
/// is three filter primitives on a pass that exists. A surface nested in
/// another draws no backdrop pass and so no shade.
///
/// Dropped, like every term that rides the backdrop pass, by the
/// reduce-transparency fallback, and by high contrast and forced colours.
@immutable
class CoreSurfaceBodyShade {
  /// Creates a body shade.
  ///
  /// [strength] is the light value; `0` states none there, which is how a
  /// style shades only its dark mode.
  const CoreSurfaceBodyShade({required this.strength, this.strengthInDarkMode})
    : assert(
        strength >= 0 && strength <= maxStrength,
        'The shade is the share of itself that white loses. Negative would '
        'lighten the backdrop, and past one white goes below black.',
      ),
      assert(
        strengthInDarkMode == null ||
            (strengthInDarkMode >= 0 && strengthInDarkMode <= maxStrength),
        'The dark share is bounded like the light one, for the same reason.',
      );

  /// The share white loses, 0 to 1, in the light palette — and in the dark
  /// one unless [strengthInDarkMode] states one of its own.
  final double strength;

  /// The share white loses while the dark palette is active, or null for the
  /// same share as [strength].
  final double? strengthInDarkMode;

  /// The most an app may ask for: white goes all the way to black.
  static const double maxStrength = 1;

  /// The red weight of the luminance the shade is keyed on.
  ///
  /// Rec. 709, the weights `saturate()` and the Flutter chroma matrix use, so
  /// the kit has one idea of how bright a pixel is. The fragment program and
  /// the Web filter spell the same three numbers; a test pins both to these.
  static const double lumaRed = 0.213;

  /// The green weight of the luminance the shade is keyed on.
  static const double lumaGreen = 0.715;

  /// The blue weight of the luminance the shade is keyed on.
  static const double lumaBlue = 0.072;

  /// The luminance of a pixel, from channels in the 0–1 scale.
  static double lumaOf(double red, double green, double blue) =>
      (lumaRed * red) + (lumaGreen * green) + (lumaBlue * blue);

  /// The factor a pixel of luminance [luma] is multiplied by under a shade
  /// of [strength].
  static double factorAt({required double strength, required double luma}) =>
      1 - (strength * luma * luma);

  /// One pixel, shaded: channels in the 0–1 scale in and out.
  ///
  /// The single statement of the operation, so a test on either seat
  /// compares its pixels with this and not with a copy of the arithmetic.
  static ({double red, double green, double blue}) shade({
    required double strength,
    required double red,
    required double green,
    required double blue,
  }) {
    final factor = factorAt(
      strength: strength,
      luma: lumaOf(red, green, blue),
    );

    return (red: red * factor, green: green * factor, blue: blue * factor);
  }

  /// The share white loses while drawing in [brightness].
  double strengthFor(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark
      ? strengthInDarkMode ?? strength
      : strength;

  /// Whether the strength is stated per mode, so a seat can skip asking
  /// which mode it is in when it is not.
  bool get statesByMode => strengthInDarkMode != null;

  /// Whether this shade changes nothing in either mode.
  bool get isIdentity => strength == 0 && (strengthInDarkMode ?? 0) == 0;

  /// This shade as it draws in [brightness]: the strength collapsed into
  /// [strength], with no per-mode statement left.
  ///
  /// Returns this very instance when nothing is stated per mode.
  CoreSurfaceBodyShade atBrightness(CoreBrightness brightness) {
    if (!statesByMode) return this;

    return CoreSurfaceBodyShade(strength: strengthFor(brightness));
  }

  /// This shade as it is drawn while its surface is [progress] of the way in
  /// or out of view: the share white loses goes from nothing to its stated
  /// value with [CoreSurfaceDissolve.share] of the progress, in both modes.
  ///
  /// The shade acts on whatever the surface lets through, so a shade that
  /// stayed at full strength while the fill was fading out would darken a
  /// page that no panel is left over.
  ///
  /// Returns this very instance at a progress of 1.
  CoreSurfaceBodyShade dissolvedAt(double progress) => progress >= 1
      ? this
      : CoreSurfaceBodyShade(
          strength: CoreSurfaceDissolve.scaled(strength, progress),
          strengthInDarkMode: strengthInDarkMode == null
              ? null
              : CoreSurfaceDissolve.scaled(strengthInDarkMode!, progress),
        );

  /// Creates a copy with the given fields replaced.
  ///
  /// A null [strengthInDarkMode] keeps the one this has — to clear a dark
  /// statement, build a new shade.
  CoreSurfaceBodyShade copyWith({
    double? strength,
    double? strengthInDarkMode,
  }) => CoreSurfaceBodyShade(
    strength: strength ?? this.strength,
    strengthInDarkMode: strengthInDarkMode ?? this.strengthInDarkMode,
  );

  /// Serializes this shade to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'strength': strength,
    if (strengthInDarkMode != null) 'strengthInDarkMode': strengthInDarkMode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceBodyShade &&
          strength == other.strength &&
          strengthInDarkMode == other.strengthInDarkMode;

  @override
  int get hashCode => Object.hash(strength, strengthInDarkMode);

  @override
  String toString() =>
      'CoreSurfaceBodyShade(strength: $strength'
      '${strengthInDarkMode == null ? '' : ', dark: $strengthInDarkMode'})';
}
