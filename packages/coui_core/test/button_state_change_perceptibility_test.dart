// A state has to look like something happened, or it did not happen.
//
// `button_variant_contrast_test.dart` asks "can you still read the label
// on this fill" — a readability question. This file asks a different one:
// "does the fill (or, failing that, the label) actually change when the
// button enters this state at all." A fill can be perfectly readable in
// both rest and hover and still fail this — if hover repaints the exact
// same colour rest already had, hovering does nothing, and the WCAG
// reading of either state alone cannot see that, because it never compares
// them to each other.
//
// This is not hypothetical. Chip actually shipped this: primary/selected
// hover and pressed both landed on `on-surface` at an alpha that happened
// to equal the resting fill's own tone, and the change was 1.00 — the
// literal absence of a state. Nothing here is chip-specific; this is the
// general shape of that bug for Button.
//
// The floor is 1.02 rather than 1.00 to leave a hair of room for rounding
// in the sRGB → contrast pipeline — a state that is *exactly* invisible
// and one that is invisible up to floating-point noise are the same bug.
//
// Scope: Button only. Chip had the same bug once and would benefit from
// the same test; this file does not attempt it, so a reader should not
// take passing here as evidence about any other component.

// The schemes are CoUI's own source — `CouiColorPresets.source` through
// `resolveThemeSchemeFrom`, which is what `CoreThemePresets` puts on screen.
// A generated palette read through a mapping is the brand path; a guard
// that measured one would check a palette this product does not ship.
// Reading the source is the difference between checking the screen and
// checking a palette nobody sees.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// `src` at [alpha] composited over `dst` — what the eye receives when a
/// fill is translucent. Without this, comparing a raw token argb to
/// another raw token argb would be comparing colours nobody's screen ever
/// shows: what's actually painted is the blend with whatever sits behind.
int _composite(int src, double alpha, int dst) {
  int channel(int shift) {
    final s = (src >> shift) & 0xFF;
    final d = (dst >> shift) & 0xFF;
    return (s * alpha + d * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// The colour a `CoreColor` becomes on [scheme], flattened onto [page]
/// when it carries alpha.
int _rendered(CoreColorScheme scheme, CoreColor color, int page) {
  final resolved = scheme.resolve(color);
  final opacity = color.opacity;
  if (opacity >= 1) return resolved.argb | 0xFF000000;
  return _composite(resolved.argb, opacity, page);
}

/// The four modes a colour has to answer for — deliberately including
/// high contrast, which the sibling readability test does not check.
/// It matters here specifically: a candidate hover fill for `destructive`
/// (a darker but still-red token) passed in both normal modes and still
/// failed this exact test in high-contrast mode, because that mode had
/// already pushed `error` itself to its most extreme step — there was no
/// darker step left to move to, so the state stopped being perceptible in
/// the one mode where a user turned contrast up because they needed it.
Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.light,
    ),
    'dark': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.dark,
    ),
    'high-contrast light': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.light,
      highContrast: true,
    ),
    'high-contrast dark': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.dark,
      highContrast: true,
    ),
  };
}

/// A state Button paints beyond rest, and the two accessors that read
/// what it restates. `null` from either accessor means "this variant does
/// not restate that channel for this state" — not "restates it as
/// nothing" — the two are different and only one of them is a bug
/// candidate (see `_isPerceptible` below).
class _EngagedState {
  const _EngagedState(this.name, this.fill, this.label, {this.stateLayer});

  final String name;
  final CoreColor? Function(CoreButtonVariantStyle) fill;
  final CoreColor? Function(CoreButtonVariantStyle) label;

  /// `stateLayer.hover` / `stateLayer.pressed` reader — `null`
  /// for states (`selected`) that have no state-layer concept. See
  /// `_verdict`'s use of this for why the plain [fill] accessor alone
  /// cannot see this axis: `primary`/`secondary`/`outline` deliberately
  /// set [fill] equal to the resting background (the resolver composites
  /// the real delta at paint time, not at the Style-value level this test
  /// otherwise reads).
  final double? Function(CoreButtonVariantStyle)? stateLayer;
}

const _engagedStates = [
  _EngagedState(
    'hover',
    _hoverFill,
    _hoverLabel,
    stateLayer: _hoverStateLayerOpacity,
  ),
  _EngagedState(
    'focus',
    _focusFill,
    _focusLabel,
    stateLayer: _focusStateLayerOpacity,
  ),
  _EngagedState('selected', _selectedFill, _selectedLabel),
  _EngagedState(
    'pressed',
    _pressedFill,
    _pressedLabel,
    stateLayer: _pressedStateLayerOpacity,
  ),
];

CoreColor? _hoverFill(CoreButtonVariantStyle s) => s.hoverBackgroundColor;
CoreColor? _hoverLabel(CoreButtonVariantStyle s) => s.hoverForegroundColor;
CoreColor? _selectedFill(CoreButtonVariantStyle s) => s.selectedBackgroundColor;
CoreColor? _selectedLabel(CoreButtonVariantStyle s) =>
    s.selectedForegroundColor;

