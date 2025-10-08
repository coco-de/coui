import 'dart:collection';
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

Color _fromAHSL(double a, double h, double l, double s) {
  return HSLColor.fromAHSL(a, h, s, l).toColor();
}

class SingleChartColorScheme implements ChartColorScheme {
  const SingleChartColorScheme(this.color);

  final Color color;

  @override
  List<Color> get chartColors => [color, color, color, color, color];

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
  Color get chart2 => chartColors[1];
  Color get chart3 => chartColors[2];
  Color get chart4 => chartColors[3];
  Color get chart5 => chartColors[4];
}

class ColorShades implements Color, ColorSwatch {
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
    int base = 500,
    int hueShift = 0,
    int lightnessStepDown = 8,
    int lightnessStepUp = 9,
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
    int base = 500,
    int hueShift = 0,
    int lightnessStepDown = 8,
    int lightnessStepUp = 9,
    int saturationStepDown = 0,
    int saturationStepUp = 0,
  }) {
    assert(
      shadeValues.contains(base),
      'ColorShades.fromAccent: Invalid base value',
    );
    final slate = ColorShades._();
    for (final key in shadeValues) {
      final delta = (key - base) / _step;
      final hueDelta = delta * (hueShift / 10);
      final saturationDelta = delta > 0
          ? delta * saturationStepUp
          : delta * saturationStepDown;
      final lightnessDelta = delta > 0
          ? delta * lightnessStepUp
          : delta * lightnessStepDown;
      final h = (accent.hue + hueDelta) % 360;
      final s = (accent.saturation * 100 - saturationDelta).clamp(0, 100) / 100;
      final l = (accent.lightness * 100 - lightnessDelta).clamp(0, 100) / 100;
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
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    950,
  ];

  static const _step = 100;

  final Map<int, Color> _colors;

  static HSLColor shiftHSL(
    HSLColor hsv,
    int targetBase, {
    int base = 500,
    int hueShift = 0,
    int lightnessStepDown = 8,
    int lightnessStepUp = 9,
    int saturationStepDown = 0,
    int saturationStepUp = 0,
  }) {
    assert(
      shadeValues.contains(base),
      'ColorShades.fromAccent: Invalid base value',
    );
    final delta = (targetBase - base) / _step;
    final hueDelta = delta * (hueShift / 10);
    final saturationDelta = delta > 0
        ? delta * saturationStepUp
        : delta * saturationStepDown;
    final lightnessDelta = delta > 0
        ? delta * lightnessStepUp
        : delta * lightnessStepDown;
    final h = (hsv.hue + hueDelta) % 360;
    final s = (hsv.saturation * 100 - saturationDelta).clamp(0, 100) / 100;
    final l = (hsv.lightness * 100 - lightnessDelta).clamp(0, 100) / 100;
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
      final safe = (_colors[key]!.blue + delta).clamp(0, 255).toDouble();
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
      final safe = (_colors[key]!.green + delta).clamp(0, 255).toDouble();
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
      final safe = (_colors[key]!.red + delta).clamp(0, 255).toDouble();
      colors[key] = _colors[key]!.withRed(safe);
    }

    return ColorShades._direct(colors);
  }

  @override
  Color operator [](index) {
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
        blue: blue,
        colorSpace: colorSpace,
        green: green,
        red: red,
      );
    }

    return ColorShades._direct(colors);
  }

  @override
  int toARGB32() {
    return _primary.toARGB32();
  }

  Color get shade50 => _colors[50]!;
  Color get shade100 => _colors[100]!;

  Color get shade200 => _colors[200]!;

  Color get shade300 => _colors[300]!;

  Color get shade400 => _colors[400]!;

  Color get shade500 => _colors[500]!;

  Color get shade600 => _colors[600]!;

  Color get shade700 => _colors[700]!;

  Color get shade800 => _colors[800]!;

  Color get shade900 => _colors[900]!;

  Color get shade950 => _colors[950]!;

  Color get _primary => _colors[500]!;

  @override
  int get alpha => _primary.alpha;

  @override
  int get blue => _primary.blue;

  @override
  int get green => _primary.green;

  @override
  double get opacity => _primary.opacity;

  @override
  int get red => _primary.red;

  @override
  int get value => _primary.value;

  @override
  double get a => _primary.a;

  @override
  double get b => _primary.b;

  @override
  ColorSpace get colorSpace => _primary.colorSpace;

  @override
  double get g => _primary.g;

  @override
  Iterable get keys => _colors.keys;

  @override
  double get r => _primary.r;
}

