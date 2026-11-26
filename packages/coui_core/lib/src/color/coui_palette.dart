import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

/// CoUI's neutral ramp — fifteen fixed steps from `50` to `1050`.
///
/// Fixed hex rather than a generated scale: the steps are an OKLCH ladder
/// the designer authored once (hue 255 at chroma 0.0025 — a grey with no
/// visible cast), and every CoUI ramp meets the legibility bars at this
/// one's step numbers — `600` is the body-text step (4.5:1 or more on
/// white), `500` the UI-boundary step (3:1 or more).
/// `PrimitiveColors` computes its seven steps from an HSL seed, so the
/// shape cannot be carried by that type; brands keep using it unchanged.
///
/// The three in-between steps (`150`, `850`, `950`) exist only here: they
/// are the surface-container rungs the light and dark pages climb.
@immutable
final class CouiNeutralRamp {
  /// Creates a [CouiNeutralRamp].
  const CouiNeutralRamp({
    required this.s50,
    required this.s100,
    required this.s150,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s850,
    required this.s900,
    required this.s950,
    required this.s1000,
    required this.s1050,
  });

  /// Step `50` — the lightest neutral.
  final CoreColor s50;

  /// Step `100`.
  final CoreColor s100;

  /// Step `150`.
  final CoreColor s150;

  /// Step `200`.
  final CoreColor s200;

  /// Step `300`.
  final CoreColor s300;

  /// Step `400`.
  final CoreColor s400;

  /// Step `500` — the UI-boundary step (3:1 on white).
  final CoreColor s500;

  /// Step `600` — the body-text step (~4.7:1 on white).
  final CoreColor s600;

  /// Step `700`.
  final CoreColor s700;

  /// Step `800`.
  final CoreColor s800;

  /// Step `850`.
  final CoreColor s850;

  /// Step `900`.
  final CoreColor s900;

  /// Step `950`.
  final CoreColor s950;

  /// Step `1000` — the dark page.
  final CoreColor s1000;

  /// Step `1050` — the darkest neutral.
  final CoreColor s1050;

  /// Every step keyed by its number, ascending — the emit order of the
  /// primitive vocabulary.
  Map<int, CoreColor> get steps => {
    50: s50,
    100: s100,
    150: s150,
    200: s200,
    300: s300,
    400: s400,
    500: s500,
    600: s600,
    700: s700,
    800: s800,
    850: s850,
    900: s900,
    950: s950,
    1000: s1000,
    1050: s1050,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouiNeutralRamp && _sameSteps(steps, other.steps));

  @override
  int get hashCode => Object.hashAll(steps.values);
}

/// One CoUI tone ramp — the hundreds from `100` to `1000`.
///
/// The four status families extend it with dark-only steps
/// ([CouiStatusRamp]). The legibility bars sit at the same step numbers as
/// the neutral ramp's —
/// `500` clears 3:1 against white (the UI-boundary step) and `600` clears
/// 4.5:1 (the body-text step) — so swapping a neutral for a status colour
/// at the same step keeps it on the same side of each bar.
@immutable
final class CouiToneRamp {
  /// Creates a [CouiToneRamp].
  const CouiToneRamp({
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s900,
    required this.s1000,
  });

  /// Step `100` — the lightest tone.
  final CoreColor s100;

  /// Step `200`.
  final CoreColor s200;

  /// Step `300`.
  final CoreColor s300;

  /// Step `400`.
  final CoreColor s400;

  /// Step `500`.
  final CoreColor s500;

  /// Step `600`.
  final CoreColor s600;

  /// Step `700`.
  final CoreColor s700;

  /// Step `800`.
  final CoreColor s800;

  /// Step `900`.
  final CoreColor s900;

  /// Step `1000` — the darkest tone.
  final CoreColor s1000;

  /// Every step keyed by its number, ascending — the emit order of the
  /// primitive vocabulary.
  Map<int, CoreColor> get steps => {
    100: s100,
    200: s200,
    300: s300,
    400: s400,
    500: s500,
    600: s600,
    700: s700,
    800: s800,
    900: s900,
    1000: s1000,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouiToneRamp && _sameSteps(steps, other.steps));

  @override
  int get hashCode => Object.hashAll(steps.values);
}

