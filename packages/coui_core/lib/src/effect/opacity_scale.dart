/// Opacity primitive + semantic tokens.
///
/// Spec: 21개 Primitive(`opacity0`~`opacity100`) + 5개 Semantic
/// (`disabled`/`hover`/`focus`/`pressed`/`scrim`).
///
/// Flutter: `CoreOpacity.opacity50` → 0.5 (const double, 0.0–1.0)
/// Web: `CoreOpacity.scale.opacity50` → '50' (Tailwind class key)
///
/// Tailwind CSS scale 을 기반으로 하되, 15/85 를 추가하여 양 끝 구간에서
/// 세밀한 조절이 가능합니다.
abstract final class CoreOpacity {
  const CoreOpacity._();

  // === Primitive Tokens (21개) ===

  /// 0.0 — fully transparent.
  static const double opacity0 = 0;

  /// 0.03 — barest overlay. `0 → 5%` is not "the next step" of a state
  /// layer — it is a different intensity, the same reason the size
  /// ladder keeps a tighter step in its optical range. Exists mainly
  /// so `hover` can sit here instead of doubling straight to 5%.
  static const double opacity3 = 0.03;

  /// 0.05 — subtle overlay.
  static const double opacity5 = 0.05;

  /// 0.08 — the focus weight of the light-surface state ramp.
  ///
  /// This step and [opacity12] / [opacity16] exist because the state
  /// ramps land between the old 5 / 10 / 15 rungs. They were carried as
  /// bare literals inside `CoreStateLayer` for a while, which meant the
  /// weights the kit actually paints were the one set of opacities not on
  /// this scale — and so the only ones the token export could not name.
  static const double opacity8 = 0.08;

  /// 0.1 — light overlay.
  static const double opacity10 = 0.1;

  /// 0.12 — the pressed weight of the light-surface state ramp, and the
  /// focus weight of the heavy one.
  static const double opacity12 = 0.12;

  /// 0.15 — overlay.
  static const double opacity15 = 0.15;

  /// 0.16 — the pressed weight of the heavy state ramp.
  static const double opacity16 = 0.16;

  /// 0.2 — medium-light overlay.
  static const double opacity20 = 0.2;

  /// 0.25 — quarter transparent.
  static const double opacity25 = 0.25;

  /// 0.3 — medium overlay.
  static const double opacity30 = 0.3;

  /// 0.4 — disabled state default.
  static const double opacity40 = 0.4;

  /// 0.5 — half transparent.
  static const double opacity50 = 0.5;

  /// 0.6 — medium-heavy opaque.
  static const double opacity60 = 0.6;

  /// 0.7 — heavy opaque.
  static const double opacity70 = 0.7;

  /// 0.75 — three-quarters opaque.
  static const double opacity75 = 0.75;

  /// 0.8 — nearly opaque.
  static const double opacity80 = 0.8;

  /// 0.85 — very opaque.
  static const double opacity85 = 0.85;

  /// 0.9 — slightly transparent.
  static const double opacity90 = 0.9;

  /// 0.95 — nearly fully opaque.
  static const double opacity95 = 0.95;

  /// 1.0 — fully opaque.
  static const double opacity100 = 1;

  // === Semantic Tokens (5개) ===

  /// Disabled state opacity (0.4).
  static const double disabled = opacity40;

  /// Hover overlay opacity (0.03).
  ///
  /// These three are the light-surface state ramp, and they are the same
  /// three numbers `CoreStateLayer.subtle` carries — that type reads them
  /// from here, so the pair cannot drift.
  ///
  /// They said 3 / 10 / 15 until 0.130, which was a second ramp: nothing
  /// in Dart read [focus] or [pressed], but the token export publishes all
  /// three to Figma, so a designer binding `opacity/focus` on the canvas
  /// got a weight the kit never painted. An unread constant is merely
  /// dead; an unread constant that ships to the canvas is wrong.
  static const double hover = opacity3;

  /// Focus overlay opacity (0.08).
  static const double focus = opacity8;

  /// Pressed overlay opacity (0.12).
  static const double pressed = opacity12;

  /// Modal/overlay scrim opacity (0.3).
  ///
  /// The dim a modal lays over the page in every brightness: black at 30%
  /// draws `#b3b3b3` over a white page. A designer-judgement value — light
  /// enough that the page behind still reads, so the reader knows which
  /// screen the modal sits over; the panel's own shadow and border carry
  /// the separation.
  static const double scrim = opacity30;

  // === Scale Names (String for Web) ===

  /// Tailwind/CSS variable key record for compile-safe interpolation.
  ///
  /// Usage: `opacity-${CoreOpacity.scale.opacity50}` → `opacity-50`,
  /// or `var(--opacity-${CoreOpacity.scale.disabled})` →
  /// `var(--opacity-disabled)`.
  static const ({
    String disabled,
    String focus,
    String hover,
    String opacity0,
    String opacity10,
    String opacity12,
    String opacity100,
    String opacity15,
    String opacity16,
    String opacity20,
    String opacity25,
    String opacity3,
    String opacity30,
    String opacity40,
    String opacity5,
    String opacity8,
    String opacity50,
    String opacity60,
    String opacity70,
    String opacity75,
    String opacity80,
    String opacity85,
    String opacity90,
    String opacity95,
    String pressed,
    String scrim,
  })
  scale = (
    // Primitives
    opacity0: '0',
    opacity5: '5',
    opacity8: '8',
    opacity10: '10',
    opacity12: '12',
    opacity15: '15',
    opacity16: '16',
    opacity20: '20',
    opacity25: '25',
    opacity3: '3',
    opacity30: '30',
    opacity40: '40',
    opacity50: '50',
    opacity60: '60',
    opacity70: '70',
    opacity75: '75',
    opacity80: '80',
    opacity85: '85',
    opacity90: '90',
    opacity95: '95',
    opacity100: '100',
    // Semantics
    disabled: 'disabled',
    hover: 'hover',
    focus: 'focus',
    pressed: 'pressed',
    scrim: 'scrim',
  );
}