String hexFromColor(Color color) {
  return '#${color.value.toRadixString(16).toUpperCase()}';
}

class ColorScheme implements ChartColorScheme {
  const ColorScheme({
    required this.accent,
    required this.accentForeground,
    required this.background,
    required this.border,
    required this.brightness,
    required this.card,
    required this.cardForeground,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.destructive,
    this.destructiveForeground = Colors.transparent,
    required this.foreground,
    required this.input,
    required this.muted,
    required this.mutedForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.ring,
    required this.secondary,
    required this.secondaryForeground,
    required this.sidebar,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarRing,
  });

  ColorScheme.fromMap(Map<String, dynamic> map)
    : background = map._col('background'),
      foreground = map._col('foreground'),
      card = map._col('card'),
      cardForeground = map._col('cardForeground'),
      popover = map._col('popover'),
      popoverForeground = map._col('popoverForeground'),
      primary = map._col('primary'),
      primaryForeground = map._col('primaryForeground'),
      secondary = map._col('secondary'),
      secondaryForeground = map._col('secondaryForeground'),
      muted = map._col('muted'),
      mutedForeground = map._col('mutedForeground'),
      accent = map._col('accent'),
      accentForeground = map._col('accentForeground'),
      destructive = map._col('destructive'),
      destructiveForeground = map._col('destructiveForeground'),
      border = map._col('border'),
      input = map._col('input'),
      ring = map._col('ring'),
      chart1 = map._col('chart1'),
      chart2 = map._col('chart2'),
      chart3 = map._col('chart3'),
      chart4 = map._col('chart4'),
      chart5 = map._col('chart5'),
      sidebar = map._col('sidebar'),
      sidebarForeground = map._col('sidebarForeground'),
      sidebarPrimary = map._col('sidebarPrimary'),
      sidebarPrimaryForeground = map._col('sidebarPrimaryForeground'),
      sidebarAccent = map._col('sidebarAccent'),
      sidebarAccentForeground = map._col('sidebarAccentForeground'),
      sidebarBorder = map._col('sidebarBorder'),
      sidebarRing = map._col('sidebarRing'),
      brightness =
          Brightness.values
              .where((element) => element.name == map['brightness'])
              .firstOrNull ??
          Brightness.light;

  ColorScheme.fromColors({
    required Brightness brightness,
    required Map<String, Color> colors,
  }) : this(
         accent: colors._col('accent'),
         accentForeground: colors._col('accentForeground'),
         background: colors._col('background'),
         border: colors._col('border'),
         brightness: brightness,
         card: colors._col('card'),
         cardForeground: colors._col('cardForeground'),
         chart1: colors._col('chart1'),
         chart2: colors._col('chart2'),
         chart3: colors._col('chart3'),
         chart4: colors._col('chart4'),
         chart5: colors._col('chart5'),
         destructive: colors._col('destructive'),
         destructiveForeground: colors._col('destructiveForeground'),
         foreground: colors._col('foreground'),
         input: colors._col('input'),
         muted: colors._col('muted'),
         mutedForeground: colors._col('mutedForeground'),
         popover: colors._col('popover'),
         popoverForeground: colors._col('popoverForeground'),
         primary: colors._col('primary'),
         primaryForeground: colors._col('primaryForeground'),
         ring: colors._col('ring'),
         secondary: colors._col('secondary'),
         secondaryForeground: colors._col('secondaryForeground'),
         sidebar: colors._col('sidebar'),
         sidebarAccent: colors._col('sidebarAccent'),
         sidebarAccentForeground: colors._col('sidebarAccentForeground'),
         sidebarBorder: colors._col('sidebarBorder'),
         sidebarForeground: colors._col('sidebarForeground'),
         sidebarPrimary: colors._col('sidebarPrimary'),
         sidebarPrimaryForeground: colors._col('sidebarPrimaryForeground'),
         sidebarRing: colors._col('sidebarRing'),
       );

  static const colorKeys = {
    'background',
    'foreground',
    'card',
    'cardForeground',
    'popover',
    'popoverForeground',
    'primary',
    'primaryForeground',
    'secondary',
    'secondaryForeground',
    'muted',
    'mutedForeground',
    'accent',
    'accentForeground',
    'destructive',
    'destructiveForeground',
    'border',
    'input',
    'ring',
    'chart1',
    'chart2',
    'chart3',
    'chart4',
    'chart5',
  };
  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  @Deprecated('Legacy color')
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;
  @override
  final Color chart1;
  @override
  final Color chart2;

  @override
  final Color chart3;

  @override
  final Color chart4;