/// One CoUI status ramp — the [CouiToneRamp] hundreds plus [s950], the
/// dark container step. All four status families (`success`, `info`,
/// `warning`, `error`) have these same eleven steps.
///
/// [s950] sits between `900` and `1000` by lightness and is lower in chroma
/// than either; the dark `*Container` slots read it. A `900` container was
/// saturated enough to pull the eye ahead of the content on the dark page
/// — a removed line in a code diff read as an alarm — so a status's dark
/// surface gets a step of its own instead of reusing a light one, as Radix
/// Colors and Primer keep theirs. The in-between steps follow the neutral
/// ramp's naming: the number states where the lightness sits.
///
/// Equality and hash read [steps], so every added step is compared.
@immutable
final class CouiStatusRamp extends CouiToneRamp {
  /// Creates a [CouiStatusRamp].
  const CouiStatusRamp({
    required super.s100,
    required super.s200,
    required super.s300,
    required super.s400,
    required super.s500,
    required super.s600,
    required super.s700,
    required super.s800,
    required super.s900,
    required this.s950,
    required super.s1000,
  });

  /// Step `950` — the dark container step.
  final CoreColor s950;

  @override
  Map<int, CoreColor> get steps => {
    100: s100,
    200: s200,
    300: s300,
    400: s400,
    500: s500,
    600: s600,
    700: s700,
    800: s800,
    900: s900,
    950: s950,
    1000: s1000,
  };
}

/// CoUI's fixed-hex primitive palette.
///
/// The code is the source of truth for these values. They were translated
/// once from the designer's token export; edits flow code → Figma (the
/// exporter publishes them), never the other way, so there is no second
/// copy to keep in step.
///
/// There is no `primary`, `secondary` or `tertiary` ramp. CoUI's call to
/// action is neutral, so its `primary`, `secondary` and `tertiary` slots all
/// read the neutral ramp. A separate ramp holding the neutral's hex would
/// make two primitives share one colour, and the Figma export would then
/// have no single variable to alias a semantic slot to.
@immutable
final class CouiPalette {
  /// Creates a [CouiPalette].
  const CouiPalette({
    required this.neutral,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
    required this.white,
    required this.black,
    @Deprecated(
      'Ignored (since 0.179) — CoUI has no primary ramp; its primary slots '
      'read the neutral ramp.',
    )
    CouiToneRamp? primary,
  });

  /// The neutral ramp — surfaces, text and boundaries.
  final CouiNeutralRamp neutral;

  /// The neutral ramp's hundreds, in the shape the removed `primary` ramp
  /// had.
  @Deprecated(
    'Use neutral (since 0.179) — CoUI has no primary ramp; its primary '
    'slots read the neutral ramp at the same step numbers.',
  )
  CouiToneRamp get primary => CouiToneRamp(
    s100: neutral.s100,
    s200: neutral.s200,
    s300: neutral.s300,
    s400: neutral.s400,
    s500: neutral.s500,
    s600: neutral.s600,
    s700: neutral.s700,
    s800: neutral.s800,
    s900: neutral.s900,
    s1000: neutral.s1000,
  );

  /// The `success` status ramp.
  final CouiStatusRamp success;

  /// The `info` status ramp.
  final CouiStatusRamp info;

  /// The `warning` status ramp.
  final CouiStatusRamp warning;

  /// The `error` status ramp.
  final CouiStatusRamp error;

  /// `base/white` — pure white, distinct from `neutral/50`.
  final CoreColor white;

  /// `base/black` — pure black, distinct from `neutral/1050`.
  final CoreColor black;

  /// The primitive vocabulary: `'<family>/<step>'` → colour, in emit order
  /// (neutral, success, info, warning, error, base).
  ///
  /// The Web writes each entry as `--coui-<family>-<step>`; the Figma
  /// export writes it as `color/coui/<family>/<step>`.
  Map<String, CoreColor> get primitives => {
    for (final step in neutral.steps.entries) 'neutral/${step.key}': step.value,
    for (final (name, ramp) in _toneRamps)
      for (final step in ramp.steps.entries) '$name/${step.key}': step.value,
    'base/white': white,
    'base/black': black,
  };

  List<(String, CouiToneRamp)> get _toneRamps => [
    ('success', success),
    ('info', info),
    ('warning', warning),
    ('error', error),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouiPalette &&
          neutral == other.neutral &&
          success == other.success &&
          info == other.info &&
          warning == other.warning &&
          error == other.error &&
          white == other.white &&
          black == other.black);

  @override
  int get hashCode => Object.hash(
    neutral,
    success,
    info,
    warning,
    error,
    white,
    black,
  );
}

bool _sameSteps(Map<int, CoreColor> a, Map<int, CoreColor> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
