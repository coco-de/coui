import 'dart:math' as math;

import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

// OKLch format parsing constants
const _kOklchGroup1 = 1;
const _kOklchGroup2 = 2;
const _kOklchGroup3 = 3;
const _kOklchGroup4 = 4;

const _kDecimalPrecision2 = 2;
const _kDecimalPrecision4 = 4;

/// Utilities for converting between color spaces.
///
/// Supports OKLch, HSL, Hex, and ARGB conversions without any platform
/// dependency (no `dart:ui`).
class CoreColorConversion {
  const CoreColorConversion._();

  // Colour-space scalar constants — single source for the platform packages
  // (relocated here from the former coui_flutter `ColorConstants`).

  /// Maximum RGB channel value.
  static const rgbMax = 255;

  /// Maximum alpha channel value.
  static const int alphaMax = rgbMax;

  /// Minimum color channel value.
  static const channelMin = 0;

  /// RGB scaling multiplier (0–1 ↔ 0–255).
  static const rgbScale = 255.0;

  /// Maximum hue value in degrees.
  static const hueMax = 360;

  /// Percentage maximum value.
  static const percentMax = 100;

  /// Percentage divisor for decimal conversion.
  static const int percentDivisor = percentMax;

  /// HSL/HSV saturation and lightness/value range minimum.
  static const slMinimum = 0.0;

  /// HSL/HSV saturation and lightness/value range maximum.
  static const slMaximum = 1.0;

  /// Radix for hexadecimal conversion.
  static const hexRadix = 16;

  /// ARGB-to-RGB hex prefix length.
  static const hexPrefixLength = 2;

  /// Half value (0.5) for midpoint calculations.
  static const half = 0.5;

  /// Opacity fully transparent.
  static const opacityTransparent = 0.0;

  /// Opacity fully opaque.
  static const opacityOpaque = 1.0;

  // sRGB gamma correction thresholds and constants
  static const _srgbLinearThreshold = 0.0031308;
  static const _srgbLinearMultiplier = 12.92;
  static const _srgbGammaThreshold = 0.04045;
  static const _srgbGammaMultiplier = 1.055;
  static const _srgbGammaOffset = 0.055;
  static const _srgbGammaExponent = 2.4;
  static const double _srgbGammaExponentReciprocal = 1.0 / 2.4;

  // HSL color space constants (hue sextant indices as a sequence so the
  // literal `2`/`0.5` do not duplicate hexPrefixLength / half above).
  static const _hslMaxSegments = 6.0;
  static const _hslSegment1 = 1;
  static const int _hslSegment2 = _hslSegment1 + 1;
  static const int _hslSegment3 = _hslSegment2 + 1;
  static const int _hslSegment4 = _hslSegment3 + 1;
  static const int _hslSegment5 = _hslSegment4 + 1;
  static const double _hslLightnessThreshold = half;

  // OKLab cube root exponent
  static const double _oklabCubeRootExponent = 1.0 / 3.0;

  // OKLab → Linear RGB transformation matrix
  static const _oklabLrToLabA1 = 0.3963377774;
  static const _oklabLrToLabB1 = 0.2158037573;
  static const _oklabLgToLabA1 = 0.1055613458;
  static const _oklabLgToLabB1 = 0.0638541728;
  static const _oklabLbToLabA1 = 0.0894841775;
  static const _oklabLbToLabB1 = 1.2914855480;

  static const _oklabToRgbR1 = 4.0767416621;
  static const _oklabToRgbR2 = 3.3077115913;
  static const _oklabToRgbR3 = 0.2309699292;
  static const _oklabToRgbG1 = 1.2684380046;
  static const _oklabToRgbG2 = 2.6097574011;
  static const _oklabToRgbG3 = 0.3413193965;
  static const _oklabToRgbB1 = 0.0041960863;
  static const _oklabToRgbB2 = 0.7034186147;
  static const _oklabToRgbB3 = 1.7076147010;

  // Linear RGB → OKLab transformation matrix
  static const _rgbToOklabLr1 = 0.4122214708;
  static const _rgbToOklabLr2 = 0.5363325363;
  static const _rgbToOklabLr3 = 0.0514459929;
  static const _rgbToOklabLg1 = 0.2119034982;
  static const _rgbToOklabLg2 = 0.6806995451;
  static const _rgbToOklabLg3 = 0.1073969566;
  static const _rgbToOklabLb1 = 0.0883024619;
  static const _rgbToOklabLb2 = 0.2817188376;
  static const _rgbToOklabLb3 = 0.6299787005;

