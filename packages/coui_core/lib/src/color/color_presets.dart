import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/coui_palette.dart';
import 'package:coui_core/src/color/coui_semantic_mapping.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/semantic_mapping_set.dart';

/// CoUI's own colours — the palette and the source every default seat
/// renders "the CoUI look" from.
///
/// [source] is what the theme presets, the unset-slot fallback of
/// `CoreColorScheme.resolved`, the Web default theme and the Figma export's
/// CoUI collection read. A project with its own brand builds a
/// `CoreSchemeSource` of its own — usually a [PrimitiveColors] palette
/// through `CoreSemanticMappingSet.standard.bind` — and passes that instead.
///
/// In this palette `primary` is neutral: CoUI is the base other products
/// build on, so its own call to action carries no hue — a near-black fill
/// in light mode, a near-white one in dark. `secondary` is neutral
/// emphasis, and `tertiary` — with the `CoreColors.accent` alias that reads
/// it — restates `primary`. The slot names are M3's, where `primary` is
/// where a brand hue goes; a brand theme does exactly that by overriding the
/// primary family.
abstract final class CouiColorPresets {
  /// CoUI's fixed primitive palette.
  ///
  /// Fixed hex rather than a generated scale: the steps are an OKLCH ladder
  /// the designer authored once (neutral at hue 255 and chroma 0.0025), and
  /// every ramp meets the legibility bars at the same step numbers — 600 is
  /// the body-text step (4.5:1 or more against white), 500 the UI-boundary
  /// step (3:1 or more). These values are the source of
  /// truth; the Figma variables are exported from them.
  static const CouiPalette palette = CouiPalette(
    neutral: CouiNeutralRamp(
      s50: CoreColor(0xFFF9FAFB),
      s100: CoreColor(0xFFF4F5F6),
      s150: CoreColor(0xFFEDEEF0),
      s200: CoreColor(0xFFE4E6E7),
      s300: CoreColor(0xFFD0D1D2),
      s400: CoreColor(0xFFB4B5B6),
      s500: CoreColor(0xFF939596),
      s600: CoreColor(0xFF737476),
      s700: CoreColor(0xFF58595A),
      s800: CoreColor(0xFF404143),
      s850: CoreColor(0xFF343536),
      s900: CoreColor(0xFF2A2B2C),
      s950: CoreColor(0xFF1F2021),
      s1000: CoreColor(0xFF161718),
      s1050: CoreColor(0xFF0F1011),
    ),
    success: CouiStatusRamp(
      s100: CoreColor(0xFFE9F8EB),
      s200: CoreColor(0xFFCDEAD2),
      s300: CoreColor(0xFFA8DAB1),
      s400: CoreColor(0xFF78C489),
      s500: CoreColor(0xFF3DA65C),
      s600: CoreColor(0xFF007F33),
      s700: CoreColor(0xFF006E2D),
      s800: CoreColor(0xFF005521),
      s900: CoreColor(0xFF003D17),
      s950: CoreColor(0xFF1D2F21),
      s1000: CoreColor(0xFF00270C),
    ),
    info: CouiStatusRamp(
      s100: CoreColor(0xFFE9F6FF),
      s200: CoreColor(0xFFCDE7FF),
      s300: CoreColor(0xFFA7D1FF),
      s400: CoreColor(0xFF77B8FF),
      s500: CoreColor(0xFF3F94F5),
      s600: CoreColor(0xFF006ED1),
      s700: CoreColor(0xFF005EB2),
      s800: CoreColor(0xFF00488D),
      s900: CoreColor(0xFF033567),
      s950: CoreColor(0xFF1D2B3D),
      s1000: CoreColor(0xFF012144),
    ),
    warning: CouiStatusRamp(
      s100: CoreColor(0xFFF7F4E5),
      s200: CoreColor(0xFFFFE18D),
      s300: CoreColor(0xFFFDC64D),
      s400: CoreColor(0xFFE9A91C),
      s500: CoreColor(0xFFC78500),
      s600: CoreColor(0xFF9B6200),
      s700: CoreColor(0xFF895100),
      s800: CoreColor(0xFF6F3C00),
      s900: CoreColor(0xFF552900),
      s950: CoreColor(0xFF38281A),
      s1000: CoreColor(0xFF3A1700),
    ),
    error: CouiStatusRamp(
      s100: CoreColor(0xFFFFF1EE),
      s200: CoreColor(0xFFFFDCD6),
      s300: CoreColor(0xFFFFBFB6),
      s400: CoreColor(0xFFFF978C),
      s500: CoreColor(0xFFFF594F),
      s600: CoreColor(0xFFD71E22),
      s700: CoreColor(0xFFB81C1E),
      s800: CoreColor(0xFF921416),
      s900: CoreColor(0xFF6B0E0F),
      s950: CoreColor(0xFF41231F),
      s1000: CoreColor(0xFF470707),
    ),
    white: CoreColor(0xFFFFFFFF),
    black: CoreColor(0xFF000000),
  );

  /// [palette] read through `CouiSemanticMapping` — the input of every
  /// default CoUI seat.
  static const CouiSchemeSource source = CouiSchemeSource(palette);

  /// The generated palette CoUI rendered from before its fixed palette.
  ///
  /// Kept, value unchanged, for the deprecation window so a project pinned
  /// to the old look can still reproduce it (with [defaultMapping]).
  @Deprecated(
    'CoUI primitives are fixed hex now — read CouiColorPresets.palette or '
    'CouiColorPresets.source (since 0.154). This is the retired generated '
    'palette; its values are unchanged so the old look stays reproducible.',
  )
  static final defaultPalette = PrimitiveColors.generate(
    primaryHSL: (h: 220.0, s: 0.65, l: 0.535),
    secondaryHSL: (h: 260.0, s: 0.60, l: 0.50),
    tertiaryHSL: (h: 272.0, s: 0.75, l: 0.46),
    successHSL: (h: 140.0, s: 0.70, l: 0.30),
    infoHSL: (h: 200.0, s: 0.75, l: 0.38),
    warningHSL: (h: 45.0, s: 0.85, l: 0.50),
    errorHSL: (h: 0.0, s: 0.75, l: 0.50),
    neutralHue: 220,
  );

  /// The mapping CoUI read [defaultPalette] through before its fixed
  /// palette — primary/secondary slot families on the neutral scale.
  @Deprecated(
    'Read CouiColorPresets.source (since 0.154) — CoUI reads its fixed '
    'palette through CouiSemanticMapping now; this is the retired '
    'monochrome reading of the generated palette.',
  )
  static const CoreSemanticMappingSet defaultMapping =
      CoreSemanticMappingSet.monochrome;
}
