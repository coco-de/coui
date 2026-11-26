/// Pure-Dart cubic-bezier coordinates.
///
/// Maps 1:1 to CSS `cubic-bezier(x1, y1, x2, y2)` and Flutter `Cubic(x1, y1,
/// x2, y2)`. `coui_flutter` provides an adapter extension that converts this
/// record to a Flutter `Curve`.
typedef CoreCubicBezier = ({double x1, double y1, double x2, double y2});

/// Easing primitive tokens — cubic-bezier curves (34개).
///
/// Spec defines 43 easing tokens. The 34 CSS-representable curves live here
/// as `CoreCubicBezier` records. The remaining 9 mathematical / multi-segment
/// curves are exposed via [CoreEasingFunction] (bounce / elastic / decelerate
/// / three-point-cubic).
///
/// Design rationale: `coui_core` is Flutter-free. Storing only the 4 control
/// points keeps the package framework-agnostic; `coui_flutter` and `coui_web`
/// adapt these into `Curve` and CSS `cubic-bezier()` strings respectively.
abstract final class CoreEasing {
  const CoreEasing._();

  // === CSS standard (5) ===

  /// Linear motion (0, 0, 1, 1).
  static const CoreCubicBezier linear = (x1: 0, y1: 0, x2: 1, y2: 1);

  /// Default CSS ease.
  static const CoreCubicBezier ease = (x1: 0.25, y1: 0.1, x2: 0.25, y2: 1);

  /// Acceleration (slow start).
  static const CoreCubicBezier easeIn = (x1: 0.42, y1: 0, x2: 1, y2: 1);

  /// Deceleration (slow end).
  static const CoreCubicBezier easeOut = (x1: 0, y1: 0, x2: 0.58, y2: 1);

  /// Acceleration then deceleration.
  static const CoreCubicBezier easeInOut = (x1: 0.42, y1: 0, x2: 0.58, y2: 1);

  // === Sine (3) — soft, natural motion ===

  /// Sine ease-in.
  static const CoreCubicBezier easeInSine = (
    x1: 0.47,
    y1: 0,
    x2: 0.745,
    y2: 0.715,
  );

  /// Sine ease-out.
  static const CoreCubicBezier easeOutSine = (
    x1: 0.39,
    y1: 0.575,
    x2: 0.565,
    y2: 1,
  );

  /// Sine ease-in-out.
  static const CoreCubicBezier easeInOutSine = (
    x1: 0.445,
    y1: 0.05,
    x2: 0.55,
    y2: 0.95,
  );

  // === Quad (3) — t² ===

  /// Quad ease-in.
  static const CoreCubicBezier easeInQuad = (
    x1: 0.55,
    y1: 0.085,
    x2: 0.68,
    y2: 0.53,
  );

  /// Quad ease-out.
  static const CoreCubicBezier easeOutQuad = (
    x1: 0.25,
    y1: 0.46,
    x2: 0.45,
    y2: 0.94,
  );

  /// Quad ease-in-out.
  static const CoreCubicBezier easeInOutQuad = (
    x1: 0.455,
    y1: 0.03,
    x2: 0.515,
    y2: 0.955,
  );

  // === Cubic (3) — t³ ===

  /// Cubic ease-in.
  static const CoreCubicBezier easeInCubic = (
    x1: 0.55,
    y1: 0.055,
    x2: 0.675,
    y2: 0.19,
  );

  /// Cubic ease-out.
  static const CoreCubicBezier easeOutCubic = (
    x1: 0.215,
    y1: 0.61,
    x2: 0.355,
    y2: 1,
  );

  /// Cubic ease-in-out.
  static const CoreCubicBezier easeInOutCubic = (
    x1: 0.645,
    y1: 0.045,
    x2: 0.355,
    y2: 1,
  );

  // === Quart (3) — t⁴ ===

  /// Quart ease-in.
  static const CoreCubicBezier easeInQuart = (
    x1: 0.895,
    y1: 0.03,
    x2: 0.685,
    y2: 0.22,
  );

