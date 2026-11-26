// The brands CoUI's Figma export knows about — `coui` (the library's own
// colours), `unibook` and `medibooks` (tenant brands). One list, read by
// `export_figma_tokens.dart` (which publishes the first as the library's
// `Semantic/ Color` collection and every other as a brand value table) and by
// the tests that pin each brand's values.
//
// `CoreBrandRegistry` is the same type an app uses to name its own tenant
// palettes; this registry is CoUI's own — which brands the *design system's*
// Figma ships — a separate, smaller list by design. An app's registry is not
// read from here.

import 'package:coui_core/coui_core.dart';

/// The brands this export ships to Figma, the library brand first.
///
/// The first entry is the library: its colours are the Figma library's
/// `Semantic/ Color · <name>` collection and its `color/<id>/…` primitives.
/// Every later entry is a brand that a consumer file applies as an extension
/// of that one collection — the export writes only the values that differ
/// from the library brand (`export_figma_tokens.dart`, `brands.json`), and
/// the plugin writes them into the extension's overrides. Adding a brand is
/// exactly one more entry in this list.
///
/// Only real brands belong here — no placeholder entries.
final kFigmaBrands = CoreBrandRegistry([
  // CoUI's fixed 67-colour palette read through its own semantic mapping —
  // the same source every CoUI default seat (theme presets, the Web
  // default theme) reads, so the library publishes exactly the look the
  // code renders.
  const CoreBrand.from(
    id: 'coui',
    displayName: 'CoUI',
    source: CouiColorPresets.source,
  ),
  // Unibook's real palette, stated by the designer in the Figma DS file and
  // synced back here (seeds recovered by matching `generate()` output to the
  // authored ramps byte-exactly). Identity roles are Unibook's own; the
  // neutral hue and all four status roles are deliberately the same as
  // CoUI's — the brand differs where it has an opinion and shares where it
  // does not.
  CoreBrand(
    id: 'unibook',
    displayName: 'Unibook',
    palette: PrimitiveColors.generate(
      // 남보라. 디자이너가 DS 파일 `01. Color` 의 Unibook 프레임에 적어둔
      // 램프(#DFE3FC … #3B53ED … #071150)를 그대로 재현하는 유일한 시드로,
      // 7단계 전부 byte-exact 로 일치한다. 이전 값(212, 1.0, 0.41)은 같은
      // 프레임의 스와치가 따르던 파랑이었고, 그 프레임에서 primary 만
      // 스와치와 적힌 색 코드가 어긋나 있었다 — 나머지 일곱 계열은 일치했다.
      primaryHSL: (h: 232.0, s: 0.83, l: 0.58),
      secondaryHSL: (h: 264.0, s: 0.60, l: 0.45),
      tertiaryHSL: (h: 312.0, s: 0.60, l: 0.42),
      successHSL: (h: 140.0, s: 0.70, l: 0.30),
      infoHSL: (h: 200.0, s: 0.75, l: 0.38),
      warningHSL: (h: 45.0, s: 0.85, l: 0.50),
      errorHSL: (h: 0.0, s: 0.75, l: 0.50),
      neutralHue: 220,
    ),
    mapping: _kUnibookMapping,
  ),
  // Medibooks — the designer put its ramps into the Figma DS file to be
  // lifted into code, so those hex values are the source. They are not a
  // `PrimitiveColors.generate` output (a search over hue / saturation /
  // lightness finds no seed that reproduces the neutral, primary, secondary,
  // tertiary or success ramp), so those five are stated colour by colour —
  // `_ExplicitPalette` — and the three status ramps that DO come out of the
  // shared CoUI seeds byte-exactly are generated, as they are for Unibook.
  // Its mapping is the standard one plus the statements the designer's
  // Semantic collection makes — see `_kMedibooksMapping`.
  CoreBrand(
    id: 'medibooks',
    displayName: 'Medibooks',
    palette: _medibooksPalette,
    mapping: _kMedibooksMapping,
  ),
  // 미라클 알람 — the designer states one brand colour, #F22A4B, and the
  // CoUI brand rule (`CoreBrandPalette`) builds the rest: the colour lands
  // on step 600 exactly, and the error ramp turns away from it. The rule
  // would put the ramp's 1000 on the light primary fill (4.45:1 against
  // white's 4.03:1); the designer chose white, so the brand states it.
  const CoreBrand.fromColor(
    id: 'miracle-alarm',
    displayName: '미라클 알람',
    color: CoreColor(0xFFF22A4B),
    onLightFill: CoreBrandOnFill.white,
  ),
]);