  static const _oklabL1 = 0.2104542553;
  static const _oklabL2 = 0.7936177850;
  static const _oklabL3 = 0.0040720468;
  static const _oklabA1 = 1.9779984951;
  static const _oklabA2 = 2.4285922050;
  static const _oklabA3 = 0.4505937099;
  static const _oklabB1 = 0.0259040371;
  static const _oklabB2 = 0.7827717662;
  static const _oklabB3 = 0.8086757660;

  /// Parse OKLch color string to [CoreColor].
  ///
  /// Format: `oklch(L% C H)` or `oklch(L% C H / A%)`.
  static CoreColor fromOKLch(String oklchString) {
    final match = RegExp(
      r'oklch\s*\(\s*(\d+(?:\.\d+)?)\s*%?\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\s*(?:\/\s*(\d+(?:\.\d+)?)\s*%?)?\s*\)',
    ).firstMatch(oklchString);

    if (match == null) {
      throw FormatException('Invalid OKLch format: $oklchString');
    }

    final l = double.parse(match.group(_kOklchGroup1)!) / percentMax;
    final c = double.parse(match.group(_kOklchGroup2)!);
    final h = double.parse(match.group(_kOklchGroup3)!);
    final a = match.group(_kOklchGroup4) != null
        ? double.parse(match.group(_kOklchGroup4)!) / percentMax
        : 1.0;

    return oklchToColor(l, c, h, a);
  }

  /// Convert OKLch components to [CoreColor].
  ///
  /// - [l]: Lightness (0-1).
  /// - [c]: Chroma (0-0.4 typically).
  /// - [h]: Hue (0-360 degrees).
  /// - [a]: Alpha (0-1, default 1.0).
  static CoreColor oklchToColor(
    double l,
    double c,
    double h, [
    double a = 1.0,
  ]) {
    final linear = oklchToLinearSrgb(l, c, h);

    final sR = _linearToSrgb(linear.r);
    final sG = _linearToSrgb(linear.g);
    final sB = _linearToSrgb(linear.b);

    final red = (sR * rgbScale).clamp(channelMin, rgbMax).round();
    final green = (sG * rgbScale).clamp(channelMin, rgbMax).round();
    final blue = (sB * rgbScale).clamp(channelMin, rgbMax).round();
    final alpha = (a * rgbScale).clamp(channelMin, rgbMax).round();

    return CoreColor.fromARGB(alpha, red, green, blue);
  }

  /// OKLch components to linear-light sRGB channels, before any clamping.
  ///
  /// A channel outside 0–1 means the colour lies outside the sRGB gamut —
  /// [oklchToColor] clamps it, [isInSrgbGamut] reports it. Kept apart so a
  /// caller that has to stay inside the gamut (the brand ramp generator
  /// searching for the most saturated in-gamut chroma) reads the same
  /// matrix [oklchToColor] paints with.
  static ({double r, double g, double b}) oklchToLinearSrgb(
    double l,
    double c,
    double h,
  ) {
    final hRad = h * math.pi / (hueMax / 2.0);
    final labA = c * math.cos(hRad);
    final labB = c * math.sin(hRad);

    final lr = l + _oklabLrToLabA1 * labA + _oklabLrToLabB1 * labB;
    final lg = l - _oklabLgToLabA1 * labA - _oklabLgToLabB1 * labB;
    final lb = l - _oklabLbToLabA1 * labA - _oklabLbToLabB1 * labB;

    final lrCubed = lr * lr * lr;
    final lgCubed = lg * lg * lg;
    final lbCubed = lb * lb * lb;

    return (
      r:
          _oklabToRgbR1 * lrCubed -
          _oklabToRgbR2 * lgCubed +
          _oklabToRgbR3 * lbCubed,
      g:
          -_oklabToRgbG1 * lrCubed +
          _oklabToRgbG2 * lgCubed -
          _oklabToRgbG3 * lbCubed,
      b:
          -_oklabToRgbB1 * lrCubed -
          _oklabToRgbB2 * lgCubed +
          _oklabToRgbB3 * lbCubed,
    );
  }

