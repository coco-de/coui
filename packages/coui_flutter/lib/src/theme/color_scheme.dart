import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

// Local color scheme constants
const _kChartColorCount = 5;
const _kDefaultLightnessStepDown = 8;
const _kDefaultLightnessStepUp = 9;
const _kShadeIndex1 = 1;
const _kShadeIndex2 = 2;
const _kShadeIndex3 = 3;
const _kShadeIndex4 = 4;
const _kShadeStep = 100;
const _kHueShiftDivisor = 10;

// Shade value constants
const _kShade50 = 50;
const _kShade100 = 100;
const _kShade200 = 200;
const _kShade300 = 300;
const _kShade400 = 400;
const _kShade500 = 500;
const _kShade600 = 600;
const _kShade700 = 700;
const _kShade800 = 800;
const _kShade900 = 900;
const _kShade950 = 950;

Color _fromAHSL(double a, double h, double l, double s) {
  return HSLColor.fromAHSL(a, h, s, l).toColor();
}

/// Source-compatibility alias.
///
/// `ColorScheme` is now [CoreColorScheme] — the cross-platform colour
/// scheme that returns [CoreColor] for every field. Call sites that
/// pass it to raw Flutter widgets (`Container(color: …)`, `TextStyle`,
/// …) must add `.toValue()` to convert to Flutter `Color`.
typedef ColorScheme = CoreColorScheme;

class SingleChartColorScheme implements ChartColorScheme {
  const SingleChartColorScheme(this.color);

  final Color color;

  @override
  List<Color> get chartColors => .filled(_kChartColorCount, color);

  @override
  Color get chart1 => color;

  @override
  Color get chart2 => color;

  @override
  Color get chart3 => color;

  @override
  Color get chart4 => color;

  @override
  Color get chart5 => color;
}

class ChartColorScheme {
  const ChartColorScheme(this.chartColors);

  factory ChartColorScheme.single(Color color) {
    return SingleChartColorScheme(color);
  }

  final List<Color> chartColors;

  Color get chart1 => chartColors.first;
  Color get chart2 => chartColors[_kShadeIndex1];
  Color get chart3 => chartColors[_kShadeIndex2];
  Color get chart4 => chartColors[_kShadeIndex3];
  Color get chart5 => chartColors[_kShadeIndex4];
}

class ColorShades implements Color, ColorSwatch<dynamic> {
  ColorShades._() : _colors = {};

  @protected
  const ColorShades.raw(this._colors);

  factory ColorShades.sorted(List<Color> colors) {
    assert(
      colors.length == shadeValues.length,
      'ColorShades.sorted: Invalid number of colors',
    );
    final slate = ColorShades._();
    for (int i = 0; i < shadeValues.length; i += 1) {
      slate._colors[shadeValues[i]] = colors[i];
    }

    return slate;
  }

  factory ColorShades.fromAccent(
    Color accent, {
    int base = _kShade500,
    int hueShift = 0,
    int lightnessStepDown = _kDefaultLightnessStepDown,
    int lightnessStepUp = _kDefaultLightnessStepUp,
    int saturationStepDown = 0,
    int saturationStepUp = 0,
  }) {
    assert(
      shadeValues.contains(base),
      'ColorShades.fromAccent: Invalid base value',
    );
    final hsl = HSLColor.fromColor(accent);

    return ColorShades.fromAccentHSL(
      hsl,
      base: base,
      hueShift: hueShift,
      lightnessStepDown: lightnessStepDown,
      lightnessStepUp: lightnessStepUp,
      saturationStepDown: saturationStepDown,
      saturationStepUp: saturationStepUp,
    );
  }

