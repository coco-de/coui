import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/core_color.dart';

// ──────────────────────────────────────────────────────────────────────────
// Neutral scale constants — Weber-Fechner based lightness + inverted bell
// saturation.
// ──────────────────────────────────────────────────────────────────────────

const _kNeutralWhiteL = 0.99;
const _kNeutralWhiteS = 0.06;

const _kNeutralWhiteDarkL = 0.95;
const _kNeutralWhiteDarkS = 0.05;

const _kNeutralWhiteDarkerL = 0.90;
const _kNeutralWhiteDarkerS = 0.04;

const _kNeutralGreyLightestL = 0.84;
const _kNeutralGreyLightestS = 0.03;

const _kNeutralGreyLighterL = 0.77;
const _kNeutralGreyLighterS = 0.03;

const _kNeutralGreyLightL = 0.69;
const _kNeutralGreyLightS = 0.02;

const _kNeutralGreyL = 0.60;
const _kNeutralGreyS = 0.02;

const _kNeutralGreyDarkL = 0.50;
const _kNeutralGreyDarkS = 0.02;

const _kNeutralGreyDarkerL = 0.40;
const _kNeutralGreyDarkerS = 0.02;

const _kNeutralGreyDarkestL = 0.31;
const _kNeutralGreyDarkestS = 0.03;

const _kNeutralBlackLighterL = 0.23;
const _kNeutralBlackLighterS = 0.04;

const _kNeutralBlackLightL = 0.16;
const _kNeutralBlackLightS = 0.05;

const _kNeutralBlackL = 0.10;
const _kNeutralBlackS = 0.06;

// ──────────────────────────────────────────────────────────────────────────
// Chromatic scale constants — bidirectional lerp from base.
// ──────────────────────────────────────────────────────────────────────────

const _kLightTarget = 0.95;
const _kDarkTarget = 0.15;

const _kTLightest = 0.95;
const _kTLighter = 0.85;
const _kTLight = 0.55;
const _kTDark = 0.55;
const _kTDarker = 0.85;
const _kTDarkest = 0.95;

/// 15-step neutral color scale based on a single hue input.
///
/// Follows Weber-Fechner law for perceptual uniformity:
/// - White group: narrow lightness steps for subtle background variations.
/// - Grey group: wider steps for borders, disabled, secondary text.
/// - Black group: narrow steps for dark backgrounds and text.
///
/// Saturation uses an inverted bell curve — minimal at mid-lightness (2%),
/// slightly higher at extremes (4-6%).
class NeutralScale {
  /// Creates a [NeutralScale] from a single hue value (0-360°).
  factory NeutralScale.fromHue(double hue) {
    CoreColor hsl(double s, double l) => CoreColorConversion.fromHSL(hue, s, l);

    return NeutralScale._(
      pureWhite: const CoreColor.fromARGB(255, 255, 255, 255),
      white: hsl(_kNeutralWhiteS, _kNeutralWhiteL),
      whiteDark: hsl(_kNeutralWhiteDarkS, _kNeutralWhiteDarkL),
      whiteDarker: hsl(
        _kNeutralWhiteDarkerS,
        _kNeutralWhiteDarkerL,
      ),
      greyLightest: hsl(
        _kNeutralGreyLightestS,
        _kNeutralGreyLightestL,
      ),
      greyLighter: hsl(
        _kNeutralGreyLighterS,
        _kNeutralGreyLighterL,
      ),
      greyLight: hsl(
        _kNeutralGreyLightS,
        _kNeutralGreyLightL,
      ),
      grey: hsl(_kNeutralGreyS, _kNeutralGreyL),
      greyDark: hsl(
        _kNeutralGreyDarkS,
        _kNeutralGreyDarkL,
      ),
      greyDarker: hsl(
        _kNeutralGreyDarkerS,
        _kNeutralGreyDarkerL,
      ),
      greyDarkest: hsl(
        _kNeutralGreyDarkestS,
        _kNeutralGreyDarkestL,
      ),
      blackLighter: hsl(
        _kNeutralBlackLighterS,
        _kNeutralBlackLighterL,
      ),
      blackLight: hsl(
        _kNeutralBlackLightS,
        _kNeutralBlackLightL,
      ),
      black: hsl(_kNeutralBlackS, _kNeutralBlackL),
      pureBlack: const CoreColor.fromARGB(255, 0, 0, 0),
    );
  }

