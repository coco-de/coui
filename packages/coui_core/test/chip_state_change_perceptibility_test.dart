// A state has to look like something happened, or it did not happen.
//
// This is the check `button_state_change_perceptibility_test.dart` names
// Chip as owing: `CoreStateLayer` sits outside the alpha-parity guard's
// net, so a component adopting it has to show its own composited states
// actually differ from rest — a fill can be perfectly readable in both
// rest and hover and still fail this if hover repaints the exact same
// pixel rest already had.
//
// The historical bug that motivates the check, stated directly: before
// this component owned a `stateLayer`, `primary`/`selected` hover and
// pressed both landed on `on-surface` at an alpha that happened to equal
// the resting fill's own tone — the change measured 1.00, the literal
// absence of a state. Nothing here reproduces that specific collision;
// this file checks the NEW mechanism (the wash) can't silently regress
// into the same shape.
//
// Chip's mechanism is simpler than Button's: there is exactly one wash —
// `color-mix(in srgb, ink WEIGHT%, base)` on Web, the equivalent
// premultiplied blend in the Flutter resolver's `washedFill` — with no
// per-variant escape hatch (`link`'s decoration-only hover, `fixed`'s
// no-op). Every (colour, selected, emphasis) combination the design
// system ships restates its fill through the same wash, so this file
// checks all of them rather than reading per-variant override fields.

