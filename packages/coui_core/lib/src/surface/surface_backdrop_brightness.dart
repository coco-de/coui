import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// How much a surface dims what shows through it, stated once per mode.
///
/// ## Why this is a pair and the saturation is not
///
/// The blur and the edge band act on whatever is behind the surface without
/// caring which end of the palette that is, and the fill itself is a token
/// that already resolves per mode. Brightness cannot be stated once,
/// because it is a **multiply** and the direction that helps flips with
/// the mode — so the preset has to answer for both, and the type makes
/// stating one a choice (the fill's share, `CoreSurfaceOpacity`, is a pair
/// for the same reason).
///
/// The chroma lift and the angle of the edge light are the other two terms
/// a mode can disagree about, and neither is a pair: one number has always
/// been right for both, so each states a single value and lets a material
/// that wants its own in dark say so
/// (`CoreSurfaceToken.saturationInDarkMode`,
/// `CoreSurfaceEdgeBevel.lightAngleInDarkMode`).
///
/// A panel's text sits on `fill·a + backdrop·(1−a)`. In light the fill is
/// near-white and the text is dark, so the worst backdrop is a dark one
/// and lifting it *up* would help — except a multiply cannot lift a light
/// page that the chroma lift has already driven to 255, so upward is dead
/// where it would be useful. In dark the fill is near-black and the text
/// is light, so the worst backdrop is a bright one and pulling it *down*
/// helps a great deal. One number cannot be both.
///
/// That is measured, not argued. Sweeping the shipped fills (40% content,
/// 50% floating) over seven backdrops in both modes, the band of a single
/// mode-blind value that never lands below today is `[1.05, 1.40]` — and
/// it is hollow: `saturate(1.6)` preserves neutrals exactly, so a white
/// page is already clipped at 255 and every value in that band buys the
/// same ΔE 0.67, which is under the ~2.3 where a difference reads at a
/// glance. The direction with authority is downward, and downward is
/// exactly where the two modes disagree.
///
/// ## The separation this buys is proportional to the fill
///
/// For two roles differing only in alpha, the distance between their
/// composites is `(a₁ − a₂) · F · (1 − b)`. `F` is the surface token, 252
/// in light and 24 in dark, so the same `b` moves the dark pair roughly
/// ten times less far. A dark mode that wants the same perceptual gap has
/// to travel much further down — which it can afford, because down is
/// also the direction that helps its text.
///
/// ## Where it collapses to one number
///
/// At the seat that folds the material into a theme, and nowhere else.
/// Both platforms consume a scalar: Flutter bakes it into the backdrop
/// colour matrix at build time, and Web emits it into one
/// `backdrop-filter` list. Neither renderer knows this type exists, which
/// is what keeps the mode out of component code.
@immutable
class CoreBackdropBrightness {
  /// States a different value per mode.
  const CoreBackdropBrightness({required this.light, required this.dark});

  /// States one value for both modes.
  ///
  /// The honest shape for a material whose backdrop treatment genuinely
  /// does not depend on the palette's polarity. It exists so that stating
  /// one value is a *choice* rather than the result of forgetting the
  /// second field — a nullable dark term would have made the omission
  /// silent, and silence is how the identity value shipped for a term
  /// that was already known to need two.
  const CoreBackdropBrightness.same(double value) : light = value, dark = value;

  /// Leaves the backdrop exactly as it is, in both modes.
  static const CoreBackdropBrightness identity = CoreBackdropBrightness.same(
    CoreBackdropBrightness.identityValue,
  );

  /// The multiplier that changes nothing.
  static const double identityValue = 1;

  /// The multiplier applied while the light palette is active.
  final double light;

  /// The multiplier applied while the dark palette is active.
  final double dark;

  /// The single number a renderer gets, for the mode that is active.
  double resolve(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark ? dark : light;

  /// Whether this leaves the backdrop alone in both modes.
  ///
  /// Read by both platforms to skip the pass entirely: on Flutter an
  /// identity matrix is a second render pass that achieves nothing, and
  /// on Web an identity `brightness()` is a filter function that has to
  /// be parsed to do the same.
  bool get isIdentity => light == identityValue && dark == identityValue;

  /// Creates a copy with the given fields replaced.
  CoreBackdropBrightness copyWith({double? light, double? dark}) =>
      CoreBackdropBrightness(
        light: light ?? this.light,
        dark: dark ?? this.dark,
      );

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'light': light, 'dark': dark};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBackdropBrightness &&
          light == other.light &&
          dark == other.dark;

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => light == dark
      ? 'BackdropBrightness.same($light)'
      : 'BackdropBrightness(light: $light, dark: $dark)';
}
