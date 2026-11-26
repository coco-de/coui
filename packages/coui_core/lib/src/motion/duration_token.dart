/// Duration primitive tokens.
///
/// Spec defines 16 primitive tokens — Transition (`ms0`–`ms500`, 50 ms steps)
/// and Display (`ms1000`–`ms5000`, 1 s steps). Values are stored as integer
/// milliseconds.
///
/// Component-specific constant (`indeterminate`) is kept as an
/// out-of-spec auxiliary token.
abstract final class CoreDuration {
  const CoreDuration._();

  // ── Transition (0–500 ms, 50 ms steps) ──

  /// 0 ms — instant, no animation.
  static const int ms0 = 0;

  /// 50 ms — immediate feedback.
  static const int ms50 = 50;

  /// 100 ms — fast transition.
  static const int ms100 = 100;

  /// 150 ms — fast transition.
  static const int ms150 = 150;

  /// 200 ms — standard transition (default).
  static const int ms200 = 200;

  /// 250 ms — medium transition.
  static const int ms250 = 250;

  /// 300 ms — smooth transition.
  static const int ms300 = 300;

  /// 350 ms — slow transition.
  static const int ms350 = 350;

  /// 400 ms — slow transition.
  static const int ms400 = 400;

  /// 450 ms — complex transition.
  static const int ms450 = 450;

  /// 500 ms — maximum transition duration.
  static const int ms500 = 500;

  // ── Display (1000–5000 ms, 1 s steps) ──

  /// 1000 ms (1 s).
  static const int ms1000 = 1000;

  /// 2000 ms (2 s).
  static const int ms2000 = 2000;

  /// 3000 ms (3 s) — typical toast duration.
  static const int ms3000 = 3000;

  /// 4000 ms (4 s).
  static const int ms4000 = 4000;

  /// 5000 ms (5 s) — long display.
  static const int ms5000 = 5000;

  // ── Component-specific (out of spec, retained) ──

  /// Indeterminate slide duration (1500 ms) — used by `Loading.bar` and
  /// `Progress` indeterminate fill for ping-pong / left-to-right slides.
  static const int indeterminate = 1500;

  // ── Alias tier (semantic) ──
  //
  // Use-case names layered on the raw scale above. The raw scale answers
  // "how long"; the alias answers "why that long" — `ms150` does not say why
  // it is 150, `fast` does. Component defaults reference the alias tier so a
  // single global motion override (reduced-motion) has one vocabulary to act
  // on instead of 16 unrelated numbers.
  //
  // Only transition-tier durations (0–500 ms) have aliases. Display-tier
  // values (`ms1000`+) and [indeterminate] describe how long content stays
  // on screen, not how fast it moves, so a motion override must not touch
  // them — they stay raw by design.
  //
  // Each alias is pinned to the raw value that was already dominant for that
  // use case, so introducing this tier changed no timing anywhere.

  /// Immediate state change — check marks, toggles. Maps to [ms100].
  ///
  /// The shortest duration still read as motion rather than a jump.
  static const int instant = ms100;

  /// Small-element transition — tooltip reveal, chip removal, button hover,
  /// input focus. Maps to [ms150].
  static const int fast = ms150;

  /// Default for most transitions — dropdowns, focus rings, card hover,
  /// accordion. Maps to [ms200].
  static const int normal = ms200;

  /// Medium-element transition — modal entry, panel slide. Maps to [ms300].
  static const int moderate = ms300;

  /// Page-level transition and composite choreography. Maps to [ms500].
  ///
  /// The upper bound of the transition tier — anything longer reads as a
  /// wait rather than a transition.
  static const int slow = ms500;

  // ── Scale Names (Web / Tailwind) ──

  /// Tailwind duration class names for compile-safe interpolation.
  static const ({
    String indeterminate,
    String ms0,
    String ms100,
    String ms1000,
    String ms150,
    String ms200,
    String ms2000,
    String ms250,
    String ms300,
    String ms3000,
    String ms350,
    String ms400,
    String ms4000,
    String ms450,
    String ms50,
    String ms500,
    String ms5000,
  })
  scale = (
    ms0: '0',
    ms50: '50',
    ms100: '100',
    ms150: '150',
    ms200: '200',
    ms250: '250',
    ms300: '300',
    ms350: '350',
    ms400: '400',
    ms450: '450',
    ms500: '500',
    ms1000: '1000',
    ms2000: '2000',
    ms3000: '3000',
    ms4000: '4000',
    ms5000: '5000',
    indeterminate: '1500',
  );
}