  /// Quart ease-out.
  static const CoreCubicBezier easeOutQuart = (
    x1: 0.165,
    y1: 0.84,
    x2: 0.44,
    y2: 1,
  );

  /// Quart ease-in-out.
  static const CoreCubicBezier easeInOutQuart = (
    x1: 0.77,
    y1: 0,
    x2: 0.175,
    y2: 1,
  );

  // === Quint (3) — t⁵ ===

  /// Quint ease-in.
  static const CoreCubicBezier easeInQuint = (
    x1: 0.755,
    y1: 0.05,
    x2: 0.855,
    y2: 0.06,
  );

  /// Quint ease-out.
  static const CoreCubicBezier easeOutQuint = (
    x1: 0.23,
    y1: 1,
    x2: 0.32,
    y2: 1,
  );

  /// Quint ease-in-out.
  static const CoreCubicBezier easeInOutQuint = (
    x1: 0.86,
    y1: 0,
    x2: 0.07,
    y2: 1,
  );

  // === Expo (3) — 2^x ===

  /// Expo ease-in.
  static const CoreCubicBezier easeInExpo = (
    x1: 0.95,
    y1: 0.05,
    x2: 0.795,
    y2: 0.035,
  );

  /// Expo ease-out.
  static const CoreCubicBezier easeOutExpo = (
    x1: 0.19,
    y1: 1,
    x2: 0.22,
    y2: 1,
  );

  /// Expo ease-in-out.
  static const CoreCubicBezier easeInOutExpo = (x1: 1, y1: 0, x2: 0, y2: 1);

  // === Circ (3) — circular ===

  /// Circ ease-in.
  static const CoreCubicBezier easeInCirc = (
    x1: 0.6,
    y1: 0.04,
    x2: 0.98,
    y2: 0.335,
  );

  /// Circ ease-out.
  static const CoreCubicBezier easeOutCirc = (
    x1: 0.075,
    y1: 0.82,
    x2: 0.165,
    y2: 1,
  );

  /// Circ ease-in-out.
  static const CoreCubicBezier easeInOutCirc = (
    x1: 0.785,
    y1: 0.135,
    x2: 0.15,
    y2: 0.86,
  );

  // === Back (3) — overshoot ===

  /// Back ease-in (pull back, then go).
  static const CoreCubicBezier easeInBack = (
    x1: 0.6,
    y1: -0.28,
    x2: 0.735,
    y2: 0.045,
  );

  /// Back ease-out (overshoot, then settle).
  static const CoreCubicBezier easeOutBack = (
    x1: 0.175,
    y1: 0.885,
    x2: 0.32,
    y2: 1.275,
  );

  /// Back ease-in-out (overshoot on both ends).
  static const CoreCubicBezier easeInOutBack = (
    x1: 0.68,
    y1: -0.55,
    x2: 0.265,
    y2: 1.55,
  );

  // === Flutter special (5) ===

  /// Material Design standard.
  static const CoreCubicBezier fastOutSlowIn = (
    x1: 0.4,
    y1: 0,
    x2: 0.2,
    y2: 1,
  );

  /// Fast at edges, slow in the middle.
  static const CoreCubicBezier slowMiddle = (
    x1: 0.15,
    y1: 0.85,
    x2: 0.85,
    y2: 0.15,
  );

  /// Apple iOS-style swipe-back curve.
  static const CoreCubicBezier fastLinearToSlowEaseIn = (
    x1: 0.18,
    y1: 1,
    x2: 0.04,
    y2: 1,
  );

  /// Slow start → linear end.
  static const CoreCubicBezier easeInToLinear = (
    x1: 0.67,
    y1: 0.03,
    x2: 0.65,
    y2: 0.09,
  );

  /// Linear start → slow end.
  static const CoreCubicBezier linearToEaseOut = (
    x1: 0.35,
    y1: 0.91,
    x2: 0.33,
    y2: 0.97,
  );

