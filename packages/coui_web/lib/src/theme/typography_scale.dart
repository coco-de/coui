/// Typography scale system supporting Material Design, DaisyUI, and shadcn.
///
/// Provides unified typography tokens that work across all design systems.
library;

/// Text style configuration.
class TextStyleConfig {
  /// Creates a text style configuration.
  const TextStyleConfig({
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    this.letterSpacing,
  });

  /// Font size in pixels.
  final double fontSize;

  /// Line height (relative to font size).
  final double lineHeight;

  /// Font weight (100-900).
  final int fontWeight;

  /// Letter spacing in em.
  final double? letterSpacing;

  /// Converts to CSS string.
  String toCss() {
    final props = <String>[];
    props.addAll([
      'font-size: ${fontSize}px',
      'line-height: $lineHeight',
      'font-weight: $fontWeight',
    ]);
    if (letterSpacing != null) {
      props.add('letter-spacing: ${letterSpacing}em');
    }

    return props.join('; ');
  }
}

/// Typography scale system.
class TypographyScale {
  /// Creates a typography scale.
  const TypographyScale({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  /// Display large (57px) - Material 3 / h1.
  final TextStyleConfig displayLarge;

  /// Display medium (45px) - Material 3 / h2.
  final TextStyleConfig displayMedium;

  /// Display small (36px) - Material 3 / h3.
  final TextStyleConfig displaySmall;

  /// Headline large (32px) - Material 3 / h4.
  final TextStyleConfig headlineLarge;

  /// Headline medium (28px) - Material 3 / h5.
  final TextStyleConfig headlineMedium;

  /// Headline small (24px) - Material 3 / h6.
  final TextStyleConfig headlineSmall;

  /// Title large (22px).
  final TextStyleConfig titleLarge;

  /// Title medium (16px).
  final TextStyleConfig titleMedium;

  /// Title small (14px).
  final TextStyleConfig titleSmall;

  /// Body large (16px).
  final TextStyleConfig bodyLarge;

  /// Body medium (14px).
  final TextStyleConfig bodyMedium;

  /// Body small (12px).
  final TextStyleConfig bodySmall;

  /// Label large (14px).
  final TextStyleConfig labelLarge;

  /// Label medium (12px).
  final TextStyleConfig labelMedium;

  /// Label small (11px).
  final TextStyleConfig labelSmall;

  /// Default Material Design 3 typography scale.
  static const material3 = TypographyScale(
    displayLarge: TextStyleConfig(
      fontSize: 57,
      lineHeight: 1.12,
      fontWeight: 400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyleConfig(
      fontSize: 45,
      lineHeight: 1.16,
      fontWeight: 400,
    ),
    displaySmall: TextStyleConfig(
      fontSize: 36,
      lineHeight: 1.22,
      fontWeight: 400,
    ),
    headlineLarge: TextStyleConfig(
      fontSize: 32,
      lineHeight: 1.25,
      fontWeight: 400,
    ),
    headlineMedium: TextStyleConfig(
      fontSize: 28,
      lineHeight: 1.29,
      fontWeight: 400,
    ),
    headlineSmall: TextStyleConfig(
      fontSize: 24,
      lineHeight: 1.33,
      fontWeight: 400,
    ),
    titleLarge: TextStyleConfig(
      fontSize: 22,
      lineHeight: 1.27,
      fontWeight: 500,
    ),
    titleMedium: TextStyleConfig(
      fontSize: 16,
      lineHeight: 1.5,
      fontWeight: 500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyleConfig(
      fontSize: 14,
      lineHeight: 1.43,
      fontWeight: 500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyleConfig(
      fontSize: 16,
      lineHeight: 1.5,
      fontWeight: 400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyleConfig(
      fontSize: 14,
      lineHeight: 1.43,
      fontWeight: 400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyleConfig(
      fontSize: 12,
      lineHeight: 1.33,
      fontWeight: 400,
      letterSpacing: 0.4,
    ),
    // ignore: no-equal-arguments - Material Design 3 intentionally uses same lineHeight for labelLarge and bodyMedium
    labelLarge: TextStyleConfig(
      fontSize: 14,
      lineHeight: 1.43,
      fontWeight: 500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyleConfig(
      fontSize: 12,
      lineHeight: 1.33,
      fontWeight: 500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyleConfig(
      fontSize: 11,
      lineHeight: 1.45,
      fontWeight: 500,
      letterSpacing: 0.5,
    ),
  );

  /// shadcn/ui typography scale.
  static const shadcn = TypographyScale(
    displayLarge: TextStyleConfig(
      fontSize: 72,
      lineHeight: 1,
      fontWeight: 800,
      letterSpacing: -0.02,
    ),
    displayMedium: TextStyleConfig(
      fontSize: 60,
      lineHeight: 1,
      fontWeight: 800,
      letterSpacing: -0.02,
    ),
    displaySmall: TextStyleConfig(
      fontSize: 48,
      lineHeight: 1,
      fontWeight: 800,
      letterSpacing: -0.02,
    ),
    headlineLarge: TextStyleConfig(
      fontSize: 36,
      lineHeight: 1.1,
      fontWeight: 700,
      letterSpacing: -0.02,
    ),
    headlineMedium: TextStyleConfig(
      fontSize: 30,
      lineHeight: 1.2,
      fontWeight: 600,
    ),
    headlineSmall: TextStyleConfig(
      fontSize: 24,
      lineHeight: 1.25,
      fontWeight: 600,
    ),
    titleLarge: TextStyleConfig(
      fontSize: 20,
      lineHeight: 1.4,
      fontWeight: 600,
    ),
    titleMedium: TextStyleConfig(
      fontSize: 18,
      lineHeight: 1.4,
      fontWeight: 600,
    ),
    titleSmall: TextStyleConfig(
      fontSize: 16,
      lineHeight: 1.5,
      fontWeight: 600,
    ),
    bodyLarge: TextStyleConfig(
      fontSize: 16,
      lineHeight: 1.75,
      fontWeight: 400,
    ),
    bodyMedium: TextStyleConfig(
      fontSize: 14,
      lineHeight: 1.5,
      fontWeight: 400,
    ),
    bodySmall: TextStyleConfig(
      fontSize: 13,
      lineHeight: 1.5,
      fontWeight: 400,
    ),
    labelLarge: TextStyleConfig(
      fontSize: 14,
      lineHeight: 1.5,
      fontWeight: 500,
    ),
    labelMedium: TextStyleConfig(
      fontSize: 12,
      lineHeight: 1.5,
      fontWeight: 500,
    ),
    labelSmall: TextStyleConfig(
      fontSize: 11,
      lineHeight: 1.5,
      fontWeight: 500,
    ),
  );

  /// Scales typography by a factor.
  TypographyScale scale(double factor) {
    return TypographyScale(
      displayLarge: TextStyleConfig(
        fontSize: displayLarge.fontSize * factor,
        lineHeight: displayLarge.lineHeight,
        fontWeight: displayLarge.fontWeight,
        letterSpacing: displayLarge.letterSpacing,
      ),
      displayMedium: TextStyleConfig(
        fontSize: displayMedium.fontSize * factor,
        lineHeight: displayMedium.lineHeight,
        fontWeight: displayMedium.fontWeight,
        letterSpacing: displayMedium.letterSpacing,
      ),
      displaySmall: TextStyleConfig(
        fontSize: displaySmall.fontSize * factor,
        lineHeight: displaySmall.lineHeight,
        fontWeight: displaySmall.fontWeight,
        letterSpacing: displaySmall.letterSpacing,
      ),
      headlineLarge: TextStyleConfig(
        fontSize: headlineLarge.fontSize * factor,
        lineHeight: headlineLarge.lineHeight,
        fontWeight: headlineLarge.fontWeight,
        letterSpacing: headlineLarge.letterSpacing,
      ),
      headlineMedium: TextStyleConfig(
        fontSize: headlineMedium.fontSize * factor,
        lineHeight: headlineMedium.lineHeight,
        fontWeight: headlineMedium.fontWeight,
        letterSpacing: headlineMedium.letterSpacing,
      ),
      headlineSmall: TextStyleConfig(
        fontSize: headlineSmall.fontSize * factor,
        lineHeight: headlineSmall.lineHeight,
        fontWeight: headlineSmall.fontWeight,
        letterSpacing: headlineSmall.letterSpacing,
      ),
      titleLarge: TextStyleConfig(
        fontSize: titleLarge.fontSize * factor,
        lineHeight: titleLarge.lineHeight,
        fontWeight: titleLarge.fontWeight,
        letterSpacing: titleLarge.letterSpacing,
      ),
      titleMedium: TextStyleConfig(
        fontSize: titleMedium.fontSize * factor,
        lineHeight: titleMedium.lineHeight,
        fontWeight: titleMedium.fontWeight,
        letterSpacing: titleMedium.letterSpacing,
      ),
      titleSmall: TextStyleConfig(
        fontSize: titleSmall.fontSize * factor,
        lineHeight: titleSmall.lineHeight,
        fontWeight: titleSmall.fontWeight,
        letterSpacing: titleSmall.letterSpacing,
      ),
      bodyLarge: TextStyleConfig(
        fontSize: bodyLarge.fontSize * factor,
        lineHeight: bodyLarge.lineHeight,
        fontWeight: bodyLarge.fontWeight,
        letterSpacing: bodyLarge.letterSpacing,
      ),
      bodyMedium: TextStyleConfig(
        fontSize: bodyMedium.fontSize * factor,
        lineHeight: bodyMedium.lineHeight,
        fontWeight: bodyMedium.fontWeight,
        letterSpacing: bodyMedium.letterSpacing,
      ),
      bodySmall: TextStyleConfig(
        fontSize: bodySmall.fontSize * factor,
        lineHeight: bodySmall.lineHeight,
        fontWeight: bodySmall.fontWeight,
        letterSpacing: bodySmall.letterSpacing,
      ),
      labelLarge: TextStyleConfig(
        fontSize: labelLarge.fontSize * factor,
        lineHeight: labelLarge.lineHeight,
        fontWeight: labelLarge.fontWeight,
        letterSpacing: labelLarge.letterSpacing,
      ),
      labelMedium: TextStyleConfig(
        fontSize: labelMedium.fontSize * factor,
        lineHeight: labelMedium.lineHeight,
        fontWeight: labelMedium.fontWeight,
        letterSpacing: labelMedium.letterSpacing,
      ),
      labelSmall: TextStyleConfig(
        fontSize: labelSmall.fontSize * factor,
        lineHeight: labelSmall.lineHeight,
        fontWeight: labelSmall.fontWeight,
        letterSpacing: labelSmall.letterSpacing,
      ),
    );
  }

  /// Converts to CSS variables.
  Map<String, String> toCssVariables() {
    return {
      '--text-display-large': displayLarge.toCss(),
      '--text-display-medium': displayMedium.toCss(),
      '--text-display-small': displaySmall.toCss(),
      '--text-headline-large': headlineLarge.toCss(),
      '--text-headline-medium': headlineMedium.toCss(),
      '--text-headline-small': headlineSmall.toCss(),
      '--text-title-large': titleLarge.toCss(),
      '--text-title-medium': titleMedium.toCss(),
      '--text-title-small': titleSmall.toCss(),
      '--text-body-large': bodyLarge.toCss(),
      '--text-body-medium': bodyMedium.toCss(),
      '--text-body-small': bodySmall.toCss(),
      '--text-label-large': labelLarge.toCss(),
      '--text-label-medium': labelMedium.toCss(),
      '--text-label-small': labelSmall.toCss(),
    };
  }
}
