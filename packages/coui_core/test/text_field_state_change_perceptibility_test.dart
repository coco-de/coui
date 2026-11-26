// A hovered field has to look hovered, or the hover did not happen.
//
// `CoreStateLayer` sits outside the alpha-parity guard's net — that guard
// reads `final double? …Opacity` declarations under `contracts/**`, and
// these three weights live in `src/effect/` under names it does not match.
// The type's own doc states the deal: a component adopting it **owes an
// equivalent check of its own**, or it inherits the exemption without
// inheriting the thing that earned it. `button_state_change_perceptibility`
// is Button's; this is TextField's.
//
// The failure being pinned is not "wrong colour" but "no colour change at
// all": a state whose result equals the resting fill is the literal absence
// of a state, and reading either state on its own cannot see it, because
// nothing ever compares them.
//
// `defaultNormalVariant` / `defaultErrorVariant` no longer carry a
// `stateLayer` — the wash was measured against WCAG 2.4.13's 3:1 non-text
// contrast floor and dropped (an 8% foreground-over-`surface` blend landed
// 1.06–1.17 in every mode, well short of the floor). Hover now rides the
// border step alone, so those two variants are held to a border-contrast
// assertion instead of a wash-contrast one. `plain` has no border to step
// (its resting fill is transparent — the host's, not its own), so it keeps
// the wash and is held to the original assertions.

// The schemes are CoUI's own source (`CouiColorPresets.source`) — the
// look this product ships. A generated palette read through a mapping is
// the brand path and would measure a palette nobody sees here.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// Composites [over] at [alpha] onto [base] — the same arithmetic the
/// Flutter resolver's `Color.alphaBlend` performs and the same one Web's
/// `color-mix(in srgb, …)` performs, so one measurement answers for both.
int _blend(int over, int base, double alpha) {
  int channel(int shift) {
    final o = (over >> shift) & 0xFF;
    final b = (base >> shift) & 0xFF;
    return (o * alpha + b * (1 - alpha)).round();
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// Below this a state is invisible up to rounding, which is the same bug as
/// being exactly invisible. Matches Button's floor so the two components
/// are held to one standard.
const double _perceptibleFloor = 1.02;

Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': source.light(),
    'dark': source.dark(),
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

int _argb(CoreColorScheme scheme, CoreColor color) =>
    scheme.resolve(color).argb | 0xFF000000;

void main() {
  group('a TextField state change is visible', () {
    for (final variant in CoreTextFieldVariant.values) {
      final vs = CoreTextFieldStyle.defaultsByVariant[variant]!;

      // `plain` states no fill of its own — its resting surface is the
      // host's — so a blend against `backgroundColor` measures a wash over
      // nothing. The ramp is asserted; the deltas are the host's to prove.
      if (vs.backgroundColor == CoreColor.transparent) {
        test('${variant.name} states a ramp at all', () {
          expect(vs.stateLayer, isNotNull);
          expect(vs.stateLayer!.isAscending, isTrue);
        });
        continue;
      }

      // The boxed variants dropped their wash — hover now rides the
      // border alone. Held to a border-contrast assertion instead of the
      // wash-contrast one below.
      if (vs.stateLayer == null) {
        test('${variant.name} states no wash — hover rides the border '
            'alone', () {
          expect(vs.stateLayer, isNull);
        });

        final hoverBorder = vs.hoverBorderColor ?? vs.borderColor;
        if (hoverBorder == vs.borderColor) {
          // A variant may intentionally restate its resting border on
          // hover (the error row: the pointer does not soften a
          // validation border). That is a decision, not an oversight —
          // pin it explicitly so a future edit that accidentally drops
          // a real hover step doesn't read as "this is fine, like error".
          test('${variant.name} — hover intentionally restates the '
              'resting border (no softer state on the pointer)', () {
            expect(hoverBorder, vs.borderColor);
          });
          continue;
        }

        test('${variant.name} — hover border is perceptibly different '
            'from the resting border, in every mode', () {
          _schemes().forEach((mode, scheme) {
            final rest = _argb(scheme, vs.borderColor);
            final hovered = _argb(scheme, hoverBorder);
            final delta = _contrast(rest, hovered);

            expect(
              delta,
              greaterThanOrEqualTo(_perceptibleFloor),
              reason:
                  '$mode / ${variant.name} — the hover border lands on '
                  '${delta.toStringAsFixed(4)} against the resting one, '
                  'which is a state that draws nothing',
            );
          });
        });
        continue;
      }

      test('${variant.name} states a ramp at all', () {
        // The adoption itself. Without this, every assertion below would
        // vacuously pass the day someone dropped the field.
        expect(
          vs.stateLayer,
          isNotNull,
          reason:
              'the state-layer decision record assigns Text Field to tier A; '
              'a variant with no ramp paints no hover, focus or pressed',
        );
        expect(vs.stateLayer!.isAscending, isTrue);
      });

      test('${variant.name} — every state differs from rest, in every '
          'mode', () {
        final layer = vs.stateLayer!;
        _schemes().forEach((mode, scheme) {
          final rest = _argb(scheme, vs.backgroundColor);
          final fg = _argb(scheme, vs.foregroundColor);

          for (final entry in <String, double>{
            'hover': layer.hover,
            'focus': layer.focus,
            'pressed': layer.pressed,
          }.entries) {
            final washed = _blend(fg, rest, entry.value);
            final delta = _contrast(washed, rest);
            expect(
              delta,
              greaterThanOrEqualTo(_perceptibleFloor),
              reason:
                  '$mode / ${variant.name} / ${entry.key} — the wash lands on '
                  '${delta.toStringAsFixed(4)} against the resting fill, '
                  'which is a state that draws nothing',
            );
          }
        });
      });

      test('${variant.name} — and each state differs from the one below', () {
        // Ascending WEIGHTS do not guarantee ascending RESULTS: the blend
        // is against a specific fill, and two adjacent weights can round to
        // the same 8-bit channel on a fill close to the foreground. Hover
        // on a focused field has to change something, so the composited
        // steps are what gets measured, not the ramp's own ordering.
        final layer = vs.stateLayer!;
        _schemes().forEach((mode, scheme) {
          final rest = _argb(scheme, vs.backgroundColor);
          final fg = _argb(scheme, vs.foregroundColor);

          final hover = _blend(fg, rest, layer.hover);
          final focus = _blend(fg, rest, layer.focus);
          final pressed = _blend(fg, rest, layer.pressed);

          expect(
            focus,
            isNot(hover),
            reason:
                '$mode / ${variant.name} — hovering a focused field '
                'repaints the focus colour, so the pointer does nothing',
          );
          expect(
            pressed,
            isNot(focus),
            reason:
                '$mode / ${variant.name} — pressing a focused field '
                'repaints the focus colour, so the press does nothing',
          );
        });
      });

      test('${variant.name} — the washed fill still carries its text', () {
        // The wash darkens (or lightens) the ground the value sits on. A
        // state that made the field prettier and the text unreadable would
        // pass every assertion above.
        final layer = vs.stateLayer!;
        _schemes().forEach((mode, scheme) {
          final rest = _argb(scheme, vs.backgroundColor);
          final fg = _argb(scheme, vs.foregroundColor);
          final pressed = _blend(fg, rest, layer.pressed);

          expect(
            _contrast(fg, pressed),
            greaterThanOrEqualTo(4.5),
            reason:
                '$mode / ${variant.name} — value text over the pressed wash',
          );
        });
      });
    }
  });
}