  // === Alias tier (semantic) ===
  //
  // The raw catalogue above holds 34 curves because CSS and Flutter name
  // that many; a design system does not need 34 distinct decisions. These
  // four aliases plus [linear] cover the use cases a component actually
  // chooses between, and component defaults reference them. The raw curves
  // stay available for the rare case that genuinely needs a specific one.
  //
  // The distinction each alias encodes is direction of travel, because that
  // is what the eye reads: something arriving should settle, something
  // leaving should get out of the way, and something merely changing should
  // do both symmetrically.

  /// Movement between two on-screen states — most UI transitions.
  ///
  /// Symmetric acceleration and deceleration. Maps to [easeInOut].
  static const CoreCubicBezier move = easeInOut;

  /// Elements entering the screen — fast in, settling at rest.
  ///
  /// Maps to [easeOut]. Distinct from [CoreEasingFunction.decelerate], which
  /// is the Android `DecelerateInterpolator` polynomial and not expressible
  /// as a single cubic-bezier; prefer this alias unless that exact Android
  /// curve is required.
  static const CoreCubicBezier enter = easeOut;

  /// Elements leaving the screen — starts at rest, accelerates away.
  ///
  /// Maps to [easeIn]. Exits are read as "gone" the moment they start
  /// moving, so they need no settle.
  static const CoreCubicBezier exit = easeIn;

  /// Tactile interaction — slight overshoot before settling.
  ///
  /// Maps to [easeOutBack]. For physics-driven motion with real mass use
  /// `CoreSpringConfig` instead; this is the cubic-bezier approximation for
  /// CSS transitions and implicit Flutter animations.
  static const CoreCubicBezier feedback = easeOutBack;

  // [linear] intentionally has no separate alias — the raw token already
  // carries the right name. Reserve it for loop animations (spinners,
  // shimmer); a linear one-shot transition reads as mechanical.

  // === CSS variable scale (kebab-case keys for `--easing-*`) ===

  /// CSS variable key record for compile-safe interpolation.
  ///
  /// Usage: `var(--easing-${CoreEasing.scale.easeOut})` →
  /// `var(--easing-ease-out)`.
  ///
  /// The four alias keys (`standard` / `decelerate` / `accelerate` /
  /// `spring`) duplicate the CSS value of their pinned raw key
  /// (`easeInOut` / `easeOut` / `easeIn` / `easeOutBack`) rather than
  /// introducing a second `--easing-*` variable — there is exactly one
  /// variable per curve, and the alias is a second Dart-side name for the
  /// same key. Web call sites that think in alias terms (`CoreEasing.scale.
  /// spring`) get one without inventing a raw-curve name for a value they
  /// chose semantically.
  static const ({
    String accelerate,
    String decelerate,
    String ease,
    String easeIn,
    String easeInBack,
    String easeInCirc,
    String easeInCubic,
    String easeInExpo,
    String easeInOut,
    String easeInOutBack,
    String easeInOutCirc,
    String easeInOutCubic,
    String easeInOutExpo,
    String easeInOutQuad,
    String easeInOutQuart,
    String easeInOutQuint,
    String easeInOutSine,
    String easeInQuad,
    String easeInQuart,
    String easeInQuint,
    String easeInSine,
    String easeInToLinear,
    String easeOut,
    String easeOutBack,
    String easeOutCirc,
    String easeOutCubic,
    String easeOutExpo,
    String easeOutQuad,
    String easeOutQuart,
    String easeOutQuint,
    String easeOutSine,
    String fastLinearToSlowEaseIn,
    String fastOutSlowIn,
    String linear,
    String linearToEaseOut,
    String slowMiddle,
    String spring,
    String standard,
  })
  scale = (
    linear: 'linear',
    ease: 'ease',
    easeIn: 'ease-in',
    easeOut: 'ease-out',
    easeInOut: 'ease-in-out',
    easeInSine: 'ease-in-sine',
    easeOutSine: 'ease-out-sine',
    easeInOutSine: 'ease-in-out-sine',
    easeInQuad: 'ease-in-quad',
    easeOutQuad: 'ease-out-quad',
    easeInOutQuad: 'ease-in-out-quad',
    easeInCubic: 'ease-in-cubic',
    easeOutCubic: 'ease-out-cubic',
    easeInOutCubic: 'ease-in-out-cubic',
    easeInQuart: 'ease-in-quart',
    easeOutQuart: 'ease-out-quart',
    easeInOutQuart: 'ease-in-out-quart',
    easeInQuint: 'ease-in-quint',
    easeOutQuint: 'ease-out-quint',
    easeInOutQuint: 'ease-in-out-quint',
    easeInExpo: 'ease-in-expo',
    easeOutExpo: 'ease-out-expo',
    easeInOutExpo: 'ease-in-out-expo',
    easeInCirc: 'ease-in-circ',
    easeOutCirc: 'ease-out-circ',
    easeInOutCirc: 'ease-in-out-circ',
    easeInBack: 'ease-in-back',
    easeOutBack: 'ease-out-back',
    easeInOutBack: 'ease-in-out-back',
    fastOutSlowIn: 'fast-out-slow-in',
    slowMiddle: 'slow-middle',
    fastLinearToSlowEaseIn: 'fast-linear-to-slow-ease-in',
    easeInToLinear: 'ease-in-to-linear',
    linearToEaseOut: 'linear-to-ease-out',
    standard: 'ease-in-out',
    decelerate: 'ease-out',
    accelerate: 'ease-in',
    spring: 'ease-out-back',
  );
}