  /// Whether the OKLch colour ([l], [c], [h]) lies inside the sRGB gamut.
  ///
  /// Each linear channel may overshoot 0–1 by [gamutTolerance] — the
  /// rounding noise of the matrix at the gamut edge, which an 8-bit channel
  /// cannot show.
  static bool isInSrgbGamut(double l, double c, double h) {
    final linear = oklchToLinearSrgb(l, c, h);
    bool inside(double v) =>
        v >= -gamutTolerance && v <= slMaximum + gamutTolerance;

    return inside(linear.r) && inside(linear.g) && inside(linear.b);
  }

  /// How far a linear channel may fall outside 0–1 and still count as
  /// inside the gamut in [isInSrgbGamut].
  static const double gamutTolerance = 0.0005;

  /// Convert [CoreColor] to OKLch string.
  static String toOKLch(CoreColor color) {
    final components = colorToOKLch(color);
    final l = (components.l * percentMax).toStringAsFixed(
      _kDecimalPrecision2,
    );
    final c = components.c.toStringAsFixed(_kDecimalPrecision4);
    final h = components.h.toStringAsFixed(_kDecimalPrecision2);

    if (components.a < 1.0) {
      final a = (components.a * percentMax).toStringAsFixed(
        _kDecimalPrecision2,
      );
      return 'oklch($l% $c $h / $a%)';
    }

    return 'oklch($l% $c $h)';
  }

  /// Convert [CoreColor] to OKLch components.
  ///
  /// Requires the ARGB case; semantic-token colours must be resolved
  /// against a scheme first.
  static OKLchComponents colorToOKLch(CoreColor color) {
    final r = srgbToLinear(color.red / rgbScale);
    final g = srgbToLinear(color.green / rgbScale);
    final b = srgbToLinear(color.blue / rgbScale);

    final lr = math.pow(
      _rgbToOklabLr1 * r + _rgbToOklabLr2 * g + _rgbToOklabLr3 * b,
      _oklabCubeRootExponent,
    );
    final lg = math.pow(
      _rgbToOklabLg1 * r + _rgbToOklabLg2 * g + _rgbToOklabLg3 * b,
      _oklabCubeRootExponent,
    );
    final lb = math.pow(
      _rgbToOklabLb1 * r + _rgbToOklabLb2 * g + _rgbToOklabLb3 * b,
      _oklabCubeRootExponent,
    );

    final l = _oklabL1 * lr + _oklabL2 * lg - _oklabL3 * lb;
    final labA = _oklabA1 * lr - _oklabA2 * lg + _oklabA3 * lb;
    final labB = _oklabB1 * lr + _oklabB2 * lg - _oklabB3 * lb;

    final c = math.sqrt(labA * labA + labB * labB);
    final h =
        (math.atan2(labB, labA) * (hueMax / 2.0) / math.pi + hueMax) % hueMax;
    final a = color.alpha / rgbScale;

    return OKLchComponents(l: l, c: c, h: h, a: a);
  }

  /// Convert HSL to [CoreColor].
  ///
  /// - [h]: Hue (0-360 degrees).
  /// - [s]: Saturation (0-1).
  /// - [l]: Lightness (0-1).
  /// - [a]: Alpha (0-1, default 1.0).
  static CoreColor fromHSL(double h, double s, double l, [double a = 1.0]) {
    final hNorm = h % hueMax / hueMax;

    final c = (1.0 - (2.0 * l - 1.0).abs()) * s;
    final x = c * (1.0 - ((hNorm * _hslMaxSegments) % 2.0 - 1.0).abs());
    final m = l - c / 2.0;

    double r;
    double g;
    double b;

    if (hNorm < _hslSegment1 / _hslMaxSegments) {
      r = c;
      g = x;
      b = 0.0;
    } else if (hNorm < _hslSegment2 / _hslMaxSegments) {
      r = x;
      g = c;
      b = 0.0;
    } else if (hNorm < _hslSegment3 / _hslMaxSegments) {
      r = 0.0;
      g = c;
      b = x;
    } else if (hNorm < _hslSegment4 / _hslMaxSegments) {
      r = 0.0;
      g = x;
      b = c;
    } else if (hNorm < _hslSegment5 / _hslMaxSegments) {
      r = x;
      g = 0.0;
      b = c;
    } else {
      r = c;
      g = 0.0;
      b = x;
    }

    return CoreColor.fromARGB(
      (a * rgbScale).round(),
      ((r + m) * rgbScale).round(),
      ((g + m) * rgbScale).round(),
      ((b + m) * rgbScale).round(),
    );
  }