  factory ColorShades.fromAccentHSL(
    HSLColor accent, {
    int base = _kShade500,
    int hueShift = 0,
    int lightnessStepDown = _kDefaultLightnessStepDown,
    int lightnessStepUp = _kDefaultLightnessStepUp,
    int saturationStepDown = 0,
    int saturationStepUp = 0,
  }) {
    assert(
      shadeValues.contains(base),
      'ColorShades.fromAccent: Invalid base value',
    );
    final slate = ColorShades._();
    for (final key in shadeValues) {
      final delta = (key - base) / _kShadeStep;
      final hueDelta = delta * (hueShift / _kHueShiftDivisor);
      final saturationDelta = delta > 0
          ? delta * saturationStepUp
          : delta * saturationStepDown;
      final lightnessDelta = delta > 0
          ? delta * lightnessStepUp
          : delta * lightnessStepDown;
      final h = (accent.hue + hueDelta) % CoreColorConversion.hueMax;
      final s =
          (accent.saturation * CoreColorConversion.percentMax - saturationDelta)
              .clamp(
                CoreColorConversion.slMinimum,
                CoreColorConversion.percentMax,
              ) /
          CoreColorConversion.percentMax;
      final l =
          (accent.lightness * CoreColorConversion.percentMax - lightnessDelta)
              .clamp(
                CoreColorConversion.slMinimum,
                CoreColorConversion.percentMax,
              ) /
          CoreColorConversion.percentMax;
      final a = accent.alpha;
      slate._colors[key] = _fromAHSL(a, h, s, l);
    }

    return slate;
  }

  factory ColorShades.fromMap(Map<int, Color> colors) {
    final slate = ColorShades._();
    for (final key in shadeValues) {
      assert(
        colors.containsKey(key),
        'ColorShades.fromMap: Missing value for $key',
      );
      slate._colors[key] = colors[key]!;
    }

    return slate;
  }

  const ColorShades._direct(this._colors);

  static const shadeValues = [
    _kShade50,
    _kShade100,
    _kShade200,
    _kShade300,
    _kShade400,
    _kShade500,
    _kShade600,
    _kShade700,
    _kShade800,
    _kShade900,
    _kShade950,
  ];

  final Map<int, Color> _colors;

  static HSLColor shiftHSL(
    HSLColor hsv,
    int targetBase, {
    int base = _kShade500,
    int hueShift = 0,
    int lightnessStepDown = _kDefaultLightnessStepDown,
    int lightnessStepUp = _kDefaultLightnessStepUp,
    int saturationStepDown = 0,
    int saturationStepUp = 0,
  }) {
    assert(
      shadeValues.contains(base),
      'ColorShades.fromAccent: Invalid base value',
    );
    final delta = (targetBase - base) / _kShadeStep;
    final hueDelta = delta * (hueShift / _kHueShiftDivisor);
    final saturationDelta = delta > 0
        ? delta * saturationStepUp
        : delta * saturationStepDown;
    final lightnessDelta = delta > 0
        ? delta * lightnessStepUp
        : delta * lightnessStepDown;
    final h = (hsv.hue + hueDelta) % CoreColorConversion.hueMax;
    final s =
        (hsv.saturation * CoreColorConversion.percentMax - saturationDelta)
            .clamp(
              CoreColorConversion.slMinimum,
              CoreColorConversion.percentMax,
            ) /
        CoreColorConversion.percentMax;
    final l =
        (hsv.lightness * CoreColorConversion.percentMax - lightnessDelta).clamp(
          CoreColorConversion.slMinimum,
          CoreColorConversion.percentMax,
        ) /
        CoreColorConversion.percentMax;
    final a = hsv.alpha;

    return HSLColor.fromAHSL(a, h, s, l);
  }

  Color get(int key) {
    assert(_colors.containsKey(key), 'ColorShades.get: Missing value for $key');

    return _colors[key]!;
  }

  @override
  double computeLuminance() {
    return _primary.computeLuminance();
  }

  @override
  ColorShades withAlpha(int a) {
    final colors = <int, Color>{};
    for (final key in shadeValues) {
      colors[key] = _colors[key]!.withAlpha(a);
    }

    return ColorShades._direct(colors);
  }