/// Unibook's mapping: the standard chromatic interpretation, with the
/// designer's statements from the Figma DS file synced back here — dark
/// keeps the SATURATED primary (`base`, not the usual `light` step) with a
/// plain white foreground, and the light-mode text slots sit on `base`
/// (Unibook's base clears 4.5:1 on the light surface — 5.8:1 measured —
/// where the standard mapping's hue-proof default has to stay at `darker`).
///
/// High contrast raises from Unibook's own light/dark (so the two doors
/// into HC — the four-builder form and the seat's raise — agree; the raise
/// overrides the primary family anyway, so the result matches the standard
/// HC set).
final _kUnibookMapping = CoreSemanticMappingSet(
  light: _unibookLight,
  dark: _unibookDark,
  highContrastLight: (c) => CoreSemanticMapping.raiseContrast(
    _unibookLight(c),
    c,
    CoreBrightness.light,
  ),
  highContrastDark: (c) => CoreSemanticMapping.raiseContrast(
    _unibookDark(c),
    c,
    CoreBrightness.dark,
  ),
  raiseContrast: CoreSemanticMapping.raiseContrast,
);

CoreColorScheme _unibookLight(PrimitiveColors c) =>
    CoreSemanticMapping.light(c).copyWith(
      // Unibook's page ground is pure #FFF, not the off-white the standard
      // mapping uses. Stated in the Figma DS file and synced back here —
      // only the light ground; dark is unchanged. High contrast follows
      // for free because `raiseContrast` does not restate `surface`.
      surface: c.neutral.pureWhite,
      primaryText: c.primary.base,
      primaryTextLarge: c.primary.base,
    );

CoreColorScheme _unibookDark(PrimitiveColors c) =>
    CoreSemanticMapping.dark(c).copyWith(
      primary: c.primary.base,
      onPrimary: c.neutral.white,
    );

// ─── Medibooks ──────────────────────────────────────────────────────────────

/// Medibooks' mapping: the standard chromatic interpretation, with the four
/// statements its Semantic collection in the Figma DS file makes where it
/// departs from the standard — the light page ground is pure white, the dark
/// primary keeps the SATURATED `base` (with a plain white foreground), and the
/// light-mode text slots sit on `dark` (`primaryText`) and `base`
/// (`primaryTextLarge`) where the standard keeps both at `darker`. It also
/// holds the selected face (`primaryContainer`) at the step it has always
/// drawn, where the standard mapping's gap contract would now move it.
///
/// Where the Figma collection and the standard mapping still differ after
/// these — `outline-subtle` in every mode, and `shadow` in the dark modes —
/// the collection was written by an older export that read those two slots
/// another way (a shadow colour that flipped to white in the dark modes), so
/// code's current rule decides: the standard one.
///
/// High contrast raises from Medibooks' own light/dark, as Unibook's does —
/// `raiseContrast` does not restate `surface`, so the pure-white ground
/// follows into HC.
final _kMedibooksMapping = CoreSemanticMappingSet(
  light: _medibooksLight,
  dark: _medibooksDark,
  highContrastLight: (c) => CoreSemanticMapping.raiseContrast(
    _medibooksLight(c),
    c,
    CoreBrightness.light,
  ),
  highContrastDark: (c) => CoreSemanticMapping.raiseContrast(
    _medibooksDark(c),
    c,
    CoreBrightness.dark,
  ),
  raiseContrast: CoreSemanticMapping.raiseContrast,
);

CoreColorScheme _medibooksLight(PrimitiveColors c) =>
    CoreSemanticMapping.light(c).copyWith(
      surface: c.neutral.pureWhite,
      // Stated so the selected face stays where Medibooks has always drawn
      // it (#DAF3E4). The standard mapping would move it a step darker —
      // 1.17:1 on the page is under `CorePrimaryContainerGap.minLight` — but
      // this face was never the designer's choice, only the generator's, and
      // the gap contract is not to change a shipped brand's screen. The
      // contract test lists the shortfall without failing on it.
      primaryContainer: c.primary.lightest,
      primaryText: c.primary.dark,
      primaryTextLarge: c.primary.base,
    );

CoreColorScheme _medibooksDark(PrimitiveColors c) =>
    CoreSemanticMapping.dark(c).copyWith(
      primary: c.primary.base,
      onPrimary: c.neutral.white,
      // As in light: today's face (#003520), stated so the standard
      // mapping's gap walk (1.26:1, under `CorePrimaryContainerGap.minDark`)
      // does not move it.
      primaryContainer: c.primary.darker,
    );