// The schemes are CoUI's own source (`CouiColorPresets.source`) — the
// look this product ships. A generated palette read through a mapping is
// the brand path and would measure a palette nobody sees here.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// `colour` at `alpha` composited over `page` — what actually lands on
/// screen when a fill carries alpha (the `unselectedBg` sentinel is
/// literally `CoreColor.transparent`, alpha 0 — its rendered pixel is the
/// page it sits on, not a colour of its own). `alpha` here must be
/// [CoreColor.effectiveOpacity], not the raw [CoreColor.opacity]
/// modifier field — the modifier defaults to 1.0 regardless of the
/// colour's own alpha byte, so reading it alone for `.transparent`
/// (alpha byte 0) silently treats a see-through fill as opaque.
int _compositeOverPage(int colorRgb, double alpha, int pageArgb) {
  int channel(int shift) {
    final s = (colorRgb >> shift) & 0xFF;
    final d = (pageArgb >> shift) & 0xFF;
    return (s * alpha + d * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// The `color-mix(in srgb, over P1%, base P2%)` step itself — CSS Color 4
/// §13.1's alpha-weighted mix, generalised past the simple channel blend
/// `button`/`navigation_bar`'s sibling tests use because Chip's `base`
/// operand can itself carry alpha (the transparent sentinel). When `base`
/// is fully opaque this collapses to that same simple blend; when `base`
/// is fully transparent the mixed colour is pure `over` at alpha
/// `weight` — exactly what `color-mix(in srgb, ink 12%, transparent)`
/// resolves to in a browser, which then gets composited onto the page in
/// [_compositeOverPage] like any other translucent fill.
({int colorRgb, double alpha}) _mix(
  int overArgb,
  int baseArgb,
  double baseAlpha,
  double weight,
) {
  // The ink operand is emitted without its own alpha — the state-layer
  // WEIGHT is what governs the blend ratio, not whatever alpha the ink
  // happened to carry (`resolveChipRules`'s doc comment says the same).
  const overAlpha = 1.0;
  final a1 = weight * overAlpha;
  final a2 = (1 - weight) * baseAlpha;
  final resultAlpha = a1 + a2;

  int channel(int shift) {
    final o = (overArgb >> shift) & 0xFF;
    final b = (baseArgb >> shift) & 0xFF;
    if (resultAlpha <= 0) return o;
    return ((o * a1 + b * a2) / resultAlpha).round().clamp(0, 255);
  }

  final rgb = (channel(16) << 16) | (channel(8) << 8) | channel(0);
  return (colorRgb: rgb, alpha: resultAlpha);
}

/// The four modes a colour has to answer for — deliberately including
/// high contrast, which is the mode where a candidate wash has the least
/// room left to move (the base token is already at its most extreme
/// step).
Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': source.light(),
    'dark': source.dark(),
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

const _perceptibleFloor = 1.02;

void _expectPerceptible(
  double delta, {
  required String mode,
  required String name,
  required String state,
}) {
  expect(
    delta,
    greaterThanOrEqualTo(_perceptibleFloor),
    reason:
        '$mode / $name / $state — ${delta.toStringAsFixed(4)} against '
        'rest is a state that paints nothing new',
  );
}

/// Rest fill (`base`) and rest ink (`ink`) for one (colour, selected,
/// emphasis) combination — re-deriving the exact branch shape
/// `resolveChip` (Flutter) and `resolveChipRules` (Web) both walk, so a
/// bug that changes which token a branch picks shows up here as well as
/// in the resolvers themselves. `custom`/seed-colour chips are a
/// separate, narrower group below — this table only covers what
/// [CoreChipStyle.defaultsByColor] ships.
({CoreColor base, CoreColor ink}) _restColors({
  required CoreChipColor chipColor,
  required bool selected,
  required CoreChipEmphasis emphasis,
  CoreChipVariant variant = CoreChipVariant.outlined,
}) {
  final colorStyle = CoreChipStyle.defaultsByColor[chipColor]!;
  if (selected) {
    return emphasis == .low
        ? (base: colorStyle.lowSelectedBg, ink: colorStyle.lowSelectedFg)
        : (base: colorStyle.selectedBg, ink: colorStyle.selectedFg);
  }
  return (
    base: variant == .filled
        ? CoreChipStyle.defaultFilledUnselectedBackgroundColor
        : colorStyle.unselectedBg,
    ink: emphasis == .low
        ? colorStyle.lowUnselectedFg
        : colorStyle.unselectedFg,
  );
}

void main() {
  const layer = CoreChipStyle.defaultStateLayer;

  group('the chip state layer is stated and ascends', () {
    test('hover <= focus <= pressed', () {
      expect(layer, isNotNull);
      expect(layer.isAscending, isTrue);
    });
  });

  group('every shipped chip fill restates a wash the eye can see', () {
    for (final chipColor in CoreChipColor.values.where((c) => c != .custom)) {
      for (final selected in [true, false]) {
        for (final emphasis in CoreChipEmphasis.values) {
          // `variant` only moves an unselected chip's fill, so the selected
          // rows are sampled once and the unselected ones at both variants.
          for (final variant
              in selected
                  ? [CoreChipVariant.outlined]
                  : CoreChipVariant.values) {
            final name =
                '${chipColor.name} '
                '${selected ? 'selected' : 'unselected ${variant.name}'} '
                '${emphasis.name}';

            test('$name — hover / focus / pressed all differ from rest', () {
              final colors = _restColors(
                chipColor: chipColor,
                selected: selected,
                emphasis: emphasis,
                variant: variant,
              );

              _schemes().forEach((mode, scheme) {
                final page = scheme
                    .resolve(const CoreColor.token(CoreColors.surface))
                    .argb;
                final resolvedBase = scheme.resolve(colors.base);
                final baseArgb = resolvedBase.argb;
                final baseAlpha = resolvedBase.effectiveOpacity;
                final inkArgb = scheme.resolve(colors.ink).argb;

                final restRendered = _compositeOverPage(
                  baseArgb,
                  baseAlpha,
                  page,
                );

                for (final entry in <String, double>{
                  'hover': layer.hover,
                  'focus': layer.focus,
                  'pressed': layer.pressed,
                }.entries) {
                  final mixed = _mix(inkArgb, baseArgb, baseAlpha, entry.value);
                  final washedRendered = _compositeOverPage(
                    mixed.colorRgb,
                    mixed.alpha,
                    page,
                  );
                  final delta = _contrast(restRendered, washedRendered);

                  _expectPerceptible(
                    delta,
                    mode: mode,
                    name: name,
                    state: entry.key,
                  );
                }
              });
            });
          }
        }
      }
    }
  });

  group('pressed washes stronger than hover, never the same weight', () {
    // Same claim `button_state_change_perceptibility_test.dart` makes for
    // its own ramp — restated here because Chip's ramp is a fully
    // independent `CoreStateLayer` value, not a shared instance, so a
    // future per-component override could silently collapse the tiers.
    test('the default subtle ramp keeps three distinct weights', () {
      expect(layer.focus, greaterThanOrEqualTo(layer.hover));
      expect(layer.pressed, greaterThan(layer.focus));
    });
  });

  group('a custom seed-colour chip washes the same way', () {
    // A selected `custom` chip bypasses `defaultsByColor` — a
    // caller-supplied seed becomes its rest fill — so this group exercises
    // that branch with one representative seed rather than the full
    // defaults table above. An unselected one speaks no colour: it is read
    // off the neutral row, the way both resolvers draw it.
    //
    // The selected label is the seed's own on-colour
    // (`defaultCustomSelectedForegroundColorFor`, designer decision 22 of
    // #5319). A fixed white label would measure 1.25:1 (dark) and 1.09:1
    // (high-contrast dark) on the near-white `tertiary` the dark modes map
    // to, and a hover wash toward it falls under the floor. With the
    // paired `onTertiary` every rung in every mode clears the floor, with
    // no exemption.
    const seed = CoreColor.token(CoreColors.tertiary);

    for (final selected in [true, false]) {
      for (final emphasis in CoreChipEmphasis.values) {
        // `variant` only moves an unselected chip's fill.
        for (final variant
            in selected ? [CoreChipVariant.outlined] : CoreChipVariant.values) {
          final name =
              'custom ${selected ? 'selected' : 'unselected ${variant.name}'} '
              '${emphasis.name}';

          test('$name — hover / focus / pressed all differ from rest', () {
            final CoreColor base;
            final CoreColor ink;
            if (selected && emphasis == .low) {
              base = CoreChipStyle.defaultCustomLowSelectedBackgroundColor;
              ink = CoreChipStyle.defaultCustomLowSelectedForegroundColor;
            } else if (selected) {
              base = seed;
              ink = CoreChipStyle.defaultCustomSelectedForegroundColorFor(seed);
            } else {
              // Unselected custom is the neutral chip: the neutral label at
              // each emphasis on the neutral rest fill. The hairline is not
              // sampled here.
              final neutral =
                  CoreChipStyle.defaultsByColor[CoreChipColor.neutral]!;
              base = variant == .filled
                  ? CoreChipStyle.defaultFilledUnselectedBackgroundColor
                  : neutral.unselectedBg;
              ink = emphasis == .low
                  ? neutral.lowUnselectedFg
                  : neutral.unselectedFg;
            }

            _schemes().forEach((mode, scheme) {
              final page = scheme
                  .resolve(const CoreColor.token(CoreColors.surface))
                  .argb;
              final resolvedBase = scheme.resolve(base);
              final baseArgb = resolvedBase.argb;
              final baseAlpha = resolvedBase.effectiveOpacity;
              final inkArgb = scheme.resolve(ink).argb;

              final restRendered = _compositeOverPage(
                baseArgb,
                baseAlpha,
                page,
              );

              for (final entry in <String, double>{
                'hover': layer.hover,
                'focus': layer.focus,
                'pressed': layer.pressed,
              }.entries) {
                final mixed = _mix(inkArgb, baseArgb, baseAlpha, entry.value);
                final washedRendered = _compositeOverPage(
                  mixed.colorRgb,
                  mixed.alpha,
                  page,
                );
                final delta = _contrast(restRendered, washedRendered);

                _expectPerceptible(
                  delta,
                  mode: mode,
                  name: name,
                  state: entry.key,
                );
              }
            });
          });
        }
      }
    }
  });
}
