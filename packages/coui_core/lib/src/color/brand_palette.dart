import 'dart:math' as math;

import 'package:coui_core/src/color/color_contrast.dart';
import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/color_difference.dart';
import 'package:coui_core/src/color/color_presets.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/coui_palette.dart';
import 'package:coui_core/src/color/coui_semantic_mapping.dart';
import 'package:coui_core/src/color/primary_container_gap.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// Which colour goes on the brand's primary fill in light mode.
///
/// The CTA rule measures it ([measured]): white whenever white reaches
/// 4.5:1 on the fill, otherwise whichever of white and the ramp's `1000`
/// reads better. A brand whose designer has chosen the
/// text colour states it instead — the rule's hover / pressed walk then
/// follows the stated text (darker under white, lighter under `1000`), the
/// same walk the measurement would have chosen. Only light mode reads this;
/// dark and the high-contrast modes keep the rule's own on-colours.
enum CoreBrandOnFill {
  /// White when white reaches 4.5:1 on the fill, even where `1000` would
  /// measure higher; otherwise white or `1000`, whichever has the higher
  /// contrast.
  measured,

  /// White, whatever the measurement says.
  white,

  /// The ramp's `1000`, whatever the measurement says.
  darkest,
}

/// A brand's palette generated from one brand colour on CoUI's step scale.
///
/// The rule is the designer's (the CoUI Brand Color Generator plugin's
/// engine); the code is its source of truth, so the plugin, the apps and the
/// Figma export all read one result.
///
/// - **Primary ramp.** Steps `100` … `1000`, each with the relative
///   luminance of the CoUI neutral at the same number — so a step clears the
///   same contrast bars against white whatever the hue (`500` 3:1, `600`
///   4.5:1). Hue stays the brand's; chroma follows [chromaProfile] scaled to
///   the brand colour, capped at the most saturated in-gamut sRGB value. Warm
///   hues (orange, yellow) lean redder as they darken and yellower as they
///   lighten, the way pigments of those hues do.
/// - **The brand colour itself.** It lands on the step whose luminance is
///   nearest ([anchorStep]) and, when [keepsBrandColor] is set, takes that
///   step exactly — the brand's own hex is a step of the ramp.
/// - **Everything else is CoUI's.** Neutral and the four status ramps are
///   read from the base palette (CoUI's fixed palette unless stated). A
///   status ramp whose `600` sits within [collisionDeltaE] of the brand
///   colour turns its hue away from the brand, inside the hue band that still
///   reads as that status ([statusHueBands]), and is re-solved at the same
///   step luminances.
///
/// Read through [CoreBrandSchemeSource]: CoUI's semantic mapping for every
/// shared slot, and the CTA rule for the primary family.
@immutable
final class CoreBrandPalette {
  const CoreBrandPalette._({
    required this.brandColor,
    required this.keepsBrandColor,
    required this.primary,
    required this.anchorStep,
    required this.palette,
    required this.statusShifts,
    required this.onLightFill,
  });