  @override
  final Color chart5;

  Map<String, String> toMap() {
    return {
      'accent': hexFromColor(accent),
      'accentForeground': hexFromColor(accentForeground),
      'background': hexFromColor(background),
      'border': hexFromColor(border),
      'brightness': brightness.name,
      'card': hexFromColor(card),
      'cardForeground': hexFromColor(cardForeground),
      'chart1': hexFromColor(chart1),
      'chart2': hexFromColor(chart2),
      'chart3': hexFromColor(chart3),
      'chart4': hexFromColor(chart4),
      'chart5': hexFromColor(chart5),
      'destructive': hexFromColor(destructive),
      'destructiveForeground': hexFromColor(destructiveForeground),
      'foreground': hexFromColor(foreground),
      'input': hexFromColor(input),
      'muted': hexFromColor(muted),
      'mutedForeground': hexFromColor(mutedForeground),
      'popover': hexFromColor(popover),
      'popoverForeground': hexFromColor(popoverForeground),
      'primary': hexFromColor(primary),
      'primaryForeground': hexFromColor(primaryForeground),
      'ring': hexFromColor(ring),
      'secondary': hexFromColor(secondary),
      'secondaryForeground': hexFromColor(secondaryForeground),
      'sidebar': hexFromColor(sidebar),
      'sidebarAccent': hexFromColor(sidebarAccent),
      'sidebarAccentForeground': hexFromColor(sidebarAccentForeground),
      'sidebarBorder': hexFromColor(sidebarBorder),
      'sidebarForeground': hexFromColor(sidebarForeground),
      'sidebarPrimary': hexFromColor(sidebarPrimary),
      'sidebarPrimaryForeground': hexFromColor(sidebarPrimaryForeground),
      'sidebarRing': hexFromColor(sidebarRing),
    };
  }

  Map<String, Color> toColorMap() {
    return {
      'accent': accent,
      'accentForeground': accentForeground,
      'background': background,
      'border': border,
      'card': card,
      'cardForeground': cardForeground,
      'chart1': chart1,
      'chart2': chart2,
      'chart3': chart3,
      'chart4': chart4,
      'chart5': chart5,
      'destructive': destructive,
      'destructiveForeground': destructiveForeground,
      'foreground': foreground,
      'input': input,
      'muted': muted,
      'mutedForeground': mutedForeground,
      'popover': popover,
      'popoverForeground': popoverForeground,
      'primary': primary,
      'primaryForeground': primaryForeground,
      'ring': ring,
      'secondary': secondary,
      'secondaryForeground': secondaryForeground,
      'sidebar': sidebar,
      'sidebarAccent': sidebarAccent,
      'sidebarAccentForeground': sidebarAccentForeground,
      'sidebarBorder': sidebarBorder,
      'sidebarForeground': sidebarForeground,
      'sidebarPrimary': sidebarPrimary,
      'sidebarPrimaryForeground': sidebarPrimaryForeground,
      'sidebarRing': sidebarRing,
    };
  }

