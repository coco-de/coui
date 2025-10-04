/// Radius scale system.
library;

/// Border radius scale configuration.
class RadiusScale {
  /// Creates a radius scale.
  const RadiusScale({
    required this.none,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.full,
  });

  /// No radius.
  final double none;

  /// Extra small radius.
  final double xs;

  /// Small radius.
  final double sm;

  /// Medium radius.
  final double md;

  /// Large radius.
  final double lg;

  /// Extra large radius.
  final double xl;

  /// Extra extra large radius.
  final double xxl;

  /// Full radius (circle).
  final double full;

  /// Material Design 3 radius scale.
  static const material3 = RadiusScale(
    none: 0,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 28,
    full: 9999,
  );

  /// shadcn radius scale.
  static const shadcn = RadiusScale(
    none: 0,
    xs: 2,
    sm: 4,
    md: 6,
    lg: 8,
    xl: 12,
    xxl: 16,
    full: 9999,
  );

  /// Scales radius by a factor.
  RadiusScale scale(double factor) {
    return RadiusScale(
      none: none,
      xs: xs * factor,
      sm: sm * factor,
      md: md * factor,
      lg: lg * factor,
      xl: xl * factor,
      xxl: xxl * factor,
      full: full,
    );
  }

  /// Converts to CSS variables.
  Map<String, String> toCssVariables() {
    return {
      '--radius-none': '${none}px',
      '--radius-xs': '${xs}px',
      '--radius-sm': '${sm}px',
      '--radius-md': '${md}px',
      '--radius-lg': '${lg}px',
      '--radius-xl': '${xl}px',
      '--radius-xxl': '${xxl}px',
      '--radius-full': '${full}px',
    };
  }
}
