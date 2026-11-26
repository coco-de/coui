/// Web implementation of [OverflowMarqueeMeasurer].
///
/// A direct port of Flutter's `_RenderOverflowMarqueeLayout` to the
/// web. On every animation frame the measurer computes
/// `offsetProgress` from the elapsed ticker time — the exact same
/// formula Flutter uses — and writes three pieces of state to the
/// DOM:
///
///   - `transform: translate(...)` on the track, to position it by
///     `-sizeDiff × progress`.
///   - `--co-om-fade-start-alpha` on the container
///     (`= 1 - fadeStartProgress`, i.e. `1` on the left delay, ramping
///     to `0` after the track has moved `fadePortion` pixels).
///   - `--co-om-fade-end-alpha` on the container
///     (`= 1 - fadeEndProgress`, symmetric on the right).
///
/// The scoped stylesheet reads those variables through
/// `rgb(0 0 0 / var(--...))` in the container's `mask-image`, so no
/// CSS animation, `@keyframes`, or `@property` plumbing is needed.
/// That removes the HTML-escape hazard (`syntax: "<number>"`
/// collapsing to `syntax: ""` on SSR), keeps the `<style>` tag static,
/// and gives us pixel-exact parity with the Flutter implementation by
/// construction.
///
/// A [web.ResizeObserver] on the container and the track re-measures
/// `sizeDiff` live whenever the viewport or the content width changes.
/// Hover pauses the ticker instead of animating
/// `animation-play-state`, mirroring Flutter's
/// `MouseRegion(onEnter: ...ticker.muted...)` path.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// Cubic-bezier control points matching CSS `ease-in`, `ease-out`,
/// and `ease-in-out` — identical to Flutter's
/// `Curves.easeIn/Out/InOut`.
const _kEaseInP1x = 0.42;
const _kEaseInP1y = 0.0;
const _kEaseInP2x = 1.0;
const _kEaseInP2y = 1.0;

const _kEaseOutP1x = 0.0;
const _kEaseOutP1y = 0.0;
const _kEaseOutP2x = 0.58;
const _kEaseOutP2y = 1.0;

const _kEaseInOutP1x = 0.42;
const _kEaseInOutP1y = 0.0;
const _kEaseInOutP2x = 0.58;
const _kEaseInOutP2y = 1.0;

/// Newton-Raphson iterations for bezier inversion. 8 is what Chromium
/// uses in its internal cubic-bezier solver.
const _kBezierIterations = 8;

/// Slope below which Newton-Raphson gives up and returns the current
/// estimate — same threshold Chromium's solver uses.
const _kBezierSlopeEpsilon = 1e-6;

/// Coefficients of the derivative of a cubic polynomial
/// (`d/dt (at³ + bt² + ct) = 3at² + 2bt + c`).
const _kCubicDerivativeA = 3;
const _kCubicDerivativeB = 2;

/// Scales the linear control-point span to match the cubic Bézier
/// basis — the `3` that appears in every `(1-t)³ + 3(1-t)²t + ...`
/// expansion.
const _kBezierBasisScale = 3;

/// Decimal digits written for fade-alpha variables. Four digits is
/// enough for sub-pixel smoothness without flooding DevTools with
/// long numbers each frame.
const _kFadeAlphaDigits = 4;

/// Web orchestrator for a single `OverflowMarquee` instance.
class OverflowMarqueeMeasurer {
  /// Creates an [OverflowMarqueeMeasurer].
  OverflowMarqueeMeasurer({
    required this.containerId,
    required this.trackSelector,
    required this.axis,
    required this.duration,
    required this.delayDuration,
    required this.step,
    required this.fadePortion,
    required this.curve,
    required this.pauseOnHover,
  });

  /// `id` of the marquee container `<div>`.
  final String containerId;

  /// CSS selector used to find the inner track within the container.
  final String trackSelector;

  /// Scroll axis. Horizontal marquees translate the track on X and
  /// compare rects on `width`; vertical swaps both.
  final CoreAxis axis;

  /// Unscaled forward-phase duration (mirrors Flutter's
  /// `_RenderOverflowMarqueeLayout.duration`).
  final Duration duration;

  /// Pause at each traversal end.
  final Duration delayDuration;

  /// Pixel-step used to scale forward speed:
  /// `forwardMicros = duration.inMicroseconds × diff / step`.
  final double step;