  ColorScheme copyWith({
    ValueGetter<Color>? accent,
    ValueGetter<Color>? accentForeground,
    ValueGetter<Color>? background,
    ValueGetter<Color>? border,
    ValueGetter<Brightness>? brightness,
    ValueGetter<Color>? card,
    ValueGetter<Color>? cardForeground,
    ValueGetter<Color>? chart1,
    ValueGetter<Color>? chart2,
    ValueGetter<Color>? chart3,
    ValueGetter<Color>? chart4,
    ValueGetter<Color>? chart5,
    ValueGetter<Color>? destructive,
    ValueGetter<Color>? destructiveForeground,
    ValueGetter<Color>? foreground,
    ValueGetter<Color>? input,
    ValueGetter<Color>? muted,
    ValueGetter<Color>? mutedForeground,
    ValueGetter<Color>? popover,
    ValueGetter<Color>? popoverForeground,
    ValueGetter<Color>? primary,
    ValueGetter<Color>? primaryForeground,
    ValueGetter<Color>? ring,
    ValueGetter<Color>? secondary,
    ValueGetter<Color>? secondaryForeground,
    ValueGetter<Color>? sidebar,
    ValueGetter<Color>? sidebarAccent,
    ValueGetter<Color>? sidebarAccentForeground,
    ValueGetter<Color>? sidebarBorder,
    ValueGetter<Color>? sidebarForeground,
    ValueGetter<Color>? sidebarPrimary,
    ValueGetter<Color>? sidebarPrimaryForeground,
    ValueGetter<Color>? sidebarRing,
  }) {
    return ColorScheme(
      accent: accent == null ? this.accent : accent(),
      accentForeground: accentForeground == null
          ? this.accentForeground
          : accentForeground(),
      background: background == null ? this.background : background(),
      border: border == null ? this.border : border(),
      brightness: brightness == null ? this.brightness : brightness(),
      card: card == null ? this.card : card(),
      cardForeground: cardForeground == null
          ? this.cardForeground
          : cardForeground(),
      chart1: chart1 == null ? this.chart1 : chart1(),
      chart2: chart2 == null ? this.chart2 : chart2(),
      chart3: chart3 == null ? this.chart3 : chart3(),
      chart4: chart4 == null ? this.chart4 : chart4(),
      chart5: chart5 == null ? this.chart5 : chart5(),
      destructive: destructive == null ? this.destructive : destructive(),
      destructiveForeground: destructiveForeground == null
          ? this.destructiveForeground
          : destructiveForeground(),
      foreground: foreground == null ? this.foreground : foreground(),
      input: input == null ? this.input : input(),
      muted: muted == null ? this.muted : muted(),
      mutedForeground: mutedForeground == null
          ? this.mutedForeground
          : mutedForeground(),
      popover: popover == null ? this.popover : popover(),
      popoverForeground: popoverForeground == null
          ? this.popoverForeground
          : popoverForeground(),
      primary: primary == null ? this.primary : primary(),
      primaryForeground: primaryForeground == null
          ? this.primaryForeground
          : primaryForeground(),
      ring: ring == null ? this.ring : ring(),
      secondary: secondary == null ? this.secondary : secondary(),
      secondaryForeground: secondaryForeground == null
          ? this.secondaryForeground
          : secondaryForeground(),
      sidebar: sidebar == null ? this.sidebar : sidebar(),
      sidebarAccent: sidebarAccent == null
          ? this.sidebarAccent
          : sidebarAccent(),
      sidebarAccentForeground: sidebarAccentForeground == null
          ? this.sidebarAccentForeground
          : sidebarAccentForeground(),
      sidebarBorder: sidebarBorder == null
          ? this.sidebarBorder
          : sidebarBorder(),
      sidebarForeground: sidebarForeground == null
          ? this.sidebarForeground
          : sidebarForeground(),
      sidebarPrimary: sidebarPrimary == null
          ? this.sidebarPrimary
          : sidebarPrimary(),
      sidebarPrimaryForeground: sidebarPrimaryForeground == null
          ? this.sidebarPrimaryForeground
          : sidebarPrimaryForeground(),
      sidebarRing: sidebarRing == null ? this.sidebarRing : sidebarRing(),
    );
  }

