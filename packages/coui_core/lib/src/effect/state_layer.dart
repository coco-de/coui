/// The overlay a control paints over itself while it is hovered, focused
/// or pressed.
library;

import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:meta/meta.dart';

/// How strongly a control's own foreground is laid over it, per interaction
/// state.
///
/// The mechanism is one thing said three ways, not three mechanisms: the
/// control's foreground colour is painted over its fill at one of these
/// weights. Lowering the fill's own alpha instead would fade the brand
/// colour every time the pointer moved.
///
/// **Why a type rather than three doubles per component.** The three
/// weights are not independent — they are one ramp, and the invariant that
/// matters (hover ≤ focus ≤ pressed) is a statement about the ramp, not
/// about any one value. A component that carried them as three separate
/// fields could state a focus weaker than its hover without anything
/// noticing, and the failure looks like hover doing nothing on a focused
/// control.
///
/// **This type is outside the alpha-parity guard's net, on purpose but not
/// for free.** That guard reads `final double? …Opacity` declarations under
/// `contracts/**/*_style.dart` and checks that both platforms apply the
/// alpha the same *kind* of way. These three weights live here, under a
/// different directory and under names it does not match, so it no longer
/// sees them — the three fields it used to see were
/// `hover|focus|pressedStateLayerOpacity` on `CoreButtonVariantStyle`.
///
/// What replaces it is stronger for this particular value, not weaker:
/// `button_state_change_perceptibility_test` reads the COMPOSITED result in
/// four modes on both platforms, where the guard only checked that a call
/// site of the right shape sat near the field name. But it is stronger for
/// `Button` alone. **A component that adopts this type owes an equivalent
/// check of its own** — otherwise it inherits the exemption without
/// inheriting the thing that earned it.
///
/// **What this does not say: where the layer is painted.** Every surface
/// that reads this today paints it over its own box — `Toggle` included,
/// whose layer is a pill stretched over the track (not a halo around the
/// thumb). Deliberately absent: a field nothing reads is not an axis
/// (`core/theme-axis-composition.md`).
@immutable
class CoreStateLayer {
  /// Creates a state-layer ramp.
  const CoreStateLayer({
    required this.hover,
    required this.focus,
    required this.pressed,
  });

  /// Over a surface that is not itself filled — a white or near-white
  /// panel, an outlined or ghost control.
  ///
  /// 3 / 8 / 12 %. Measured off the library canvas, which paints this ramp
  /// on `TextField`'s `plain` variant (the boxed variants carry hover on
  /// the border instead — no wash, see `CoreTextFieldVariantStyle
  /// .stateLayer`), `Chip` and the OTP cell — every one of them a light
  /// surface. (`Toggle` reads [standard]: the canvas paints 8 / 16 on its
  /// track and no focus wash. `NavigationBar` states a ramp of its own,
  /// 3 / 8 / 8: its pressed wash stops short of this tier's 12 so the
  /// unselected label keeps 4.5 : 1 over it in dark — see
  /// `CoreNavigationBarStyle.defaultStateLayer`.)
  /// The three weights come from [CoreOpacity]'s semantic trio rather than
  /// as literals here, because that trio is what the token export ships to
  /// the canvas. Written twice, the two drifted — the export said 3/10/15
  /// while this said 3/8/12, and nothing compared them.
  static const CoreStateLayer subtle = CoreStateLayer(
    hover: CoreOpacity.hover,
    focus: CoreOpacity.focus,
    pressed: CoreOpacity.pressed,
  );

  /// Over a dark or saturated fill — a primary or secondary button.
  ///
  /// 8 / 12 / 16 %. Heavier for the same perceived change: the same alpha
  /// moves a light surface further than a dark one, so matching the
  /// numbers would make the filled controls look unresponsive next to the
  /// unfilled ones.
  ///
  /// The canvas does not demonstrate this ramp — its filled controls carry
  /// a layer node but keep it hidden in every state, so the only surfaces
  /// it actually paints are the [subtle] ones. That is an absence of
  /// evidence, not evidence against; the two ramps agree exactly wherever
  /// the canvas does paint one.
  /// Off the numeric scale directly, not the semantic trio: there is no
  /// second set of hover/focus/pressed token names for the heavy ramp, and
  /// inventing one would publish an axis the canvas does not paint.
  static const CoreStateLayer strong = CoreStateLayer(
    hover: CoreOpacity.opacity8,
    focus: CoreOpacity.opacity12,
    pressed: CoreOpacity.opacity16,
  );

  /// The ramp the `state-layer/*` semantic tokens carry — the one a
  /// component reads when it has no reason of its own to differ.
  ///
  /// 8 / 8 / 16 %. Measured on the popup surface for the menu row
  /// (Button · Menu 개편 2026-09-08 §8-1): a hover ΔL* near 7 and a pressed
  /// near 15 in all four modes, with the label never below 10:1. Focus
  /// equals hover on purpose — the ring is the focus indicator, and a wash
  /// heavier than hover would make pointing at a focused row read as a
  /// step back.
  ///
  /// Why a third ramp rather than [subtle] or [strong]: those two are
  /// per-surface answers (a light control, a filled control), and the
  /// controls that read them each landed on their own numbers — four
  /// ladders across the kit today. This one sits behind a semantic name
  /// so that the system-wide decision, when it is taken, is one edit
  /// here rather than one per component. It is the menu row's ladder
  /// today, not yet everyone's.
  ///
  /// Authoring registry on the canvas: a layer's opacity binds to a percent
  /// FLOAT such as `opacity/70`, but no builder binds one of these rungs —
  /// the plugin writes the state-layer alpha as a literal — the arrangement
  /// `line-height/control` has.
  static const CoreStateLayer standard = CoreStateLayer(
    hover: CoreOpacity.opacity8,
    focus: CoreOpacity.opacity8,
    pressed: CoreOpacity.opacity16,
  );

  /// Weight while the pointer is over the control.
  final double hover;

  /// Weight while the control holds keyboard focus.
  ///
  /// Above [hover] so that hovering a focused control still reads as a
  /// change. Below [pressed] for the same reason in the other direction.
  final double focus;

  /// Weight while the control is held down.
  final double pressed;

  /// Whether the ramp only ever gets stronger.
  ///
  /// The one invariant worth naming: a focus weaker than hover makes
  /// hovering a focused control look like it did nothing, and a pressed
  /// weaker than focus does the same to the press.
  bool get isAscending => hover <= focus && focus <= pressed;

  /// Returns a copy with the given weights replaced.
  CoreStateLayer copyWith({double? hover, double? focus, double? pressed}) =>
      CoreStateLayer(
        hover: hover ?? this.hover,
        focus: focus ?? this.focus,
        pressed: pressed ?? this.pressed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStateLayer &&
          runtimeType == other.runtimeType &&
          hover == other.hover &&
          focus == other.focus &&
          pressed == other.pressed;

  @override
  int get hashCode => Object.hash(hover, focus, pressed);

  @override
  String toString() =>
      'CoreStateLayer(hover: $hover, focus: $focus, pressed: $pressed)';
}
