import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// How much of a surface's fill shows, stated once per mode.
///
/// ## Why this is a pair
///
/// The fill is a token that already resolves per mode — 252 in light and
/// 24 in dark for the surface family — but the *share* of it that covers
/// the backdrop used to be one number for both. That cannot be right for
/// both: what the fill has to do is keep text legible over whatever the
/// backdrop averages to, and the two modes need different amounts of it.
///
/// A panel's text sits on `fill·a + backdrop·(1−a)`. In dark the fill is
/// near-black, so every point of `a` taken from the backdrop is a point of
/// bright page that no longer reaches the text. That matters most for a
/// panel that inverts the polarity — a tooltip fills with `onSurface` and
/// writes in `surface` — where the thinner the fill, the closer its text
/// sits to the colour it is drawn on. In light the same share is already
/// enough, and thickening it there would spend the translucency the
/// material exists to show.
///
/// Same shape as `CoreBackdropBrightness`, for the same reason: a term the
/// two modes disagree about is stated as a pair and collapses to one number
/// only at the seat that folds the material into a theme. Neither renderer
/// sees this type — Flutter resolves it against the theme's mode at build
/// time, and Web restates the fill under both dark forms of the stylesheet.
///
/// ## Where it collapses to one number
///
/// Never in the token. A reader that wants a scalar asks for one mode:
/// [resolve] on Flutter (through the theme's brightness) and the two
/// restated CSS rules on Web. Reading [light] directly is how a dark
/// surface ends up drawn with the light fill, which is exactly the mistake
/// this type exists to make impossible to write by accident.
@immutable
class CoreSurfaceOpacity {
  /// States a different value per mode.
  const CoreSurfaceOpacity({required this.light, required this.dark});

  /// States one value for both modes.
  ///
  /// The honest shape for a material whose fill does not depend on the
  /// palette's polarity — and for an app that states a fill outright, which
  /// is a statement about both modes. It exists so that stating one value
  /// is a *choice* rather than the result of forgetting the second field.
  const CoreSurfaceOpacity.same(double value) : light = value, dark = value;

  /// A fill that covers the backdrop completely, in both modes.
  static const CoreSurfaceOpacity opaque = CoreSurfaceOpacity.same(
    CoreSurfaceOpacity.opaqueValue,
  );

  /// The opacity at which a fill hides everything behind it.
  static const double opaqueValue = 1;

  /// The fill share applied while the light palette is active.
  final double light;

  /// The fill share applied while the dark palette is active.
  final double dark;

  /// The single number a renderer gets, for the mode that is active.
  double resolve(CoreBrightness brightness) =>
      brightness == CoreBrightness.dark ? dark : light;

  /// Whether the fill hides the backdrop completely in both modes.
  ///
  /// False when *either* mode lets something through, because that is the
  /// question the reduce-transparency fallback and the "does this style
  /// state a material" check are asking: is there any translucency here
  /// for them to act on?
  bool get isOpaque => light >= opaqueValue && dark >= opaqueValue;

  /// Creates a copy with the given fields replaced.
  CoreSurfaceOpacity copyWith({double? light, double? dark}) =>
      CoreSurfaceOpacity(light: light ?? this.light, dark: dark ?? this.dark);

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'light': light, 'dark': dark};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceOpacity && light == other.light && dark == other.dark;

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => light == dark
      ? 'SurfaceOpacity.same($light)'
      : 'SurfaceOpacity(light: $light, dark: $dark)';
}