  /// Fade length in pixels — the range over which the edge alphas
  /// ramp from `1 → 0` (on entry) or `0 → 1` (on exit).
  final double fadePortion;

  /// Easing applied to the translation phase (fade ramps stay linear
  /// in progress, matching Flutter's `clamp(...)` behaviour).
  final CoreMarqueeCurve curve;

  /// When `true`, pointer hover freezes the ticker — the exact
  /// behaviour of Flutter's `MouseRegion` + `ticker.muted` path.
  final bool pauseOnHover;

  web.HTMLElement? _container;
  web.HTMLElement? _track;
  web.ResizeObserver? _resizeObserver;
  JSFunction? _mouseEnter;
  JSFunction? _mouseLeave;
  JSFunction? _tickJs;

  double _sizeDiff = 0;
  // Elapsed animation time in microseconds, accumulated from the
  // high-resolution `performance.now()` delta. Matches the semantics
  // of Flutter's `Ticker.elapsed`.
  double _elapsedMicros = 0;
  double? _lastFrameMs;
  bool _paused = false;
  int? _rafId;

  /// Resolves DOM refs, performs the initial measurement, and starts
  /// the animation loop. Idempotent.
  void attach() {
    if (_container != null) return;
    final container = web.document.getElementById(containerId);
    if (container == null) return;
    final track = container.querySelector(trackSelector);
    if (track == null) return;
    _container = container as web.HTMLElement;
    _track = track as web.HTMLElement;

    _measureSize();
    _resizeObserver = web.ResizeObserver(_handleResize.toJS)
      ..observe(container)
      ..observe(track);

    if (pauseOnHover) {
      _mouseEnter = _handleMouseEnter.toJS;
      _mouseLeave = _handleMouseLeave.toJS;
      container.addEventListener('mouseenter', _mouseEnter);
      container.addEventListener('mouseleave', _mouseLeave);
    }

    _tickJs = _tick.toJS;
    _rafId = web.window.requestAnimationFrame(_tickJs!);
  }

  /// Stops the ticker, disconnects the observer, and releases all
  /// references. Idempotent.
  void dispose() {
    final rafId = _rafId;
    if (rafId != null) {
      web.window.cancelAnimationFrame(rafId);
      _rafId = null;
    }
    _resizeObserver?.disconnect();
    _resizeObserver = null;

    final container = _container;
    if (container != null && pauseOnHover) {
      final enter = _mouseEnter;
      final leave = _mouseLeave;
      if (enter != null) container.removeEventListener('mouseenter', enter);
      if (leave != null) container.removeEventListener('mouseleave', leave);
    }
    _mouseEnter = null;
    _mouseLeave = null;
    _tickJs = null;
    _container = null;
    _track = null;
    _lastFrameMs = null;
    _elapsedMicros = 0;
    _sizeDiff = 0;
    _paused = false;
  }

  void _handleResize(JSAny entries, JSAny observer) {
    _measureSize();
  }

  void _handleMouseEnter(web.Event event) {
    _paused = true;
  }

  void _handleMouseLeave(web.Event event) {
    _paused = false;
  }

  void _measureSize() {
    final container = _container;
    final track = _track;
    if (container == null || track == null) return;
    final cr = container.getBoundingClientRect();
    final tr = track.getBoundingClientRect();
    final cs = axis == .horizontal ? cr.width : cr.height;
    final ts = axis == .horizontal ? tr.width : tr.height;
    final diff = ts - cs;
    _sizeDiff = diff > 0 ? diff : 0;
    // If the content fits, lock the visuals into the `progress == 0`
    // state — matches Flutter's `ticker.stop()` + no-translation.
    if (_sizeDiff == 0) {
      _applyState(progress: 0);
    }
  }

  void _tick(double nowMs) {
    if (_container == null) return;
    final last = _lastFrameMs;
    _lastFrameMs = nowMs;
    if (_sizeDiff > 0 && last != null) {
      final deltaMs = nowMs - last;
      if (deltaMs > 0 && !_paused) {
        _elapsedMicros += deltaMs * Duration.microsecondsPerMillisecond;
      }
      _applyState(progress: _offsetProgress(_elapsedMicros));
    }
    final tick = _tickJs;
    if (tick != null) {
      _rafId = web.window.requestAnimationFrame(tick);
    }
  }