  /// Convert [CoreColor] to HSL components.
  static HSLComponents colorToHSL(CoreColor color) {
    final r = color.red / rgbScale;
    final g = color.green / rgbScale;
    final b = color.blue / rgbScale;

    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final delta = max - min;

    final l = (max + min) / 2.0;

    if (delta == 0.0) {
      return HSLComponents(h: 0, s: 0, l: l, a: color.opacity);
    }

    final s = l > _hslLightnessThreshold
        ? delta / (2.0 - max - min)
        : delta / (max + min);

    double h;
    if (max == r) {
      h = ((g - b) / delta + (g < b ? _hslMaxSegments : 0.0)) / _hslMaxSegments;
    } else if (max == g) {
      h = ((b - r) / delta + _hslSegment2) / _hslMaxSegments;
    } else {
      h = ((r - g) / delta + _hslSegment4) / _hslMaxSegments;
    }

    return HSLComponents(h: h * hueMax, s: s, l: l, a: color.opacity);
  }

  /// Linear RGB to sRGB gamma correction.
  static double _linearToSrgb(double linear) {
    if (linear <= _srgbLinearThreshold) {
      return linear * _srgbLinearMultiplier;
    }
    return _srgbGammaMultiplier *
            math.pow(linear, _srgbGammaExponentReciprocal) -
        _srgbGammaOffset;
  }

  /// Decodes one gamma-encoded sRGB channel (0–1) to linear light (0–1).
  ///
  /// The single sRGB transfer function in the kit: OKLab conversion and
  /// WCAG relative luminance (`CoreContrast.relativeLuminance`) both read
  /// it, so the two can never disagree about what a channel means. The
  /// 0.04045 knee is the IEC 61966-2-1 value WCAG 2.2 also states; the
  /// older 0.03928 printed in WCAG 2.0 falls between the same two 8-bit
  /// codes (10 and 11 / 255), so no 8-bit colour reads differently.
  static double srgbToLinear(double srgb) {
    if (srgb <= _srgbGammaThreshold) {
      return srgb / _srgbLinearMultiplier;
    }
    return math
        .pow(
          (srgb + _srgbGammaOffset) / _srgbGammaMultiplier,
          _srgbGammaExponent,
        )
        .toDouble();
  }
}

/// OKLch color components.
@immutable
class OKLchComponents {
  /// Creates an [OKLchComponents] with the given channel values.
  const OKLchComponents({
    required this.l,
    required this.c,
    required this.h,
    this.a = 1.0,
  });

  /// Lightness (0-1).
  final double l;

  /// Chroma (0-0.4 typically).
  final double c;

  /// Hue (0-360 degrees).
  final double h;

  /// Alpha (0-1).
  final double a;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OKLchComponents &&
          l == other.l &&
          c == other.c &&
          h == other.h &&
          a == other.a;

  @override
  int get hashCode => Object.hash(l, c, h, a);

  @override
  String toString() {
    const percentMax = CoreColorConversion.percentMax;
    const precision = _kDecimalPrecision2;
    return 'OKLch(L: ${(l * percentMax).toStringAsFixed(precision)}%, '
        'C: ${c.toStringAsFixed(_kDecimalPrecision4)}, '
        'H: ${h.toStringAsFixed(precision)}°, '
        'A: ${(a * percentMax).toStringAsFixed(precision)}%)';
  }
}

/// HSL color components.
@immutable
class HSLComponents {
  /// Creates an [HSLComponents] with the given channel values.
  const HSLComponents({
    required this.h,
    required this.s,
    required this.l,
    this.a = 1.0,
  });

  /// Hue (0-360 degrees).
  final double h;

  /// Saturation (0-1).
  final double s;

  /// Lightness (0-1).
  final double l;

  /// Alpha (0-1).
  final double a;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HSLComponents &&
          h == other.h &&
          s == other.s &&
          l == other.l &&
          a == other.a;

  @override
  int get hashCode => Object.hash(h, s, l, a);

  @override
  String toString() {
    const percentMax = CoreColorConversion.percentMax;
    return 'HSL(H: ${h.toStringAsFixed(_kDecimalPrecision2)}°, '
        'S: ${(s * percentMax).toStringAsFixed(_kDecimalPrecision2)}%, '
        'L: ${(l * percentMax).toStringAsFixed(_kDecimalPrecision2)}%, '
        'A: ${(a * percentMax).toStringAsFixed(_kDecimalPrecision2)}%)';
  }
}