/// Evaluates a [CoreCubicBezier] the way a CSS `transition-timing-function`
/// does.
///
/// The curve is a timing function: its `x` axis is the share of the duration
/// that has gone by and its `y` axis is the share of the change that has
/// happened by then. [transform] answers the second for the first, so a
/// motion that the Web hands to the browser as `cubic-bezier(...)` and that
/// Flutter drives through `Cubic(...)` can be written down once, as numbers,
/// and checked against both.
extension CoreCubicBezierTransform on CoreCubicBezier {
  /// The share of the change done when [t] (0 to 1) of the duration has
  /// elapsed. Clamped: before the start nothing has happened, after the end
  /// all of it has.
  ///
  /// `x1` and `x2` stay within 0 to 1, as CSS requires, which keeps `x` rising
  /// with the curve's parameter, so the parameter for a given [t] is found
  /// by halving. Fifty-two halvings narrow it to the width of a double.
  double transform(double t) {
    assert(
      x1 >= 0 && x1 <= 1 && x2 >= 0 && x2 <= 1,
      'A timing function keeps its x control points within 0 to 1.',
    );
    if (t <= 0) return 0;
    if (t >= 1) return 1;

    var low = 0.0;
    var high = 1.0;
    var parameter = t;
    for (var i = 0; i < 52; i++) {
      parameter = (low + high) / 2;
      if (_bezier(x1, x2, parameter) < t) {
        low = parameter;
      } else {
        high = parameter;
      }
    }

    return _bezier(y1, y2, parameter);
  }
}

/// One coordinate of a cubic Bezier from (0, 0) to (1, 1) with control
/// points [a] and [b], at curve parameter [s].
double _bezier(double a, double b, double s) {
  final u = 1 - s;

  return 3 * u * u * s * a + 3 * u * s * s * b + s * s * s;
}

/// Non-cubic-bezier easing functions (9개).
///
/// Spec curves that cannot be represented as a single cubic-bezier — bounce
/// / elastic / decelerate / Material Design 3 ThreePointCubic / iOS 16
/// page transition. Each platform implements these natively (Flutter
/// `Curves.bounceOut`, custom JS easing function on the web).
enum CoreEasingFunction {
  /// Android `DecelerateInterpolator` — `1 - (1-t)^2`.
  decelerate,

  /// Bounce at the start of the animation.
  bounceIn,

  /// Bounce at the end of the animation.
  bounceOut,

  /// Bounce on both ends.
  bounceInOut,

  /// Elastic oscillation at the start.
  elasticIn,

  /// Elastic oscillation at the end.
  elasticOut,

  /// Elastic oscillation on both ends.
  elasticInOut,

  /// Material Design 3 emphasized curve (two cubics sharing a midpoint).
  easeInOutCubicEmphasized,

  /// Apple iOS 16 page transition curve (two cubics sharing a midpoint).
  fastEaseInToSlowEaseOut,
}
