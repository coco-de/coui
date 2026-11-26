import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/surface/surface_geometry_constraint.dart';
import 'package:coui_core/src/surface/surface_token.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:coui_core/src/theme/design_system.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Unified theme data combining all design tokens.
///
/// Aggregates color scheme, typography, radius, motion, and surface
/// configuration into a single theme object that can be resolved by
/// a [DesignSystem] adapter.
@immutable
class CoreThemeData {
  /// Creates a [CoreThemeData] aggregating all design tokens.
  const CoreThemeData({
    required this.colorScheme,
    required this.brightness,
    required this.designSystem,
    this.typography = CoreTypography.coui,
    this.defaultSurface,
    this.geometry = const CoreSurfaceGeometryConstraint(),
    this.textScaling = 1.0,
    this.sizeScaling = 1.0,
    this.radiusScaling = 1.0,
    this.tapSoundEnabled = true,
  });

  /// The active color scheme.
  final CoreColorScheme colorScheme;

  /// Light or dark mode.
  final CoreBrightness brightness;

  /// The target design system.
  final DesignSystem designSystem;

  /// Typography scale.
  final CoreTypography typography;

  /// Default surface token.
  final CoreSurfaceToken? defaultSurface;

  /// Geometry constraint contributed by the active surface style.
  ///
  /// Identity unless a style states otherwise, so a theme that never opts
  /// in is unchanged. Resolvers read it where a Core geometry value becomes
  /// a Flutter one; components never read it themselves, which is what
  /// keeps a style from reaching only the components that remembered to
  /// support it.
  final CoreSurfaceGeometryConstraint geometry;

  /// Global text scaling factor.
  final double textScaling;

  /// Global component size scaling factor.
  final double sizeScaling;

  /// Global radius scaling factor.
  final double radiusScaling;

  /// Whether a tap plays the platform's click sound.
  ///
  /// True keeps the platform default, which is what an app that never
  /// states anything gets. An app that turns it off gets silence from
  /// every control at once — including the buttons CoUI builds for
  /// itself (a pagination page number, a calendar day), which a caller
  /// has no parameter to reach.
  ///
  /// Deliberately not named `enableFeedback`. That name is already taken
  /// on `Clickable` / `Button` for the *press chrome* gate — the shrink,
  /// the shift, the shadow that hides under a press. Reusing it would
  /// mean an app that wants silence also loses every press animation,
  /// which is a visual regression wearing an audio switch's name.
  ///
  /// The sound is the only platform feedback CoUI emits; there is no
  /// haptic call anywhere in the kit. Web has no equivalent capability,
  /// so this axis is Flutter-only by capability rather than by omission
  /// (`CoreClickableContract.enableFeedback` records the same asymmetry).
  final bool tapSoundEnabled;

  /// Creates a copy with modified values.
  CoreThemeData copyWith({
    CoreColorScheme? colorScheme,
    CoreBrightness? brightness,
    DesignSystem? designSystem,
    CoreTypography? typography,
    CoreSurfaceToken? defaultSurface,
    CoreSurfaceGeometryConstraint? geometry,
    double? textScaling,
    double? sizeScaling,
    double? radiusScaling,
    bool? tapSoundEnabled,
  }) {
    return CoreThemeData(
      colorScheme: colorScheme ?? this.colorScheme,
      brightness: brightness ?? this.brightness,
      designSystem: designSystem ?? this.designSystem,
      typography: typography ?? this.typography,
      defaultSurface: defaultSurface ?? this.defaultSurface,
      geometry: geometry ?? this.geometry,
      textScaling: textScaling ?? this.textScaling,
      sizeScaling: sizeScaling ?? this.sizeScaling,
      radiusScaling: radiusScaling ?? this.radiusScaling,
      tapSoundEnabled: tapSoundEnabled ?? this.tapSoundEnabled,
    );
  }

  /// Serializes the theme to a JSON-compatible map. [defaultSurface]
  /// serializes through its own `toJson` (omitted when null); the
  /// [typography] scale is intentionally not serialized.
  Map<String, dynamic> toJson() {
    return {
      'brightness': brightness.name,
      'designSystem': designSystem.name,
      'defaultSurface': defaultSurface?.toJson(),
      'textScaling': textScaling,
      'sizeScaling': sizeScaling,
      'radiusScaling': radiusScaling,
      'tapSoundEnabled': tapSoundEnabled,
      'colors': colorScheme.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreThemeData &&
          colorScheme == other.colorScheme &&
          brightness == other.brightness &&
          designSystem == other.designSystem &&
          typography == other.typography &&
          defaultSurface == other.defaultSurface &&
          geometry == other.geometry &&
          textScaling == other.textScaling &&
          sizeScaling == other.sizeScaling &&
          radiusScaling == other.radiusScaling &&
          tapSoundEnabled == other.tapSoundEnabled;

  @override
  int get hashCode => Object.hash(
    colorScheme,
    brightness,
    designSystem,
    typography,
    defaultSurface,
    geometry,
    textScaling,
    sizeScaling,
    radiusScaling,
    tapSoundEnabled,
  );
}