  /// Generates the palette for [brandColor] on top of [base].
  ///
  /// [keepsBrandColor] puts [brandColor] itself on [anchorStep] (the default
  /// — the plugin's "원본 색 유지"); off, the step takes the rule's solved
  /// value. [correctsStatus] turns status ramps away from a colliding brand
  /// colour; off, every status ramp is [base]'s. [onLightFill] states the
  /// light-mode text on the primary fill instead of measuring it.
  factory CoreBrandPalette.generate(
    CoreColor brandColor, {
    CouiPalette base = CouiColorPresets.palette,
    bool keepsBrandColor = true,
    bool correctsStatus = true,
    CoreBrandOnFill onLightFill = CoreBrandOnFill.measured,
  }) {
    final brand = CoreColor(brandColor.argb | _kOpaque);
    final targets = _Targets(base.neutral);
    final (:ramp, :step) = _makeRamp(
      brand,
      targets,
      keepsBrandColor: keepsBrandColor,
    );
    final shifts = <String, double>{};
    final brandSteps = (anchor: ramp[step]!, s600: ramp[600]!);
    CouiStatusRamp statusRamp(String name, CouiStatusRamp source) {
      if (!correctsStatus) return source;
      final shift = _statusShift(
        name,
        source,
        brand: brandSteps,
        targets: targets,
      );
      if (shift == 0) return source;
      shifts[name] = shift;

      return _shiftStatusRamp(source, shift, targets);
    }

    return CoreBrandPalette._(
      brandColor: brand,
      keepsBrandColor: keepsBrandColor,
      primary: CouiToneRamp(
        s100: ramp[100]!,
        s200: ramp[200]!,
        s300: ramp[300]!,
        s400: ramp[400]!,
        s500: ramp[500]!,
        s600: ramp[600]!,
        s700: ramp[700]!,
        s800: ramp[800]!,
        s900: ramp[900]!,
        s1000: ramp[1000]!,
      ),
      anchorStep: step,
      palette: CouiPalette(
        neutral: base.neutral,
        success: statusRamp('success', base.success),
        info: statusRamp('info', base.info),
        warning: statusRamp('warning', base.warning),
        error: statusRamp('error', base.error),
        white: base.white,
        black: base.black,
      ),
      statusShifts: Map.unmodifiable(shifts),
      onLightFill: onLightFill,
    );
  }

  /// The brand colour the palette was generated from (opaque).
  final CoreColor brandColor;

  /// Whether [brandColor] itself sits on [anchorStep].
  final bool keepsBrandColor;

  /// The brand's primary ramp, `100` … `1000`.
  final CouiToneRamp primary;

  /// The step [brandColor] landed on — the step whose CoUI luminance is
  /// nearest to the brand colour's. The CTA rule reads its fills from here.
  final int anchorStep;

  /// CoUI's palette with the brand's status corrections applied — the
  /// palette every shared semantic slot reads.
  final CouiPalette palette;

  /// The hue turn, in degrees, applied to each status ramp the brand
  /// collided with — keyed by status family (`success`, `info`, `warning`,
  /// `error`). A family absent here is [palette]'s unchanged.
  final Map<String, double> statusShifts;

  /// The light-mode text on the primary fill — measured by the CTA rule
  /// unless the brand states it.
  final CoreBrandOnFill onLightFill;

  /// The ramp steps, ascending.
  static const List<int> steps = [
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
  ];

  /// The share of the ramp's peak chroma each step takes — the shape of
  /// a blue-grey ramp, fullest at `700`.
  static const Map<int, double> chromaProfile = {
    100: 0.15,
    200: 0.33,
    300: 0.52,
    400: 0.76,
    500: 0.90,
    600: 0.98,
    700: 1.0,
    800: 0.97,
    900: 0.83,
    1000: 0.64,
  };

  /// The highest peak chroma (OKLch) a ramp may take.
  static const double maxPeakChroma = 0.32;

  /// Below this CIEDE2000 difference from the brand colour a status colour
  /// counts as colliding with it.
  static const double collisionDeltaE = 15;

  /// The OKLch hue band each status family must stay inside when it turns
  /// away from the brand — outside it the colour stops reading as that
  /// status.
  static const Map<String, (double, double)> statusHueBands = {
    'success': (130, 170),
    'info': (222, 268),
    'warning': (50, 92),
    'error': (14, 36),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreBrandPalette &&
          brandColor == other.brandColor &&
          keepsBrandColor == other.keepsBrandColor &&
          onLightFill == other.onLightFill &&
          palette == other.palette);

  @override
  int get hashCode =>
      Object.hash(brandColor, keepsBrandColor, onLightFill, palette);
}

/// [CoreBrandPalette] read as a colour source.
///
/// Every shared slot — surfaces, text, outlines, status, secondary — is
/// [CouiSemanticMapping]'s, over the palette with the brand's status
/// corrections. The primary family (fill, on-colour, hover, pressed,
/// container, fixed, text, inverse, focus ring, surface tint) follows the
/// CTA rule from the brand's [CoreBrandPalette.anchorStep], and the tertiary
/// family restates primary as CoUI's does.
///
/// High contrast keeps the [CoreSchemeSource] invariant the CoUI source
/// keeps: the four builders are complete tables, and [raiseContrast] lays
/// over a base only the slots where the high-contrast table differs from the
/// normal one.
@immutable
final class CoreBrandSchemeSource implements CoreSchemeSource {
  /// Creates a [CoreBrandSchemeSource] from a generated [palette].
  const CoreBrandSchemeSource(this.palette);