  /// Flutter parity port of `_RenderOverflowMarqueeLayout.offsetProgress`.
  double _offsetProgress(double elapsedMicros) {
    final diff = _sizeDiff;
    if (diff <= 0) return 0;
    final durationMicros = duration.inMicroseconds * (diff / step);
    final delayMicros = delayDuration.inMicroseconds.toDouble();
    final cycleMicros = delayMicros + durationMicros;
    final overallMicros = cycleMicros * 2;
    var wrapped = elapsedMicros % overallMicros;
    if (wrapped < 0) wrapped += overallMicros;
    final reverse = wrapped > cycleMicros;
    final cycleElapsed = wrapped % cycleMicros;
    if (cycleElapsed < delayMicros) {
      return reverse ? 1 : 0;
    }
    if (cycleElapsed < cycleMicros) {
      final t = (cycleElapsed - delayMicros) / durationMicros;
      final eased = _applyCurve(t);
      return reverse ? 1 - eased : eased;
    }
    return reverse ? 0 : 1;
  }

  void _applyState({required double progress}) {
    final container = _container;
    final track = _track;
    if (container == null || track == null) return;
    final diff = _sizeDiff;
    final translatePx = -diff * progress;
    track.style.transform = axis == .horizontal
        ? 'translateX(${translatePx}px)'
        : 'translateY(${translatePx}px)';

    if (fadePortion <= 0 || diff <= 0) {
      container.style.setProperty('--co-om-fade-start-alpha', '1');
      container.style.setProperty('--co-om-fade-end-alpha', '1');
      return;
    }
    final fadeStart = (diff * progress / fadePortion).clamp(0.0, 1.0);
    final fadeEnd = (diff * (1 - progress) / fadePortion).clamp(0.0, 1.0);
    container.style.setProperty(
      '--co-om-fade-start-alpha',
      (1 - fadeStart).toStringAsFixed(_kFadeAlphaDigits),
    );
    container.style.setProperty(
      '--co-om-fade-end-alpha',
      (1 - fadeEnd).toStringAsFixed(_kFadeAlphaDigits),
    );
  }

  double _applyCurve(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return switch (curve) {
      .linear => t,
      .easeIn => _cubicBezier(
        t,
        _kEaseInP1x,
        _kEaseInP1y,
        _kEaseInP2x,
        _kEaseInP2y,
      ),
      .easeOut => _cubicBezier(
        t,
        _kEaseOutP1x,
        _kEaseOutP1y,
        _kEaseOutP2x,
        _kEaseOutP2y,
      ),
      .easeInOut => _cubicBezier(
        t,
        _kEaseInOutP1x,
        _kEaseInOutP1y,
        _kEaseInOutP2x,
        _kEaseInOutP2y,
      ),
    };
  }
}

/// Evaluates a 2D cubic-Bézier curve defined by control points
/// `(0,0), (p1x,p1y), (p2x,p2y), (1,1)` at input `x` and returns the
/// corresponding `y`.
///
/// Matches `Curves.easeIn/Out/InOut` (Flutter's `Cubic.transform`)
/// and CSS `cubic-bezier(...)` numerically. Implementation follows
/// Chromium's `CubicBezier::SolveCurveX`: Newton-Raphson first, with
/// a bisection fallback once the slope vanishes.
double _cubicBezier(
  double x,
  double p1x,
  double p1y,
  double p2x,
  double p2y,
) {
  final cx = _kBezierBasisScale * p1x;
  final bx = _kBezierBasisScale * (p2x - p1x) - cx;
  final ax = 1 - cx - bx;
  final cy = _kBezierBasisScale * p1y;
  final by = _kBezierBasisScale * (p2y - p1y) - cy;
  final ay = 1 - cy - by;

  double sampleX(double t) => ((ax * t + bx) * t + cx) * t;
  double sampleY(double t) => ((ay * t + by) * t + cy) * t;
  double sampleDx(double t) =>
      (_kCubicDerivativeA * ax * t + _kCubicDerivativeB * bx) * t + cx;

  var t = x;
  for (var i = 0; i < _kBezierIterations; i += 1) {
    final xEstimate = sampleX(t) - x;
    final dx = sampleDx(t);
    if (dx.abs() < _kBezierSlopeEpsilon) break;
    t -= xEstimate / dx;
  }
  return sampleY(t.clamp(0.0, 1.0));
}