  @override
  ColorShades withBlue(int b) {
    final colors = <int, Color>{};
    // calculate the difference between the current blue value and the new value
    final delta = b - blue;
    for (final key in shadeValues) {
      final safe =
          ((_colors[key]!.b * CoreColorConversion.rgbScale).round() + delta)
              .clamp(
                CoreColorConversion.channelMin,
                CoreColorConversion.rgbMax,
              );
      colors[key] = _colors[key]!.withBlue(safe);
    }

    return ColorShades._direct(colors);
  }

  @override
  Color withGreen(int g) {
    final colors = <int, Color>{};
    // calculate the difference between the current green value and the new value
    final delta = g - green;
    for (final key in shadeValues) {
      final safe =
          ((_colors[key]!.g * CoreColorConversion.rgbScale).round() + delta)
              .clamp(
                CoreColorConversion.channelMin,
                CoreColorConversion.rgbMax,
              );
      colors[key] = _colors[key]!.withGreen(safe);
    }

    return ColorShades._direct(colors);
  }

  @override
  Color withOpacity(double opacity) {
    final colors = <int, Color>{};
    for (final key in shadeValues) {
      colors[key] = _colors[key]!.scaleAlpha(opacity);
    }

    return ColorShades._direct(colors);
  }

  @override
  Color withRed(int r) {
    final colors = <int, Color>{};
    // calculate the difference between the current red value and the new value
    final delta = r - red;
    for (final key in shadeValues) {
      final safe =
          ((_colors[key]!.r * CoreColorConversion.rgbScale).round() + delta)
              .clamp(
                CoreColorConversion.channelMin,
                CoreColorConversion.rgbMax,
              );
      colors[key] = _colors[key]!.withRed(safe);
    }

    return ColorShades._direct(colors);
  }

  @override
  Color operator [](covariant int index) {
    final color = _colors[index];
    assert(color != null, 'ColorShades: Missing color for $index');

    return color!;
  }

  @override
  Color withValues({
    double? alpha,
    double? blue,
    ColorSpace? colorSpace,
    double? green,
    double? red,
  }) {
    final colors = <int, Color>{};
    for (final key in shadeValues) {
      colors[key] = _colors[key]!.withValues(
        alpha: alpha,
        red: red,
        green: green,
        blue: blue,
        colorSpace: colorSpace,
      );
    }

    return ColorShades._direct(colors);
  }

  @override
  int toARGB32() {
    return _primary.toARGB32();
  }

  Color get shade50 => _colors[_kShade50]!;
  Color get shade100 => _colors[_kShade100]!;

  Color get shade200 => _colors[_kShade200]!;

  Color get shade300 => _colors[_kShade300]!;

  Color get shade400 => _colors[_kShade400]!;

  Color get shade500 => _colors[_kShade500]!;

  Color get shade600 => _colors[_kShade600]!;

  Color get shade700 => _colors[_kShade700]!;

  Color get shade800 => _colors[_kShade800]!;

  Color get shade900 => _colors[_kShade900]!;

  Color get shade950 => _colors[_kShade950]!;

  Color get _primary => _colors[_kShade500]!;

  @override
  int get alpha =>
      (_primary.a * CoreColorConversion.rgbScale).round() &
      CoreColorConversion.alphaMax;

  @override
  int get blue =>
      (_primary.b * CoreColorConversion.rgbScale).round() &
      CoreColorConversion.rgbMax;

  @override
  int get green =>
      (_primary.g * CoreColorConversion.rgbScale).round() &
      CoreColorConversion.rgbMax;

  @override
  double get opacity => _primary.a;

  @override
  int get red =>
      (_primary.r * CoreColorConversion.rgbScale).round() &
      CoreColorConversion.rgbMax;

  @override
  int get value => _primary.toARGB32();

  @override
  double get a => _primary.a;

  @override
  double get b => _primary.b;

  @override
  ColorSpace get colorSpace => _primary.colorSpace;

  @override
  double get g => _primary.g;

  @override
  Iterable<dynamic> get keys => _colors.keys;

  @override
  double get r => _primary.r;
}