  /// Generates the palette for [brandColor] and reads it — the one-call
  /// path a brand registered by colour takes. [onLightFill] is passed to
  /// [CoreBrandPalette.generate].
  ///
  /// Results are kept per colour and [onLightFill], since a palette is a
  /// pure function of the two and a theme seat may ask for the source many
  /// times.
  factory CoreBrandSchemeSource.fromColor(
    CoreColor brandColor, {
    CoreBrandOnFill onLightFill = CoreBrandOnFill.measured,
  }) => _cache.putIfAbsent(
    (brandColor.argb | _kOpaque, onLightFill),
    () => CoreBrandSchemeSource(
      CoreBrandPalette.generate(brandColor, onLightFill: onLightFill),
    ),
  );

  static final Map<(int, CoreBrandOnFill), CoreBrandSchemeSource> _cache = {};

  /// The generated palette this source reads.
  final CoreBrandPalette palette;

  @override
  CoreColorScheme light() => _table(_Mode.light);

  @override
  CoreColorScheme dark() => _table(_Mode.dark);

  @override
  CoreColorScheme highContrastLight() =>
      raiseContrast(light(), CoreBrightness.light);

  @override
  CoreColorScheme highContrastDark() =>
      raiseContrast(dark(), CoreBrightness.dark);

  @override
  CoreColorScheme raiseContrast(
    CoreColorScheme base,
    CoreBrightness brightness,
  ) => brightness == CoreBrightness.dark
      ? CoreColorScheme.raiseByDelta(
          base,
          normal: dark(),
          raised: _table(_Mode.highContrastDark),
        )
      : CoreColorScheme.raiseByDelta(
          base,
          normal: light(),
          raised: _table(_Mode.highContrastLight),
        );

  /// CoUI's primitives with the brand's primary ramp after neutral
  /// (`primary/100` … `primary/1000`) and its corrected status ramps in
  /// place of CoUI's.
  @override
  Map<String, CoreColor> get primitives {
    final shared = palette.palette.primitives;
    final primary = {
      for (final step in palette.primary.steps.entries)
        'primary/${step.key}': step.value,
    };

    return {
      for (final entry in shared.entries)
        if (entry.key.startsWith('neutral/')) entry.key: entry.value,
      ...primary,
      for (final entry in shared.entries)
        if (!entry.key.startsWith('neutral/')) entry.key: entry.value,
    };
  }

  CoreColorScheme _table(_Mode mode) {
    final coui = palette.palette;
    final shared = switch (mode) {
      _Mode.light => CouiSemanticMapping.light(coui),
      _Mode.dark => CouiSemanticMapping.dark(coui),
      _Mode.highContrastLight => CouiSemanticMapping.highContrastLight(coui),
      _Mode.highContrastDark => CouiSemanticMapping.highContrastDark(coui),
    };
    final rows = _CtaRows(palette);
    CoreColor p(_Row row) => rows.color(row, mode);
    final container = _container(
      mode,
      shared.surface ?? palette.palette.white,
      rows,
    );

    return shared.copyWith(
      surfaceTint: p(_Row.fill),
      primary: p(_Row.fill),
      onPrimary: p(_Row.on),
      primaryHover: p(_Row.hover),
      primaryPressed: p(_Row.pressed),
      primaryContainer: container,
      onPrimaryContainer: p(_Row.onContainer),
      primaryFixed: p(_Row.fixed),
      primaryFixedDim: p(_Row.fixedDim),
      onPrimaryFixed: p(_Row.onFixed),
      onPrimaryFixedVariant: p(_Row.onFixedVariant),
      primaryText: p(_Row.text),
      primaryTextLarge: p(_Row.textLarge),
      inversePrimary: p(_Row.inverse),
      focusRing: p(_Row.focus),
      tertiary: p(_Row.fill),
      onTertiary: p(_Row.on),
      tertiaryContainer: container,
      onTertiaryContainer: p(_Row.onContainer),
      tertiaryFixed: p(_Row.fixed),
      tertiaryFixedDim: p(_Row.fixedDim),
      onTertiaryFixed: p(_Row.onFixed),
      onTertiaryFixedVariant: p(_Row.onFixedVariant),
    );
  }

