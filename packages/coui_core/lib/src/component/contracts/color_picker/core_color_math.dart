/// Platform-independent color-space math utilities for `ColorPicker`.
///
/// Inputs / outputs are plain Dart records of `int` / `double` so the
/// same math runs on Flutter and Web without referencing platform
/// `Color` types — keeps the picker's HSV ↔ RGB ↔ Hex pipeline
/// guaranteed-identical across both platforms.
library;

import 'package:coui_core/src/component/contracts/color_picker/color_picker_contract.dart';

/// 8-bit RGB channel max (0..255).
const int kColorPickerChannelMaxRgb = 255;

/// Hue circle max in degrees (HSL / HSV).
const int kColorPickerChannelMaxHue = 360;

/// Saturation / lightness / value max in percent (HSL / HSV).
const int kColorPickerChannelMaxPercent = 100;

const int _kHexRadix = 16;
const int _kMaxByte = 255;
const int _kHueDegrees = 360;
const int _kPercentMax = 100;
const int _kHueSextR = 6;
const int _kHueSextG = 2;
const int _kHueSextB = 4;
const int _kDegreesPerSextant = 60;
const int _kHexComponentLength = 2;

/// Hex string layout: `#RR(0,2)GG(2,4)BB(4,6)`. Pre-computed substring
/// boundaries to avoid magic-number arithmetic at parse time.
const int _kHexRStart = 0;
const int _kHexGStart = _kHexComponentLength;
const int _kHexBStart = 2 * _kHexComponentLength;
const int _kHexEnd = 3 * _kHexComponentLength;

/// HSV → RGB sextant indices (0..5).
const double _kSextantOrange = 1;
const double _kSextantYellow = 2;
const double _kSextantGreen = 3;
const double _kSextantCyan = 4;
const double _kSextantBlue = 5;

/// HSL ↔ RGB conversion thresholds — saturation formula switches at
/// lightness == 0.5, and chroma uses `2 * lightness - 1` for the
/// upper half. Standard HSL math (Wikipedia HSL/HSV).
const double _kHslLightnessMidpoint = 0.5;
const double _kHslChromaScale = 2;

/// Strict `#RRGGBB` validator (case-insensitive).
bool isValidHexColor(String hex) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex);

/// Returns `#RRGGBB` (uppercase) form, prepending `#` if missing.
String normalizeHexColor(String hex) {
  final s = hex.startsWith('#') ? hex : '#$hex';
  return s.toUpperCase();
}

/// Parses a `#RRGGBB` hex string into a `(r, g, b)` record (0-255).
///
/// Returns `(0, 0, 0)` for invalid input — callers should use
/// [isValidHexColor] for explicit validation.
({int r, int g, int b}) hexToRgb(String hex) {
  if (!isValidHexColor(hex)) return (r: 0, g: 0, b: 0);
  final s = hex.replaceAll('#', '');
  return (
    r: int.parse(s.substring(_kHexRStart, _kHexGStart), radix: _kHexRadix),
    g: int.parse(s.substring(_kHexGStart, _kHexBStart), radix: _kHexRadix),
    b: int.parse(s.substring(_kHexBStart, _kHexEnd), radix: _kHexRadix),
  );
}

/// Encodes a `(r, g, b)` record into `#RRGGBB` (uppercase).
String rgbToHex({required int r, required int g, required int b}) {
  String two(int v) =>
      v.clamp(0, _kMaxByte).toRadixString(_kHexRadix).padLeft(2, '0');
  return '#${two(r)}${two(g)}${two(b)}'.toUpperCase();
}

/// Converts `(r, g, b)` (0-255) to `(h, s, v)` where
/// `h ∈ [0, 360)`, `s ∈ [0, 100]`, `v ∈ [0, 100]`.
({double h, double s, double v}) rgbToHsv({
  required int r,
  required int g,
  required int b,
}) {
  final rf = r / _kMaxByte;
  final gf = g / _kMaxByte;
  final bf = b / _kMaxByte;
  final max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
  final min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
  final d = max - min;
  double h = 0;
  if (d != 0) {
    if (max == rf) {
      h = ((gf - bf) / d) % _kHueSextR;
    } else if (max == gf) {
      h = ((bf - rf) / d) + _kHueSextG;
    } else {
      h = ((rf - gf) / d) + _kHueSextB;
    }
    h *= _kDegreesPerSextant;
    if (h < 0) h += _kHueDegrees;
  }
  final s = max == 0 ? 0.0 : d / max;
  return (h: h, s: s * _kPercentMax, v: max * _kPercentMax);
}

