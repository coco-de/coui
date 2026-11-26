import 'package:coui_core/coui_core.dart';

/// A generated brand palette for tests that exercise the brand path —
/// [PrimitiveColors] read through a [CoreSemanticMappingSet].
///
/// Seeded with the values CoUI itself generated its palette from before it
/// moved to the fixed `CouiPalette`, so tests that measured the standard
/// mapping on that palette keep measuring the same colours. It is a brand
/// fixture, not the CoUI look: CoUI renders from `CouiColorPresets.source`.
final kBrandFixturePalette = PrimitiveColors.generate(
  primaryHSL: (h: 220.0, s: 0.65, l: 0.535),
  secondaryHSL: (h: 260.0, s: 0.60, l: 0.50),
  tertiaryHSL: (h: 272.0, s: 0.75, l: 0.46),
  successHSL: (h: 140.0, s: 0.70, l: 0.30),
  infoHSL: (h: 200.0, s: 0.75, l: 0.38),
  warningHSL: (h: 45.0, s: 0.85, l: 0.50),
  errorHSL: (h: 0.0, s: 0.75, l: 0.50),
  neutralHue: 220,
);

/// [kBrandFixturePalette] read through the standard mapping.
final CorePrimitiveSchemeSource kBrandFixtureSource = CoreSemanticMappingSet
    .standard
    .bind(
      kBrandFixturePalette,
    );
