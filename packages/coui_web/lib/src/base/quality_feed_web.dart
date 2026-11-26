/// Feeds the quality governor from the browser: the `requestAnimationFrame`
/// loop, the signs that the page is in motion, the visibility of the tab and
/// the reduce-transparency preference.
///
/// Everything it decides is `WebQualitySampler`'s; this file is only the
/// listeners and the loop, so it is the one part a VM test cannot run and the
/// Chrome probe (`tool/parity/test/web/adaptive_quality_probe_test.dart`)
/// does.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/quality_sampler.dart';
import 'package:web/web.dart' as web;

/// The signs that a page is in motion, listened for on the document in the
/// capture phase and passively (a handler here must never delay a scroll).
///
/// A scroll does not bubble, a transition or an animation does; capture takes
/// all of them from one place.
const List<String> _kMotionEvents = [
  'pointerdown',
  'pointermove',
  'wheel',
  'touchmove',
  'scroll',
  'keydown',
  'transitionrun',
  'animationstart',
];

/// The entry type a browser reports a frame that kept the page from painting
/// for more than fifty milliseconds with.
const String _kLongFrameEntry = 'long-animation-frame';

/// Where the reduce-transparency preference is read.
const String _kReducedTransparencyQuery =
    '(prefers-reduced-transparency: reduce)';

/// Runs one [WebQualitySampler] in a browser.
final class WebQualityFeed {
  WebQualityFeed._(this._sampler);

  /// Starts measuring for [stated], or returns null when there is nothing to
  /// decide (a tier is forced, or there is only one rung).
  static WebQualityFeed? start({
    required CoreAdaptiveQuality stated,
    required void Function(CoreQualityChange change) onChange,
  }) {
    final sampler = WebQualitySampler(stated: stated, onChange: onChange);
    if (sampler.governor == null) return null;

    return WebQualityFeed._(sampler).._attach();
  }

  final WebQualitySampler _sampler;
  final List<void Function()> _detach = [];
  web.PerformanceObserver? _longFrames;
  int? _frame;
  late final JSFunction _tickCallback = ((JSNumber timestamp) {
    _frame = null;
    _sampler.onFrame(timestamp.toDartDouble);
    _ensureLoop();
  }).toJS;

  /// Stops frame measurement until the returned hold is released.
  CoreQualityHold hold() => _sampler.hold();

  double get _now => web.window.performance.now();

  void _attach() {
    final document = web.document;

    final motion = ((web.Event _) => _handleMotion()).toJS;
    for (final type in _kMotionEvents) {
      document.addEventListener(
        type,
        motion,
        web.AddEventListenerOptions(capture: true, passive: true),
      );
      _detach.add(
        () => document.removeEventListener(
          type,
          motion,
          web.EventListenerOptions(capture: true),
        ),
      );
    }

    final visibility = ((web.Event _) {
      _sampler.onVisibilityChanged(hidden: document.hidden, nowMs: _now);
      _ensureLoop();
    }).toJS;
    document.addEventListener('visibilitychange', visibility);
    _detach.add(
      () => document.removeEventListener('visibilitychange', visibility),
    );
    if (document.hidden) {
      _sampler.onVisibilityChanged(hidden: true, nowMs: _now);
    }

    final reduced = web.window.matchMedia(_kReducedTransparencyQuery);
    final reducedChanged = ((web.Event _) {
      _sampler.onReducedTransparency(reduced: reduced.matches);
      _ensureLoop();
    }).toJS;
    reduced.addEventListener('change', reducedChanged);
    _detach.add(() => reduced.removeEventListener('change', reducedChanged));
    if (reduced.matches) _sampler.onReducedTransparency(reduced: true);

    if (web.PerformanceObserver.supportedEntryTypes.toDart.any(
      (type) => type.toDart == _kLongFrameEntry,
    )) {
      // A frame that held the page up for 50 ms is a sign it is in motion
      // even when no input says so. It is not a sample: the interval of that
      // frame is measured by the loop, when the loop is running.
      //
      // The callback is typed `JSAny`, not by what the entry list is: the list
      // is an object, not an array, and a wrapper typed `JSArray` throws on
      // every call — silently, inside the browser's own dispatch.
      final observer = web.PerformanceObserver(
        ((JSAny _, JSAny _) => _handleMotion()).toJS,
      )..observe(web.PerformanceObserverInit(type: _kLongFrameEntry));
      _longFrames = observer;
    }

    // The page has just loaded: its first transitions are motion.
    _handleMotion();
  }

  void _handleMotion() {
    _sampler.onActivity(_now);
    _ensureLoop();
  }

  void _ensureLoop() {
    if (_frame != null || !_sampler.wantsFrames) return;
    _frame = web.window.requestAnimationFrame(_tickCallback);
  }

  /// Stops listening and measuring.
  void dispose() {
    final frame = _frame;
    if (frame != null) web.window.cancelAnimationFrame(frame);
    _frame = null;
    _longFrames?.disconnect();
    _longFrames = null;
    for (final detach in _detach) {
      detach();
    }
    _detach.clear();
    _sampler.onReducedTransparency(reduced: false);
  }
}
