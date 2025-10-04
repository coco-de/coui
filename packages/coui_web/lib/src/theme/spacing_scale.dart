/// Spacing scale system.
library;

/// Spacing scale configuration.
class SpacingScale {
  /// Creates a spacing scale.
  const SpacingScale({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  /// Extra small spacing.
  final double xs;

  /// Small spacing.
  final double sm;

  /// Medium spacing.
  final double md;

  /// Large spacing.
  final double lg;

  /// Extra large spacing.
  final double xl;

  /// Extra extra large spacing.
  final double xxl;

  /// Material Design 3 spacing scale (4px base).
  static const material3 = SpacingScale(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  );

  /// shadcn spacing scale (4px base).
  static const shadcn = SpacingScale(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  );

  /// Scales spacing by a factor.
  SpacingScale scale(double factor) {
    return SpacingScale(
      xs: xs * factor,
      sm: sm * factor,
      md: md * factor,
      lg: lg * factor,
      xl: xl * factor,
      xxl: xxl * factor,
    );
  }

  /// Converts to CSS variables.
  Map<String, String> toCssVariables() {
    return {
      '--spacing-xs': '${xs}px',
      '--spacing-sm': '${sm}px',
      '--spacing-md': '${md}px',
      '--spacing-lg': '${lg}px',
      '--spacing-xl': '${xl}px',
      '--spacing-xxl': '${xxl}px',
    };
  }
}
