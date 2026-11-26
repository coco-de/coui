import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';

/// Mathematical implementations of [CoreEasingFunction] tokens for the web.
///
/// Spec source: `CoUI_Easing_Token_Specification.md` §5.3 (JavaScript easing).
/// Equivalent to Flutter's `Curves.bounceOut` / `Curves.elasticOut` etc.
///
/// Usage:
/// ```dart
/// final progress = CoreEasingFunction.bounceOut.apply(t);
/// ```
extension CoreEasingFunctionMath on CoreEasingFunction {
  /// Evaluates the easing function at [t] (clamped to `[0, 1]`).
  double apply(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return switch (this) {
      .decelerate => _decelerate(clamped),
      .bounceIn => _bounceIn(clamped),
      .bounceOut => _bounceOut(clamped),
      .bounceInOut => _bounceInOut(clamped),
      .elasticIn => _elasticIn(clamped),
      .elasticOut => _elasticOut(clamped),
      .elasticInOut => _elasticInOut(clamped),
      .easeInOutCubicEmphasized => _threePointCubicEaseInOutCubicEmphasized(
        clamped,
      ),
      .fastEaseInToSlowEaseOut => _threePointCubicFastEaseInToSlowEaseOut(
        clamped,
      ),
    };
  }
}

// ─── Decelerate ──────────────────────────────────────────────────────

/// Android `DecelerateInterpolator`: `1 - (1-t)²`.
double _decelerate(double t) {
  final inv = 1 - t;
  return 1 - inv * inv;
}

// ─── Bounce ──────────────────────────────────────────────────────────

double _bounceOut(double t) {
  const n = 7.5625;
  const d = 2.75;
  if (t < 1 / d) {
    return n * t * t;
  }
  if (t < 2 / d) {
    final tt = t - 1.5 / d;
    return n * tt * tt + 0.75;
  }
  if (t < 2.5 / d) {
    final tt = t - 2.25 / d;
    return n * tt * tt + 0.9375;
  }
  final tt = t - 2.625 / d;
  return n * tt * tt + 0.984375;
}

double _bounceIn(double t) => 1 - _bounceOut(1 - t);

double _bounceInOut(double t) =>
    t < 0.5 ? (1 - _bounceOut(1 - 2 * t)) / 2 : (1 + _bounceOut(2 * t - 1)) / 2;

// ─── Elastic ─────────────────────────────────────────────────────────

const double _kElasticPeriod = 0.4;

double _elasticOut(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return math.pow(2, -10 * t) *
          math.sin(
            (t - _kElasticPeriod / 4) * (2 * math.pi) / _kElasticPeriod,
          ) +
      1;
}

double _elasticIn(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return -math.pow(2, 10 * (t - 1)) *
      math.sin(
        (t - 1 - _kElasticPeriod / 4) * (2 * math.pi) / _kElasticPeriod,
      );
}

double _elasticInOut(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  final s = _kElasticPeriod / 4;
  final tt = t * 2 - 1;
  if (tt < 0) {
    return -0.5 *
        math.pow(2, 10 * tt) *
        math.sin((tt - s) * (2 * math.pi) / _kElasticPeriod);
  }
  return math.pow(2, -10 * tt) *
          math.sin((tt - s) * (2 * math.pi) / _kElasticPeriod) *
          0.5 +
      1;
}

// ─── ThreePointCubic ────────────────────────────────────────────────
//
// Flutter `Curves.easeInOutCubicEmphasized` and `Curves.fastEaseInToSlowEaseOut`
// are `ThreePointCubic` curves: two cubic-bezier segments joined at a
// midpoint. Web spec (§5.3) marks these as "별도 구현 필요" and provides no
// reference JS, so this implementation evaluates the y(t) of each segment
// using parametric t (not solved-for-x). Visually close enough for
// motion previews; for pixel-exact MD3 / iOS feel use Flutter platform.

double _bezierY(double t, double p1y, double p2y, double p3y) {
  final inv = 1 - t;
  return 3 * inv * inv * t * p1y + 3 * inv * t * t * p2y + t * t * t * p3y;
}

double _threePointCubic({
  required double t,
  required double mx,
  required double my,
  required double a1y,
  required double b1y,
  required double a2y,
  required double b2y,
}) {
  if (t < mx) {
    final tt = mx == 0 ? 0.0 : t / mx;
    return _bezierY(tt, a1y, b1y, my);
  }
  final span = 1 - mx;
  final tt = span == 0 ? 1.0 : (t - mx) / span;
  // Second segment: P0=(mx,my), P1=a2, P2=b2, P3=(1,1).
  final inv = 1 - tt;
  return inv * inv * inv * my +
      3 * inv * inv * tt * a2y +
      3 * inv * tt * tt * b2y +
      tt * tt * tt * 1;
}

/// Material 3 emphasized curve, control points from Flutter source.
double _threePointCubicEaseInOutCubicEmphasized(double t) => _threePointCubic(
  t: t,
  mx: 0.166666,
  my: 0.4,
  a1y: 0,
  b1y: 0.06,
  a2y: 0.82,
  b2y: 1,
);

/// iOS 16 page transition curve, control points from Flutter source.
double _threePointCubicFastEaseInToSlowEaseOut(double t) => _threePointCubic(
  t: t,
  mx: 0.198,
  my: 0.541,
  a1y: 0.024,
  b1y: 0.3085,
  a2y: 0.7,
  b2y: 0.985,
);