  static ColorScheme lerp(ColorScheme a, ColorScheme b, double t) {
    return ColorScheme(
      accent: Color.lerp(a.accent, b.accent, t)!,
      accentForeground: Color.lerp(a.accentForeground, b.accentForeground, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      brightness: t < 0.5 ? a.brightness : b.brightness,
      card: Color.lerp(a.card, b.card, t)!,
      cardForeground: Color.lerp(a.cardForeground, b.cardForeground, t)!,
      chart1: Color.lerp(a.chart1, b.chart1, t)!,
      chart2: Color.lerp(a.chart2, b.chart2, t)!,
      chart3: Color.lerp(a.chart3, b.chart3, t)!,
      chart4: Color.lerp(a.chart4, b.chart4, t)!,
      chart5: Color.lerp(a.chart5, b.chart5, t)!,
      destructive: Color.lerp(a.destructive, b.destructive, t)!,
      destructiveForeground: Color.lerp(
        a.destructiveForeground,
        b.destructiveForeground,
        t,
      )!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      input: Color.lerp(a.input, b.input, t)!,
      muted: Color.lerp(a.muted, b.muted, t)!,
      mutedForeground: Color.lerp(a.mutedForeground, b.mutedForeground, t)!,
      popover: Color.lerp(a.popover, b.popover, t)!,
      popoverForeground: Color.lerp(
        a.popoverForeground,
        b.popoverForeground,
        t,
      )!,
      primary: Color.lerp(a.primary, b.primary, t)!,
      primaryForeground: Color.lerp(
        a.primaryForeground,
        b.primaryForeground,
        t,
      )!,
      ring: Color.lerp(a.ring, b.ring, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      secondaryForeground: Color.lerp(
        a.secondaryForeground,
        b.secondaryForeground,
        t,
      )!,
      sidebar: Color.lerp(a.sidebar, b.sidebar, t)!,
      sidebarAccent: Color.lerp(a.sidebarAccent, b.sidebarAccent, t)!,
      sidebarAccentForeground: Color.lerp(
        a.sidebarAccentForeground,
        b.sidebarAccentForeground,
        t,
      )!,
      sidebarBorder: Color.lerp(a.sidebarBorder, b.sidebarBorder, t)!,
      sidebarForeground: Color.lerp(
        a.sidebarForeground,
        b.sidebarForeground,
        t,
      )!,
      sidebarPrimary: Color.lerp(a.sidebarPrimary, b.sidebarPrimary, t)!,
      sidebarPrimaryForeground: Color.lerp(
        a.sidebarPrimaryForeground,
        b.sidebarPrimaryForeground,
        t,
      )!,
      sidebarRing: Color.lerp(a.sidebarRing, b.sidebarRing, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorScheme &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          background == other.background &&
          foreground == other.foreground &&
          card == other.card &&
          cardForeground == other.cardForeground &&
          popover == other.popover &&
          popoverForeground == other.popoverForeground &&
          primary == other.primary &&
          primaryForeground == other.primaryForeground &&
          secondary == other.secondary &&
          secondaryForeground == other.secondaryForeground &&
          muted == other.muted &&
          mutedForeground == other.mutedForeground &&
          accent == other.accent &&
          accentForeground == other.accentForeground &&
          destructive == other.destructive &&
          destructiveForeground == other.destructiveForeground &&
          border == other.border &&
          input == other.input &&
          ring == other.ring &&
          chart1 == other.chart1 &&
          chart2 == other.chart2 &&
          chart3 == other.chart3 &&
          chart4 == other.chart4 &&
          chart5 == other.chart5 &&
          sidebar == other.sidebar &&
          sidebarForeground == other.sidebarForeground &&
          sidebarPrimary == other.sidebarPrimary &&
          sidebarPrimaryForeground == other.sidebarPrimaryForeground &&
          sidebarAccent == other.sidebarAccent &&
          sidebarAccentForeground == other.sidebarAccentForeground &&
          sidebarBorder == other.sidebarBorder &&
          sidebarRing == other.sidebarRing;

  @override
  String toString() {
    return 'ColorScheme{brightness: $brightness, background: $background, foreground: $foreground, card: $card, cardForeground: $cardForeground, popover: $popover, popoverForeground: $popoverForeground, primary: $primary, primaryForeground: $primaryForeground, secondary: $secondary, secondaryForeground: $secondaryForeground, muted: $muted, mutedForeground: $mutedForeground, accent: $accent, accentForeground: $accentForeground, destructive: $destructive, destructiveForeground: $destructiveForeground, border: $border, input: $input, ring: $ring, chart1: $chart1, chart2: $chart2, chart3: $chart3, chart4: $chart4, chart5: $chart5, sidebar: $sidebar, sidebarForeground: $sidebarForeground, sidebarPrimary: $sidebarPrimary, sidebarPrimaryForeground: $sidebarPrimaryForeground, sidebarAccent: $sidebarAccent, sidebarAccentForeground: $sidebarAccentForeground, sidebarBorder: $sidebarBorder, sidebarRing: $sidebarRing}';
  }

  @override
  List<Color> get chartColors => [chart1, chart2, chart3, chart4, chart5];

  @override
  int get hashCode => Object.hash(
    Object.hash(
      brightness,
      background,
      foreground,
      card,
      cardForeground,
      popover,
      popoverForeground,
      primary,
      primaryForeground,
      secondary,
      secondaryForeground,
      muted,
      mutedForeground,
      accent,
      accentForeground,
      destructive,
      destructiveForeground,
      border,
      input,
      ring,
    ),
    Object.hash(
      chart1,
      chart2,
      chart3,
      chart4,
      chart5,
      sidebar,
      sidebarForeground,
      sidebarPrimary,
      sidebarPrimaryForeground,
      sidebarAccent,
      sidebarAccentForeground,
      sidebarBorder,
      sidebarRing,
    ),
  );
}

extension _MapColorGetter on Map<String, Color> {
  Color _col(String name) {
    final color = this[name];
    assert(color != null, 'ColorScheme: Missing color for $name');

    return color!;
  }
}

extension _DynamicMapColorGetter on Map<String, dynamic> {
  Color _col(String name) {
    String? value = this[name];
    assert(value != null, 'ColorScheme: Missing color for $name');
    if (value!.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parse = int.tryParse(value, radix: 16);
    assert(parse != null, 'ColorScheme: Invalid hex color value $value');

    return Color(parse!);
  }
}
