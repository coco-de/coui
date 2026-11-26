/// Font weight primitive tokens.
///
/// Flutter: `CoreFontWeight.semiBold` → 600 (int, const).
/// Web: `CoreFontWeight.scale.semibold` → 'semibold' (Tailwind 키).
abstract final class CoreFontWeight {
  const CoreFontWeight._();

  // === Values (int — CSS font-weight) ===

  /// Thin (100).
  static const thin = 100;

  /// Extra-light (200).
  static const extraLight = 200;

  /// Light (300).
  static const light = 300;

  /// Regular/Normal (400).
  static const regular = 400;

  /// Medium (500).
  static const medium = 500;

  /// Semi-bold (600).
  static const semiBold = 600;

  /// Bold (700).
  static const bold = 700;

  /// Extra-bold (800).
  static const extraBold = 800;

  /// Black (900).
  static const black = 900;

  // === Scale Names (String — Tailwind 키) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String black,
    String bold,
    String extrabold,
    String extralight,
    String light,
    String medium,
    String regular,
    String semibold,
    String thin,
  })
  scale = (
    thin: 'thin',
    extralight: 'extralight',
    light: 'light',
    regular: 'regular',
    medium: 'medium',
    semibold: 'semibold',
    bold: 'bold',
    extrabold: 'extrabold',
    black: 'black',
  );
}