  // The CTA rule's container step, moved away from the page when it melts
  // into it — the gap contract every brand mapping keeps
  // (`CorePrimaryContainerGap`), in all four modes. In the high-contrast
  // modes a move also has to keep the text on the face at the
  // high-contrast bar.
  CoreColor _container(_Mode mode, CoreColor surface, _CtaRows rows) {
    final ramp = palette.primary.steps;
    final dark = mode == _Mode.dark || mode == _Mode.highContrastDark;
    final ladder = dark
        ? [ramp[900]!, ramp[800]!, ramp[700]!]
        : [ramp[100]!, ramp[200]!, ramp[300]!];

    return CorePrimaryContainerGap.pick(
      ladder,
      surface: surface,
      onContainer: rows.color(_Row.onContainer, mode),
      primaryText: rows.color(_Row.text, mode),
      brightness: dark ? CoreBrightness.dark : CoreBrightness.light,
      highContrast:
          mode == _Mode.highContrastLight || mode == _Mode.highContrastDark,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreBrandSchemeSource && palette == other.palette);

  @override
  int get hashCode => palette.hashCode;
}

enum _Mode { light, dark, highContrastLight, highContrastDark }

enum _Row {
  fill,
  on,
  hover,
  pressed,
  onContainer,
  fixed,
  fixedDim,
  onFixed,
  onFixedVariant,
  text,
  textLarge,
  focus,
  inverse,
}

/// The CTA rule (the plugin's R1–R5) as one row per slot and mode.
///
/// From the anchor step `k`: light fills `k` and walks one / two steps for
/// hover / pressed — darker under white text, lighter under dark text,
/// except where the ramp's end turns the walk back. Dark fills
/// `min(k, 400)` and walks toward the middle. High-contrast light fills at
/// least `800`; high-contrast dark fills `200`. White or the ramp's `1000`
/// goes on the light fill, whichever reads better — unless the brand states
/// it ([CoreBrandPalette.onLightFill]).
final class _CtaRows {
  _CtaRows(CoreBrandPalette brand)
    : _ramp = brand.primary.steps,
      _white = brand.palette.white,
      _black = brand.palette.black {
    final k = brand.anchorStep;
    final whiteText = k >= _kWhiteTextFrom;
    var lightHover = 0;
    var lightPressed = 0;
    if (whiteText) {
      if (k <= 800) {
        lightHover = k + _kStep;
        lightPressed = k + 2 * _kStep;
      } else if (k == 900) {
        lightHover = 1000;
        lightPressed = 800;
      } else {
        lightHover = 900;
        lightPressed = 800;
      }
    } else if (k <= 300) {
      lightHover = k + _kStep;
      lightPressed = k + 2 * _kStep;
    } else {
      lightHover = k - _kStep;
      lightPressed = k - 2 * _kStep;
    }
    final darkFill = math.min(k, _kDarkFillMax);
    final darkHover = darkFill > 200 ? darkFill - _kStep : darkFill + _kStep;
    final darkPressed = darkFill > 200
        ? darkFill - 2 * _kStep
        : darkFill + 2 * _kStep;
    final hcFill = math.max(k, _kHighContrastFillMin);
    var hcHover = hcFill <= 900 ? hcFill + _kStep : 900;
    var hcPressed = hcFill <= 800 ? hcFill + 2 * _kStep : 800;
    if (hcFill == 1000) {
      hcHover = 900;
      hcPressed = 800;
    }
    var focusLight = k < 500 ? 600 : k;

    // Measured on the ramp: the on-colour is white once white reaches body
    // contrast on the light fill, otherwise whichever of white and `1000`
    // reads better, and the walk follows the text.
    final fill = _ramp[k]!;
    final onWhite = CoreContrast.ratio(fill, _white);
    final onDarkest = CoreContrast.ratio(fill, _ramp[1000]!);
    final lightOnIsWhite = switch (brand.onLightFill) {
      CoreBrandOnFill.measured => onWhite >= _kBodyText || onWhite >= onDarkest,
      CoreBrandOnFill.white => true,
      CoreBrandOnFill.darkest => false,
    };
    if (!lightOnIsWhite && k >= 400) {
      lightHover = k - _kStep;
      lightPressed = k - 2 * _kStep;
    }
    if (lightOnIsWhite && k <= 500) {
      lightHover = k + _kStep;
      lightPressed = k + 2 * _kStep;
    }
    if (onWhite < _kNonText) focusLight = 600;

    _steps = {
      _Row.fill: (k, darkFill, hcFill, 200),
      _Row.hover: (lightHover, darkHover, hcHover, 100),
      _Row.pressed: (lightPressed, darkPressed, hcPressed, 300),
      _Row.onContainer: (800, 100, 1000, null),
      _Row.fixed: (200, 200, 200, 200),
      _Row.fixedDim: (300, 300, 300, 300),
      _Row.onFixed: (1000, 1000, 1000, 1000),
      _Row.onFixedVariant: (800, 800, 800, 800),
      _Row.text: (700, 300, 900, 100),
      _Row.textLarge: (600, 400, 800, 200),
      _Row.focus: (focusLight, darkFill, hcFill, 200),
      _Row.inverse: (300, 700, 200, 800),
    };
    _lightOnIsWhite = lightOnIsWhite;
  }