// `pressed` falls back to `hover` when a variant does not populate its own
// pressed slot (the resolver's `vs.pressedX ?? vs.hoverX` chain,
// `CoUI_Button_State_Layer_Decision.md` §9) — mirroring that fallback here,
// rather than reading the raw nullable field, is what lets every variant
// whose hover is already perceptible pass this state too without a
// dedicated pressed colour. Only `destructive` states its own values;
// every other variant's "pressed" delta is really hover's delta.
CoreColor? _pressedFill(CoreButtonVariantStyle s) =>
    s.pressedBackgroundColor ?? s.hoverBackgroundColor;
CoreColor? _pressedLabel(CoreButtonVariantStyle s) =>
    s.pressedForegroundColor ?? s.hoverForegroundColor;

double? _hoverStateLayerOpacity(CoreButtonVariantStyle s) =>
    s.stateLayer?.hover;
// Mirrors `_pressedFill`'s own hover fallback — a variant that sets only
// the hover weight paints pressed at that same weight.
double? _focusStateLayerOpacity(CoreButtonVariantStyle s) =>
    s.stateLayer?.focus;

/// There is no `focusedForegroundColor` — focus restates the fill only,
/// so the label accessor below always answers "this state does not restate
/// that channel", which is a different answer from "restates it as
/// nothing" and is what `_verdict` needs to hear.
CoreColor? _focusFill(CoreButtonVariantStyle s) => s.focusedBackgroundColor;

CoreColor? _focusLabel(CoreButtonVariantStyle s) => null;

double? _pressedStateLayerOpacity(CoreButtonVariantStyle s) =>
    s.stateLayer?.pressed;

const _perceptibleFloor = 1.02;

/// Verdict for one (variant, state, mode) triple.
class _Verdict {
  const _Verdict({
    required this.checked,
    required this.backgroundDelta,
    required this.foregroundDelta,
    required this.reason,
  });

  /// False when neither channel restates a value that differs from rest —
  /// e.g. `fixed`, which carries no colour change on any state by design.
  /// A test that reads only colours cannot tell such a variant from a
  /// forgotten state, so it reports it rather than passing it.
  final bool checked;
  final double? backgroundDelta;
  final double? foregroundDelta;
  final String reason;
}

_Verdict _verdict(
  CoreColorScheme scheme,
  CoreButtonVariantStyle style,
  _EngagedState state,
) {
  final page = scheme.resolve(const CoreColor.token(CoreColors.surface)).argb;

  final restFill = style.backgroundColor;
  final stateFill = state.fill(style) ?? restFill;

  // Compare by resolved VALUE, not by null-ness — a variant that restates
  // the identical token (a hover that repeats its own resting fill) has
  // not actually said anything new for this channel, the same as if it
  // had said nothing.
  final restFillRendered = _rendered(scheme, restFill, page);
  final stateFillRendered = _rendered(scheme, stateFill, page);
  final backgroundUnchanged = restFillRendered == stateFillRendered;

  if (!backgroundUnchanged) {
    return _Verdict(
      checked: true,
      backgroundDelta: _contrast(restFillRendered, stateFillRendered),
      foregroundDelta: null,
      reason: 'background',
    );
  }

  // The plain fill accessor found no change (`primary`/`secondary`/
  // `outline` deliberately state it equal to rest, see `_EngagedState.
  // stateLayer`'s doc) — check whether this state instead composites a
  // `foregroundColor`-tinted overlay on top, mirroring the resolver's own
  // `Color.alphaBlend(foreground @ opacity, resolvedBackground)` math
  // (`CoreButtonVariantStyle.stateLayer?.hover`'s doc).
  final stateLayerOpacity = state.stateLayer?.call(style);
  if (stateLayerOpacity != null) {
    final overlayRendered = _rendered(scheme, style.foregroundColor, page);
    final composited = _composite(
      overlayRendered,
      stateLayerOpacity,
      restFillRendered,
    );
    return _Verdict(
      checked: true,
      backgroundDelta: _contrast(restFillRendered, composited),
      foregroundDelta: null,
      reason: 'state-layer overlay',
    );
  }

  // Background carries no signal for this state — fall through to
  // foreground, composited on the (unchanged) rendered background.
  final restLabel = style.foregroundColor;
  final stateLabel = state.label(style) ?? restLabel;
  final restLabelRendered = _rendered(scheme, restLabel, restFillRendered);
  final stateLabelRendered = _rendered(scheme, stateLabel, stateFillRendered);

  if (restLabelRendered == stateLabelRendered) {
    // Neither channel restates anything this test can see. That is not
    // automatically a pass: it is only correct when some OTHER channel
    // (decoration, weight, an icon swap) carries the state instead. This
    // test cannot verify that channel, so it reports "not checked" rather
    // than asserting a colour delta that was never the mechanism.
    return const _Verdict(
      checked: false,
      backgroundDelta: null,
      foregroundDelta: null,
      reason: 'neither channel restates a different value',
    );
  }

  return _Verdict(
    checked: true,
    backgroundDelta: null,
    foregroundDelta: _contrast(restLabelRendered, stateLabelRendered),
    reason: 'foreground',
  );
}

