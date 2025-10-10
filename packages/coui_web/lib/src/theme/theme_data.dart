/// Main theme data for web applications.
library;

import 'brightness.dart';
import 'color_scheme.dart';
import 'radius_scale.dart';
import 'spacing_scale.dart';
import 'typography_scale.dart';

/// Theme data configuration.
class ThemeData {
  /// Creates a theme data.
  const ThemeData({
    required this.colorScheme,
    required this.typography,
    required this.spacing,
    required this.radius,
    this.textScaling = 1.0,
    this.sizeScaling = 1.0,
    this.radiusScaling = 1.0,
  });

  /// Color scheme.
  final ColorScheme colorScheme;

  /// Typography scale.
  final TypographyScale typography;

  /// Spacing scale.
  final SpacingScale spacing;

  /// Radius scale.
  final RadiusScale radius;

  /// Text scaling factor.
  final double textScaling;

  /// Size scaling factor.
  final double sizeScaling;

  /// Radius scaling factor.
  final double radiusScaling;

  /// Brightness mode.
  Brightness get brightness => colorScheme.brightness;

  /// Default light theme with Material Design 3.
  static final lightMaterial = ThemeData(
    colorScheme: ColorScheme.light,
    typography: TypographyScale.material3,
    spacing: SpacingScale.material3,
    radius: RadiusScale.material3,
  );

  /// Default dark theme with Material Design 3.
  static final darkMaterial = ThemeData(
    colorScheme: ColorScheme.dark,
    typography: TypographyScale.material3,
    spacing: SpacingScale.material3,
    radius: RadiusScale.material3,
  );

  /// Light theme with coui style.
  static final lightCoui = ThemeData(
    colorScheme: ColorScheme.light,
    typography: TypographyScale.coui,
    spacing: SpacingScale.coui,
    radius: RadiusScale.coui,
  );

  /// Dark theme with coui style.
  static final darkCoui = ThemeData(
    colorScheme: ColorScheme.dark,
    typography: TypographyScale.coui,
    spacing: SpacingScale.coui,
    radius: RadiusScale.coui,
  );

  /// Creates a copy with optional changes.
  // Standard copyWith pattern requires all optional parameters
  // ignore: avoid-long-parameter-list
  ThemeData copyWith({
    ColorScheme? colorScheme,
    TypographyScale? typography,
    SpacingScale? spacing,
    RadiusScale? radius,
    double? textScaling,
    double? sizeScaling,
    double? radiusScaling,
  }) {
    return ThemeData(
      colorScheme: colorScheme ?? this.colorScheme,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      textScaling: textScaling ?? this.textScaling,
      sizeScaling: sizeScaling ?? this.sizeScaling,
      radiusScaling: radiusScaling ?? this.radiusScaling,
    );
  }

  /// Applies scaling to the theme.
  ThemeData scale({
    double? textScaling,
    double? sizeScaling,
    double? radiusScaling,
  }) {
    final textScale = textScaling ?? this.textScaling;
    final sizeScale = sizeScaling ?? this.sizeScaling;
    final radiusScale = radiusScaling ?? this.radiusScaling;

    return ThemeData(
      colorScheme: colorScheme,
      typography: typography.scale(textScale),
      spacing: spacing.scale(sizeScale),
      radius: radius.scale(radiusScale),
      textScaling: textScale,
      sizeScaling: sizeScale,
      radiusScaling: radiusScale,
    );
  }

  /// Converts to CSS variables.
  Map<String, String> toCssVariables() {
    return {
      ...colorScheme.toCssVariables(),
      ...typography.toCssVariables(),
      ...spacing.toCssVariables(),
      ...radius.toCssVariables(),
      '--text-scaling': textScaling.toString(),
      '--size-scaling': sizeScaling.toString(),
      '--radius-scaling': radiusScaling.toString(),
    };
  }

  /// Converts to DaisyUI theme configuration.
  Map<String, String> toDaisyUITheme() {
    return colorScheme.toDaisyUITheme();
  }
}