  final Map<int, CoreColor> _ramp;
  final CoreColor _white;
  final CoreColor _black;
  late final Map<_Row, (int, int, int, int?)> _steps;
  late final bool _lightOnIsWhite;

  CoreColor color(_Row row, _Mode mode) {
    if (row == _Row.on) {
      return switch (mode) {
        _Mode.light => _lightOnIsWhite ? _white : _ramp[1000]!,
        _Mode.dark => _ramp[1000]!,
        _Mode.highContrastLight => _white,
        _Mode.highContrastDark => _black,
      };
    }
    final (light, dark, hcLight, hcDark) = _steps[row]!;
    final step = switch (mode) {
      _Mode.light => light,
      _Mode.dark => dark,
      _Mode.highContrastLight => hcLight,
      _Mode.highContrastDark => hcDark,
    };

    // `null` in the high-contrast dark column is white — the on-container
    // text of the darkest face.
    return step == null ? _white : _ramp[step]!;
  }
}

/// The luminance each step targets — the CoUI neutral at the same number.
final class _Targets {
  _Targets(CouiNeutralRamp neutral)
    : byStep = {
        for (final entry in neutral.steps.entries)
          entry.key: CoreContrast.relativeLuminance(entry.value),
      };

  final Map<int, double> byStep;
}

({Map<int, CoreColor> ramp, int step}) _makeRamp(
  CoreColor brand,
  _Targets targets, {
  required bool keepsBrandColor,
}) {
  final o = CoreColorConversion.colorToOKLch(brand);
  final k = _nearestStep(brand, targets);
  final peak = math.min(
    CoreBrandPalette.maxPeakChroma,
    o.c / CoreBrandPalette.chromaProfile[k]!,
  );
  final warm = o.h >= 35 && o.h <= 115 && o.c > 0.04;
  final ramp = <int, CoreColor>{};
  for (final s in CoreBrandPalette.steps) {
    var hue = o.h;
    if (warm && s != k) {
      final t = s < k
          ? (k - s) / math.max(100, k - 100)
          : (s - k) / math.max(100, 1000 - k);
      hue = s < k ? o.h + (o.h < 80 ? 8 : 0) * t : o.h - 18 * t;
    }
    ramp[s] = _solveStep(
      targets.byStep[s]!,
      peak * CoreBrandPalette.chromaProfile[s]!,
      hue,
    );
  }
  if (keepsBrandColor) ramp[k] = brand;

  return (ramp: ramp, step: k);
}

int _nearestStep(CoreColor color, _Targets targets) {
  final y = CoreContrast.relativeLuminance(color);
  var best = CoreBrandPalette.steps.first;
  var bestDistance = double.infinity;
  for (final s in CoreBrandPalette.steps) {
    final distance = math
        .log((y + _kFlare) / (targets.byStep[s]! + _kFlare))
        .abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = s;
    }
  }

