import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Shares the thumb's actual compositor timeline, including CSS reversal.
/// The lens remains a sibling so it retains its own surface depth.
class ToggleLensRuntime {
  ToggleLensRuntime({required this.thumbId, required this.lensId});
  final String thumbId;
  final String lensId;
  int? _frame;
  web.Animation? _animation;
  web.MediaQueryList? _reduce;
  JSFunction? _preferenceListener;
  bool _disposed = false;

  void follow() {
    var waited = 0;
    void attach(double now) {
      _frame = null;
      if (_disposed) return;
      final thumb = web.document.getElementById(thumbId);
      final lens = web.document.getElementById(lensId);
      if (thumb == null || lens is! web.HTMLElement) {
        if (++waited < 30)
          _frame = web.window.requestAnimationFrame(attach.toJS);
        return;
      }
      final reduce = _reduce = web.window.matchMedia(
        '(prefers-reduced-motion: reduce)',
      );
      void stop() {
        _animation?.cancel();
        lens.style.setProperty('opacity', '0', 'important');
      }

      if (reduce.matches) {
        stop();
        return;
      }
      _preferenceListener = ((web.Event event) {
        if (reduce.matches) stop();
      }).toJS;
      reduce.addEventListener('change', _preferenceListener);
      for (final transition in thumb.getAnimations().toDart) {
        final effect = transition.effect;
        if (effect == null) continue;
        final frames = (effect as web.KeyframeEffect).getKeyframes();
        if (frames.toDart.isEmpty || !frames.toDart.first.has('transform'))
          continue;
        // Reuse computed keyframes and the browser's shortened reversal
        // duration. A second fixed endpoint animation would jump on reversal.
        final timing = effect.getTiming()..fill = 'both';
        final mirror = _animation = lens.animate(frames, timing)
          ..playbackRate = transition.playbackRate;
        void syncStart(double now) {
          _frame = null;
          if (_disposed || reduce.matches) return;
          final start = transition.startTime;
          if (start != null) {
            mirror.startTime = start;
          } else if (++waited < 30) {
            _frame = web.window.requestAnimationFrame(syncStart.toJS);
          }
        }

        if (transition.startTime != null) {
          mirror.startTime = transition.startTime;
        } else {
          _frame = web.window.requestAnimationFrame(syncStart.toJS);
        }
        return;
      }
      // Zero duration / a completed transition has one composited pose.
      lens.style.transform = web.window.getComputedStyle(thumb).transform;
    }

    _frame = web.window.requestAnimationFrame(attach.toJS);
  }

  void dispose() {
    _disposed = true;
    if (_frame != null) web.window.cancelAnimationFrame(_frame!);
    if (_preferenceListener != null) {
      _reduce?.removeEventListener('change', _preferenceListener);
    }
    _animation?.cancel();
  }
}