/// Medibooks' palette: five ramps stated as hex (the designer's, from the
/// Figma DS file), three generated from the seeds CoUI's own status roles use.
final PrimitiveColors _medibooksPalette = () {
  final status = PrimitiveColors.generate(
    primaryHSL: (h: 0, s: 0, l: 0),
    secondaryHSL: (h: 0, s: 0, l: 0),
    tertiaryHSL: (h: 0, s: 0, l: 0),
    successHSL: (h: 0, s: 0, l: 0),
    infoHSL: (h: 200.0, s: 0.75, l: 0.38),
    warningHSL: (h: 45.0, s: 0.85, l: 0.50),
    errorHSL: (h: 0.0, s: 0.75, l: 0.50),
    neutralHue: 0,
  );
  return _ExplicitPalette(
    neutral: const _ExplicitNeutral(
      pureWhite: CoreColor(0xFFFFFFFF),
      white: CoreColor(0xFFFDFCFC),
      whiteDark: CoreColor(0xFFF4F2F1),
      whiteDarker: CoreColor(0xFFE8E4E3),
      greyLightest: CoreColor(0xFFD9D4D3),
      greyLighter: CoreColor(0xFFC9C2C0),
      greyLight: CoreColor(0xFFB6ACAA),
      grey: CoreColor(0xFFA09592),
      greyDark: CoreColor(0xFF887A77),
      greyDarker: CoreColor(0xFF6D625F),
      greyDarkest: CoreColor(0xFF564B48),
      blackLighter: CoreColor(0xFF423633),
      blackLight: CoreColor(0xFF302522),
      black: CoreColor(0xFF231815),
      pureBlack: CoreColor(0xFF000000),
    ),
    primary: const _ExplicitChromatic(
      lightest: CoreColor(0xFFDAF3E4),
      lighter: CoreColor(0xFFC3EAD4),
      light: CoreColor(0xFF71D2A1),
      base: CoreColor(0xFF009260),
      dark: CoreColor(0xFF005435),
      darker: CoreColor(0xFF003520),
      darkest: CoreColor(0xFF002C1A),
    ),
    secondary: const _ExplicitChromatic(
      lightest: CoreColor(0xFFDAEEEF),
      lighter: CoreColor(0xFFBFE0E1),
      light: CoreColor(0xFF72B6B8),
      base: CoreColor(0xFF006265),
      dark: CoreColor(0xFF043F41),
      darker: CoreColor(0xFF082D2E),
      darkest: CoreColor(0xFF082728),
    ),
    tertiary: const _ExplicitChromatic(
      lightest: CoreColor(0xFFF4E4F8),
      lighter: CoreColor(0xFFEBD1F1),
      light: CoreColor(0xFFD198DE),
      base: CoreColor(0xFF8F3CA1),
      dark: CoreColor(0xFF582164),
      darker: CoreColor(0xFF3C1644),
      darkest: CoreColor(0xFF321339),
    ),
    success: const _ExplicitChromatic(
      lightest: CoreColor(0xFFDBF0DE),
      lighter: CoreColor(0xFFC2E3C7),
      light: CoreColor(0xFF76BB84),
      base: CoreColor(0xFF12682F),
      dark: CoreColor(0xFF0B431D),
      darker: CoreColor(0xFF0B2F15),
      darkest: CoreColor(0xFF0B2913),
    ),
    info: status.info,
    warning: status.warning,
    error: status.error,
  );
}();

/// A [NeutralScale] stated colour by colour.
///
/// `NeutralScale` has no public constructor besides the one that derives
/// every step from a hue, and a hand-authored ramp is not a function of a
/// hue — so this implements the interface instead. Everything that reads a
/// palette (`CoreSemanticMapping`, `PrimitiveCssGenerator`) reads these
/// fields.
final class _ExplicitNeutral implements NeutralScale {
  const _ExplicitNeutral({
    required this.pureWhite,
    required this.white,
    required this.whiteDark,
    required this.whiteDarker,
    required this.greyLightest,
    required this.greyLighter,
    required this.greyLight,
    required this.grey,
    required this.greyDark,
    required this.greyDarker,
    required this.greyDarkest,
    required this.blackLighter,
    required this.blackLight,
    required this.black,
    required this.pureBlack,
  });

  @override
  final CoreColor pureWhite;
  @override
  final CoreColor white;
  @override
  final CoreColor whiteDark;
  @override
  final CoreColor whiteDarker;
  @override
  final CoreColor greyLightest;
  @override
  final CoreColor greyLighter;
  @override
  final CoreColor greyLight;
  @override
  final CoreColor grey;
  @override
  final CoreColor greyDark;
  @override
  final CoreColor greyDarker;
  @override
  final CoreColor greyDarkest;
  @override
  final CoreColor blackLighter;
  @override
  final CoreColor blackLight;
  @override
  final CoreColor black;
  @override
  final CoreColor pureBlack;
}

/// A [ChromaticScale] stated colour by colour — see [_ExplicitNeutral].
final class _ExplicitChromatic implements ChromaticScale {
  const _ExplicitChromatic({
    required this.lightest,
    required this.lighter,
    required this.light,
    required this.base,
    required this.dark,
    required this.darker,
    required this.darkest,
  });

  @override
  final CoreColor lightest;
  @override
  final CoreColor lighter;
  @override
  final CoreColor light;
  @override
  final CoreColor base;
  @override
  final CoreColor dark;
  @override
  final CoreColor darker;
  @override
  final CoreColor darkest;
}

/// A [PrimitiveColors] palette assembled from scales that are already
/// stated — see [_ExplicitNeutral].
final class _ExplicitPalette implements PrimitiveColors {
  const _ExplicitPalette({
    required this.neutral,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
  });

  @override
  final NeutralScale neutral;
  @override
  final ChromaticScale primary;
  @override
  final ChromaticScale secondary;
  @override
  final ChromaticScale tertiary;
  @override
  final ChromaticScale success;
  @override
  final ChromaticScale info;
  @override
  final ChromaticScale warning;
  @override
  final ChromaticScale error;
}