  const NeutralScale._({
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

  /// Pure white (H:0, S:0%, L:100%).
  final CoreColor pureWhite;

  /// White (S:6%, L:99%).
  final CoreColor white;

  /// White dark (S:5%, L:95%).
  final CoreColor whiteDark;

  /// White darker (S:4%, L:90%).
  final CoreColor whiteDarker;

  /// Grey lightest (S:3%, L:84%).
  final CoreColor greyLightest;

  /// Grey lighter (S:3%, L:77%).
  final CoreColor greyLighter;

  /// Grey light (S:2%, L:69%).
  final CoreColor greyLight;

  /// Grey (S:2%, L:60%).
  final CoreColor grey;

  /// Grey dark (S:2%, L:50%).
  final CoreColor greyDark;

  /// Grey darker (S:2%, L:40%).
  final CoreColor greyDarker;

  /// Grey darkest (S:3%, L:31%).
  final CoreColor greyDarkest;

  /// Black lighter (S:4%, L:23%).
  final CoreColor blackLighter;

  /// Black light (S:5%, L:16%).
  final CoreColor blackLight;

  /// Black (S:6%, L:10%).
  final CoreColor black;

  /// Pure black (H:0, S:0%, L:0%).
  final CoreColor pureBlack;
}

/// 7-step chromatic color scale generated from a single HSL base color.
///
/// Uses bidirectional linear interpolation:
/// - Light direction: lerp toward L=95% (background-safe).
/// - Dark direction: lerp toward L=15% (text-safe).
/// - Saturation is preserved across all 7 steps.
class ChromaticScale {
  /// Creates a [ChromaticScale] from HSL components.
  ///
  /// - [hue]: 0-360°.
  /// - [saturation]: 0-1.
  /// - [lightness]: 0-1 (base lightness).
  factory ChromaticScale.fromHSL({
    required double hue,
    required double saturation,
    required double lightness,
  }) {
    final baseL = lightness;

    return ChromaticScale._(
      lightest: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL + (_kLightTarget - baseL) * _kTLightest,
      ),
      lighter: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL + (_kLightTarget - baseL) * _kTLighter,
      ),
      light: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL + (_kLightTarget - baseL) * _kTLight,
      ),
      base: CoreColorConversion.fromHSL(hue, saturation, baseL),
      dark: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL - (baseL - _kDarkTarget) * _kTDark,
      ),
      darker: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL - (baseL - _kDarkTarget) * _kTDarker,
      ),
      darkest: CoreColorConversion.fromHSL(
        hue,
        saturation,
        baseL - (baseL - _kDarkTarget) * _kTDarkest,
      ),
    );
  }

  const ChromaticScale._({
    required this.lightest,
    required this.lighter,
    required this.light,
    required this.base,
    required this.dark,
    required this.darker,
    required this.darkest,
  });

  /// Lightest shade — backgrounds, badges.
  final CoreColor lightest;

  /// Lighter shade — borders, hover backgrounds.
  final CoreColor lighter;

  /// Light shade — secondary elements.
  final CoreColor light;

  /// Base shade — buttons, icons, primary elements.
  final CoreColor base;

  /// Dark shade — pressed state.
  final CoreColor dark;

  /// Darker shade — emphasized text.
  final CoreColor darker;

  /// Darkest shade — body text on colored backgrounds.
  final CoreColor darkest;
}

/// Complete primitive color palette generated from 8 input colors.
///
/// Contains 15 neutral colors and 7×7=49 chromatic colors (64 total).
///
/// Usage:
/// ```dart
/// final primitive = PrimitiveColors.generate(
///   primaryHSL: (h: 210, s: 0.80, l: 0.50),
///   secondaryHSL: (h: 280, s: 0.75, l: 0.45),
///   tertiaryHSL: (h: 160, s: 0.70, l: 0.40),
///   successHSL: (h: 140, s: 0.75, l: 0.40),
///   infoHSL: (h: 200, s: 0.80, l: 0.50),
///   warningHSL: (h: 45, s: 0.85, l: 0.50),
///   errorHSL: (h: 0, s: 0.80, l: 0.45),
///   neutralHue: 220,
/// );
/// ```
class PrimitiveColors {
  /// Generates a complete primitive color palette from 8 color inputs.
  ///
  /// Each chromatic color is specified as an HSL record:
  /// `(h: double, s: double, l: double)` where h is 0-360°, s and l are 0-1.
  ///
  /// [neutralHue] is the hue angle (0-360°) applied to the neutral scale.
  factory PrimitiveColors.generate({
    required ({double h, double s, double l}) primaryHSL,
    required ({double h, double s, double l}) secondaryHSL,
    required ({double h, double s, double l}) tertiaryHSL,
    required ({double h, double s, double l}) successHSL,
    required ({double h, double s, double l}) infoHSL,
    required ({double h, double s, double l}) warningHSL,
    required ({double h, double s, double l}) errorHSL,
    required double neutralHue,
  }) {
    return PrimitiveColors._(
      neutral: NeutralScale.fromHue(neutralHue),
      primary: ChromaticScale.fromHSL(
        hue: primaryHSL.h,
        saturation: primaryHSL.s,
        lightness: primaryHSL.l,
      ),
      secondary: ChromaticScale.fromHSL(
        hue: secondaryHSL.h,
        saturation: secondaryHSL.s,
        lightness: secondaryHSL.l,
      ),
      tertiary: ChromaticScale.fromHSL(
        hue: tertiaryHSL.h,
        saturation: tertiaryHSL.s,
        lightness: tertiaryHSL.l,
      ),
      success: ChromaticScale.fromHSL(
        hue: successHSL.h,
        saturation: successHSL.s,
        lightness: successHSL.l,
      ),
      info: ChromaticScale.fromHSL(
        hue: infoHSL.h,
        saturation: infoHSL.s,
        lightness: infoHSL.l,
      ),
      warning: ChromaticScale.fromHSL(
        hue: warningHSL.h,
        saturation: warningHSL.s,
        lightness: warningHSL.l,
      ),
      error: ChromaticScale.fromHSL(
        hue: errorHSL.h,
        saturation: errorHSL.s,
        lightness: errorHSL.l,
      ),
    );
  }

  const PrimitiveColors._({
    required this.neutral,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
  });

  /// Neutral color scale (15 colors).
  final NeutralScale neutral;

  /// Primary chromatic scale (7 steps).
  final ChromaticScale primary;

  /// Secondary chromatic scale (7 steps).
  final ChromaticScale secondary;

  /// Tertiary chromatic scale (7 steps).
  final ChromaticScale tertiary;

  /// Success chromatic scale (7 steps).
  final ChromaticScale success;

  /// Info chromatic scale (7 steps).
  final ChromaticScale info;

  /// Warning chromatic scale (7 steps).
  final ChromaticScale warning;

  /// Error chromatic scale (7 steps).
  final ChromaticScale error;
}