/// Converts `(r, g, b)` (0-255) to `(h, s, l)` where
/// `h ∈ [0, 360)`, `s ∈ [0, 100]`, `l ∈ [0, 100]`.
({double h, double s, double l}) rgbToHsl({
  required int r,
  required int g,
  required int b,
}) {
  final rf = r / _kMaxByte;
  final gf = g / _kMaxByte;
  final bf = b / _kMaxByte;
  final max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
  final min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
  final d = max - min;
  final l = (max + min) / 2;
  double h = 0;
  double s = 0;
  if (d != 0) {
    s = l > _kHslLightnessMidpoint
        ? d / (_kHslChromaScale - max - min)
        : d / (max + min);
    if (max == rf) {
      h = ((gf - bf) / d) + (gf < bf ? _kHueSextR : 0);
    } else if (max == gf) {
      h = ((bf - rf) / d) + _kHueSextG;
    } else {
      h = ((rf - gf) / d) + _kHueSextB;
    }
    h *= _kDegreesPerSextant;
  }
  return (h: h, s: s * _kPercentMax, l: l * _kPercentMax);
}

/// Converts `(h, s, l)` (h in 0-360, s/l in 0-100) to `(r, g, b)` (0-255).
({int r, int g, int b}) hslToRgb({
  required double h,
  required double s,
  required double l,
}) {
  final sf = (s / _kPercentMax).clamp(0.0, 1.0);
  final lf = (l / _kPercentMax).clamp(0.0, 1.0);
  if (sf == 0) {
    final v = (lf * _kMaxByte).round();
    return (r: v, g: v, b: v);
  }
  final c = (1 - (_kHslChromaScale * lf - 1).abs()) * sf;
  final hh = (h % _kHueDegrees) / _kDegreesPerSextant;
  final x = c * (1 - ((hh % _kHslChromaScale) - 1).abs());
  final m = lf - c / _kHslChromaScale;
  double rf;
  double gf;
  double bf;
  if (hh < _kSextantOrange) {
    rf = c;
    gf = x;
    bf = 0;
  } else if (hh < _kSextantYellow) {
    rf = x;
    gf = c;
    bf = 0;
  } else if (hh < _kSextantGreen) {
    rf = 0;
    gf = c;
    bf = x;
  } else if (hh < _kSextantCyan) {
    rf = 0;
    gf = x;
    bf = c;
  } else if (hh < _kSextantBlue) {
    rf = x;
    gf = 0;
    bf = c;
  } else {
    rf = c;
    gf = 0;
    bf = x;
  }
  return (
    r: ((rf + m) * _kMaxByte).round(),
    g: ((gf + m) * _kMaxByte).round(),
    b: ((bf + m) * _kMaxByte).round(),
  );
}

/// Converts `(h, s, v)` (h in 0-360, s/v in 0-100) to `(r, g, b)` (0-255).
({int r, int g, int b}) hsvToRgb({
  required double h,
  required double s,
  required double v,
}) {
  final sf = (s / _kPercentMax).clamp(0.0, 1.0);
  final vf = (v / _kPercentMax).clamp(0.0, 1.0);
  final c = vf * sf;
  final hh = ((h % _kHueDegrees) / _kDegreesPerSextant).clamp(
    0.0,
    _kHueSextR.toDouble(),
  );
  final x = c * (1 - ((hh % 2) - 1).abs());
  final m = vf - c;
  double rf;
  double gf;
  double bf;
  if (hh < _kSextantOrange) {
    rf = c;
    gf = x;
    bf = 0;
  } else if (hh < _kSextantYellow) {
    rf = x;
    gf = c;
    bf = 0;
  } else if (hh < _kSextantGreen) {
    rf = 0;
    gf = c;
    bf = x;
  } else if (hh < _kSextantCyan) {
    rf = 0;
    gf = x;
    bf = c;
  } else if (hh < _kSextantBlue) {
    rf = x;
    gf = 0;
    bf = c;
  } else {
    rf = c;
    gf = 0;
    bf = x;
  }
  return (
    r: ((rf + m) * _kMaxByte).round(),
    g: ((gf + m) * _kMaxByte).round(),
    b: ((bf + m) * _kMaxByte).round(),
  );
}

