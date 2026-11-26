import 'package:coui_web/coui_web.dart';

/// A generated brand palette for tests of the brand path — a
/// [PrimitiveColors] palette handed to `ThemeConfig(palette, mapping: …)`.
///
/// It is a brand, not the CoUI look: `ThemeConfig.defaults()` renders from
/// `CouiColorPresets.source`. Seeded like the Core suite's brand fixture,
/// so the two packages measure the same colours when they test the same
/// path.
final PrimitiveColors kBrandFixturePalette = PrimitiveColors.generate(
  primaryHSL: (h: 220.0, s: 0.65, l: 0.535),
  secondaryHSL: (h: 260.0, s: 0.60, l: 0.50),
  tertiaryHSL: (h: 272.0, s: 0.75, l: 0.46),
  successHSL: (h: 140.0, s: 0.70, l: 0.30),
  infoHSL: (h: 200.0, s: 0.75, l: 0.38),
  warningHSL: (h: 45.0, s: 0.85, l: 0.50),
  errorHSL: (h: 0.0, s: 0.75, l: 0.50),
  neutralHue: 220,
);
