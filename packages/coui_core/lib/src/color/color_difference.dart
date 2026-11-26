import 'dart:math' as math;

import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/core_color.dart';

/// Perceived colour difference — CIEDE2000 (ΔE₀₀) between two opaque
/// colours.
///
/// The brand palette generator reads it to tell when a status colour sits
/// too close to the brand colour to be told apart (see
/// `CoreBrandPalette.collisionDeltaE`). Contrast (`CoreContrast`) answers a
/// different question — whether one colour is legible on another — and two
/// colours of equal luminance can still be far apart in ΔE.
///
/// The CIE Lab step uses the sRGB → XYZ matrix with the D65 white point and
/// [CoreColorConversion.srgbToLinear] for the transfer function, so the
/// channel decoding is the kit's single one.
abstract final class CoreColorDifference {
  /// CIEDE2000 difference between [a] and [b]; 0 for identical colours.
  ///
  /// Symmetric. Alpha is ignored — both colours are read as opaque.
  static double ciede2000(CoreColor a, CoreColor b) {
    final lab1 = _toLab(a);
    final lab2 = _toLab(b);
    const rad = math.pi / _kHalfTurn;

    final c1 = _hypot(lab1.a, lab1.b);
    final c2 = _hypot(lab2.a, lab2.b);
    final cMean = (c1 + c2) / 2;
    final g = 0.5 * (1 - math.sqrt(_pow7(cMean) / (_pow7(cMean) + _k25Pow7)));
    final a1 = lab1.a * (1 + g);
    final a2 = lab2.a * (1 + g);
    final c1p = _hypot(a1, lab1.b);
    final c2p = _hypot(a2, lab2.b);
    final h1 = (math.atan2(lab1.b, a1) / rad + _kFullTurn) % _kFullTurn;
    final h2 = (math.atan2(lab2.b, a2) / rad + _kFullTurn) % _kFullTurn;

    final dL = lab2.l - lab1.l;
    final dC = c2p - c1p;
    var dh = h2 - h1;
    if (dh.abs() > _kHalfTurn) dh -= _kFullTurn * dh.sign;
    final dH = 2 * math.sqrt(c1p * c2p) * math.sin(dh * rad / 2);

    final lMean = (lab1.l + lab2.l) / 2;
    final cMeanP = (c1p + c2p) / 2;
    final hMean = (h1 - h2).abs() <= _kHalfTurn
        ? (h1 + h2) / 2
        : (h1 + h2 + _kFullTurn) / 2;
    final t =
        1 -
        0.17 * math.cos((hMean - 30) * rad) +
        0.24 * math.cos(2 * hMean * rad) +
        0.32 * math.cos((3 * hMean + 6) * rad) -
        0.20 * math.cos((4 * hMean - 63) * rad);
    final lOffset = (lMean - 50) * (lMean - 50);
    final sL = 1 + 0.015 * lOffset / math.sqrt(20 + lOffset);
    final sC = 1 + 0.045 * cMeanP;
    final sH = 1 + 0.015 * cMeanP * t;
    final dTheta = 30 * math.exp(-math.pow((hMean - 275) / 25, 2));
    final rC = 2 * math.sqrt(_pow7(cMeanP) / (_pow7(cMeanP) + _k25Pow7));
    final rT = -math.sin(2 * dTheta * rad) * rC;

    final termL = dL / sL;
    final termC = dC / sC;
    final termH = dH / sH;

    return math.sqrt(
      termL * termL + termC * termC + termH * termH + rT * termC * termH,
    );
  }

  static ({double l, double a, double b}) _toLab(CoreColor color) {
    final r = CoreColorConversion.srgbToLinear(color.red / _kChannelMax);
    final g = CoreColorConversion.srgbToLinear(color.green / _kChannelMax);
    final b = CoreColorConversion.srgbToLinear(color.blue / _kChannelMax);

    final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / _kWhiteX;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / _kWhiteZ;

    double f(double v) =>
        v > _kLabEpsilon ? math.pow(v, 1 / 3).toDouble() : 7.787 * v + 16 / 116;

    return (
      l: 116 * f(y) - 16,
      a: 500 * (f(x) - f(y)),
      b: 200 * (f(y) - f(z)),
    );
  }

  static double _hypot(double x, double y) => math.sqrt(x * x + y * y);

  static double _pow7(double v) => math.pow(v, 7).toDouble();
}

const double _kHalfTurn = 180;
const double _kFullTurn = 360;
const double _kChannelMax = 255;
const double _kWhiteX = 0.95047;
const double _kWhiteZ = 1.08883;
const double _kLabEpsilon = 0.008856;
// 25⁷ — the chroma pivot of the CIEDE2000 G and R_C terms.
const double _k25Pow7 = 6103515625;