/// Caption of the panel's HEX input cell, the first cell of the input row.
/// A technical acronym like the channel captions beside it (`R` / `G` /
/// `B`), so it is the same string in every locale. Shared by both
/// platforms.
const String kColorPickerHexLabel = 'HEX';

/// Mode-specific 3-channel triplet — labels, current values, and per-
/// channel max — derived from a `#RRGGBB` hex. Single source of truth
/// for the picker's RGB / HSL / HSV input rows on both platforms.
({
  (String, String, String) labels,
  (int, int, int) values,
  (int, int, int) max,
})
colorPickerTriplet(CoreColorPickerMode mode, String hex) {
  final rgb = hexToRgb(isValidHexColor(hex) ? hex : '#000000');
  switch (mode) {
    case .rgb:
      return (
        labels: ('R', 'G', 'B'),
        values: (rgb.r, rgb.g, rgb.b),
        max: (
          kColorPickerChannelMaxRgb,
          kColorPickerChannelMaxRgb,
          kColorPickerChannelMaxRgb,
        ),
      );
    case .hsl:
      final hsl = rgbToHsl(r: rgb.r, g: rgb.g, b: rgb.b);
      return (
        labels: ('H', 'S', 'L'),
        values: (hsl.h.round(), hsl.s.round(), hsl.l.round()),
        max: (
          kColorPickerChannelMaxHue,
          kColorPickerChannelMaxPercent,
          kColorPickerChannelMaxPercent,
        ),
      );
    case .hsv:
      final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
      return (
        labels: ('H', 'S', 'V'),
        values: (hsv.h.round(), hsv.s.round(), hsv.v.round()),
        max: (
          kColorPickerChannelMaxHue,
          kColorPickerChannelMaxPercent,
          kColorPickerChannelMaxPercent,
        ),
      );
  }
}

/// Applies a numeric edit to one channel (0/1/2) of the active mode
/// and returns the resulting `#RRGGBB` hex. Mirrors what the picker's
/// numeric inputs do — the math is identical on both platforms so it
/// belongs here rather than duplicated in each renderer.
String applyColorPickerChannelEdit({
  required CoreColorPickerMode mode,
  required String hex,
  required int channel,
  required int value,
}) {
  final rgb = hexToRgb(isValidHexColor(hex) ? hex : '#000000');
  switch (mode) {
    case .rgb:
      var r = rgb.r;
      var g = rgb.g;
      var b = rgb.b;
      switch (channel) {
        case 0:
          r = value;
        case 1:
          g = value;
        case 2:
          b = value;
      }
      return rgbToHex(r: r, g: g, b: b);
    case .hsl:
      final hsl = rgbToHsl(r: rgb.r, g: rgb.g, b: rgb.b);
      var h = hsl.h;
      var s = hsl.s;
      var l = hsl.l;
      switch (channel) {
        case 0:
          h = value.toDouble();
        case 1:
          s = value.toDouble();
        case 2:
          l = value.toDouble();
      }
      final next = hslToRgb(h: h, s: s, l: l);
      return rgbToHex(r: next.r, g: next.g, b: next.b);
    case .hsv:
      final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
      var h = hsv.h;
      var s = hsv.s;
      var v = hsv.v;
      switch (channel) {
        case 0:
          h = value.toDouble();
        case 1:
          s = value.toDouble();
        case 2:
          v = value.toDouble();
      }
      final next = hsvToRgb(h: h, s: s, v: v);
      return rgbToHex(r: next.r, g: next.g, b: next.b);
  }
}