void main() {
  group('an engaged button state is perceptible, not just readable', () {
    final schemes = _schemes();

    for (final variant in CoreButtonVariant.values) {
      for (final state in _engagedStates) {
        test('${variant.name} ${state.name}', () {
          final style = CoreButtonStyle.defaultsByVariant[variant]!;

          // `selected` is not a state every variant has — most never turn
          // `useSelectedState` on, and testing it for them would not be
          // "this state carries no signal" (the case the allow-list
          // below is for), it would be "this state does not exist here at
          // all". Different question, and not this test's to answer.
          if (state.name == 'selected' && !style.useSelectedState) return;

          // Same distinction for focus: a variant that restates neither the
          // fill nor a state-layer weight has no focus *paint* to check.
          // That is not "this state is invisible" — the focus RING is a
          // separate mechanism and carries the accessibility obligation on
          // its own (decision log §2-3). Asserting here would be asserting
          // that every variant must also tint, which is not the decision.
          if (state.name == 'focus' &&
              style.focusedBackgroundColor == null &&
              style.stateLayer?.focus == null) {
            return;
          }

          var anyChecked = false;

          schemes.forEach((mode, scheme) {
            final verdict = _verdict(scheme, style, state);
            if (!verdict.checked) return;
            anyChecked = true;

            final delta = verdict.backgroundDelta ?? verdict.foregroundDelta!;
            expect(
              delta,
              greaterThanOrEqualTo(_perceptibleFloor),
              reason:
                  '${variant.name} ${state.name} in $mode — the '
                  '${verdict.reason} does not change (delta '
                  '${delta.toStringAsFixed(4)}), so nothing visibly '
                  'happens when this state engages',
            );
          });

          // A variant/state pair that is unchecked in every mode is not a
          // pass by default — it means this test found no colour channel
          // to verify and cannot tell a real state (carried by something
          // other than colour) from a forgotten one. `fixed` is the one
          // legitimate case today; any other unchecked pair should be looked
          // at by eye.
          if (!anyChecked) {
            expect(
              '${variant.name} ${state.name}',
              anyOf(
                // `fixed` is the deliberately-inert variant CardImage
                // wraps its own image in (button_variant.dart) — no
                // fill, no border, no colour change on any state by
                // design, because the pressable affordance is the image
                // itself, not button chrome. `pressed` falls back to
                // the same no-op hover.
                'fixed hover',
                'fixed pressed',
              ),
              reason:
                  '${variant.name} ${state.name} restates neither '
                  'background nor foreground in any mode — if this is '
                  'intentional (a non-colour channel carries the state), '
                  'add it to the allow-list above with why; otherwise the '
                  'state was forgotten',
            );
          }
        });
      }
    }
  });

  group('the state layer is one mechanism with ordered weights', () {
    // Both resolvers pick the strongest active weight rather than layering
    // them, and both put focus above hover. That ordering is only correct
    // while focus is in fact the heavier of the two — otherwise a focused
    // button would LOSE overlay the moment a pointer arrived, which reads
    // as the hover doing nothing.
    //
    // On Web the ordering is not even a branch: it is the order the three
    // rules are written into the scoped stylesheet, resolved by the
    // cascade at equal specificity. Nothing there would complain if these
    // weights were reordered — this is what would.
    for (final variant in CoreButtonVariant.values) {
      final style = CoreButtonStyle.defaultsByVariant[variant]!;
      final hover = style.stateLayer?.hover;
      final focus = style.stateLayer?.focus;
      final pressed = style.stateLayer?.pressed;
      if (hover == null) continue;

      test('${variant.name} weights ascend hover → focus → pressed', () {
        expect(
          focus,
          isNotNull,
          reason:
              '${variant.name} has a state layer but no focus weight, so '
              'focus falls back to hover and the two states look the same',
        );
        expect(focus, greaterThanOrEqualTo(hover));
        expect(pressed, isNotNull);
        expect(pressed, greaterThanOrEqualTo(focus!));
      });
    }

    test('a dark fill gets a heavier layer than a light one', () {
      // The whole point of splitting into tiers. Stated as a relationship
      // rather than as the literal 0.08 / 0.03, because the numbers are
      // the design team's to retune and this invariant is not: the same
      // alpha produces less perceived change on a dark ground, so if the
      // two tiers ever converge the split has silently been undone.
      //
      // Stated on the ramps rather than on two Button rows: the filled
      // pair (`primary` / `secondary`) moved to an opaque container swap
      // (2026-09-08 §5) and no Button row carries `strong` today, but the
      // ramp is still what a dark-filled control elsewhere picks up, and
      // a retune lands on the ramp.
      expect(
        CoreStateLayer.strong.hover,
        greaterThan(CoreStateLayer.subtle.hover),
        reason:
            'strong is the dark-fill tier and subtle the light-fill tier — '
            'equal weights mean the dark one changes less than the light '
            'one, which is the complaint the tier split was made to answer',
      );
    });
  });
}