  return best;
}

// The colour at [targetY] luminance, hue [hue], chroma as close to
// [chroma] as the gamut allows — bisected on OKLch lightness.
CoreColor _solveStep(double targetY, double chroma, double hue) {
  var lo = 0.05;
  var hi = 0.995;
  var color = const CoreColor(_kOpaque);
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    final c = _fitChroma(mid, chroma, hue);
    color = CoreColorConversion.oklchToColor(mid, c, hue);
    if (CoreContrast.relativeLuminance(color) < targetY) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  return color;
}

double _fitChroma(double l, double c, double h) {
  if (CoreColorConversion.isInSrgbGamut(l, c, h)) return c;
  var lo = 0.0;
  var hi = c;
  for (var i = 0; i < 28; i++) {
    final mid = (lo + hi) / 2;
    if (CoreColorConversion.isInSrgbGamut(l, mid, h)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  return lo;
}

// The plugin scores a status against the brand colour on its anchor step
// and, with a 5-point allowance, against the brand's `600`.
double _collision(
  CoreColor status600,
  ({CoreColor anchor, CoreColor s600}) brand,
) => math.min(
  CoreColorDifference.ciede2000(brand.anchor, status600),
  CoreColorDifference.ciede2000(brand.s600, status600) + 5,
);

// The hue turn (degrees) for one status ramp, or 0 when it does not
// collide or no turn inside its band helps.
double _statusShift(
  String name,
  CouiStatusRamp ramp, {
  required ({CoreColor anchor, CoreColor s600}) brand,
  required _Targets targets,
}) {
  if (_collision(ramp.s600, brand) >= CoreBrandPalette.collisionDeltaE) {
    return 0;
  }
  final statusHue = CoreColorConversion.colorToOKLch(ramp.s600).h;
  final brandHue = CoreColorConversion.colorToOKLch(brand.anchor).h;
  final (low, high) = CoreBrandPalette.statusHueBands[name]!;
  // Away from the brand hue.
  final direction = ((statusHue - brandHue + 540) % 360) - 180 >= 0 ? 1 : -1;
  var best = 0.0;
  for (var degrees = 4; degrees <= 40; degrees += 2) {
    final hue = (statusHue + direction * degrees + 360) % 360;
    if (hue < low || hue > high) break;
    final shift = (direction * degrees).toDouble();
    best = shift;
    final candidate = _shiftedStep(ramp.s600, 600, shift, targets);
    if (_collision(candidate, brand) >= CoreBrandPalette.collisionDeltaE) {
      break;
    }
  }

  return best;
}

CoreColor _shiftedStep(
  CoreColor color,
  int step,
  double shift,
  _Targets targets,
) {
  final o = CoreColorConversion.colorToOKLch(color);

  return _solveStep(targets.byStep[step]!, o.c, (o.h + shift + 360) % 360);
}

CouiStatusRamp _shiftStatusRamp(
  CouiStatusRamp ramp,
  double shift,
  _Targets targets,
) {
  CoreColor at(int step) =>
      _shiftedStep(ramp.steps[step]!, step, shift, targets);

  return CouiStatusRamp(
    s100: at(100),
    s200: at(200),
    s300: at(300),
    s400: at(400),
    s500: at(500),
    s600: at(600),
    s700: at(700),
    s800: at(800),
    s900: at(900),
    s950: at(950),
    s1000: at(1000),
  );
}

const int _kOpaque = 0xFF000000;
const int _kStep = 100;
// From this anchor step on the rule puts white on the light fill.
const int _kWhiteTextFrom = 600;
const int _kDarkFillMax = 400;
const int _kHighContrastFillMin = 800;
const double _kBodyText = 4.5;
const double _kNonText = 3;
const double _kFlare = 0.05;
