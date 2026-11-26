/// Web implementation of [FadeScrollMeasurer].
///
/// Uses the viewport's native scroll timeline when supported. The browser
/// updates its three effects from actual geometry, including content/font
/// changes that do not notify ResizeObserver.
///
/// Older engines retain the scroll listener and viewport ResizeObserver,
/// writing the original two CSS variables:
///
///   - `--co-fade-start-alpha` — `0` when the viewport is at the start
///     boundary, `1` otherwise. Removes the leading fade once the user
///     has reached the top / left edge.
///   - `--co-fade-end-alpha` — `0` when the viewport is at the end
///     boundary, `1` otherwise. Mirrors Flutter's
///     `position < maxScrollExtent` check.
///
/// The fallback's [web.ResizeObserver] re-evaluates the boundary state when
/// the viewport size changes.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// Legacy pixel tolerance for the fallback boundary check. Sub-pixel positions
/// (high-DPI displays, momentum scroll) can leave `scrollTop` at e.g.
/// `0.5` while the user is visually at the top — a 1px slack keeps the
/// fade from flickering at the boundary.
const double _kBoundaryToleranceFactor = 1;

// package:web does not yet bind ScrollTimeline. Keep this standard platform
// interop private; unsupported engines continue through the existing measurer.
@JS('ScrollTimeline')
extension type _ScrollTimeline._(JSObject _)
    implements web.AnimationTimeline, JSObject {
  external factory _ScrollTimeline(_ScrollTimelineOptions options);
}

extension type _ScrollTimelineOptions._(JSObject _) implements JSObject {
  external factory _ScrollTimelineOptions({
    required web.Element source,
    required String axis,
  });
}

@JS('globalThis.ScrollTimeline')
external JSAny? get _scrollTimelineConstructor;

@JS('Animation.prototype')
external JSObject get _animationPrototype;

/// Web orchestrator for a single `FadeScroll` viewport.
class FadeScrollMeasurer {
  /// Creates a [FadeScrollMeasurer].
  FadeScrollMeasurer({required this.viewportId, required this.direction});

  /// `id` of the scrollable viewport `<div>` (the inner element that
  /// receives `overflow: auto`).
  final String viewportId;

  /// Scroll axis. Vertical reads `scrollTop` / `scrollHeight` /
  /// `clientHeight`; horizontal swaps to `scrollLeft` / `scrollWidth` /
  /// `clientWidth`.
  final CoreFadeScrollDirection direction;

  web.HTMLElement? _viewport;
  web.ResizeObserver? _resizeObserver;
  JSFunction? _onScroll;
  final List<web.Animation> _timelineAnimations = [];

  /// Resolves the viewport and attaches native effects or the legacy listener
  /// and [web.ResizeObserver]. Repeated calls refresh native carriers without
  /// duplicating effects; the legacy path remains idempotent.
  void attach() {
    if (_viewport != null) {
      if (_timelineAnimations.isNotEmpty) _applyTimelineCarriers();
      return;
    }
    final viewport = web.document.getElementById(viewportId);
    if (viewport == null) return;
    _viewport = viewport as web.HTMLElement;

    final constructor = _scrollTimelineConstructor;
    if (constructor != null &&
        constructor.typeofEquals('function') &&
        _animationPrototype.has('rangeStart') &&
        _animationPrototype.has('rangeEnd')) {
      _attachTimeline(_viewport!);
      _applyTimelineCarriers();
      return;
    }

    _onScroll = _handleScroll.toJS;
    _viewport!.addEventListener('scroll', _onScroll);

    _resizeObserver = web.ResizeObserver(_handleResize.toJS)
      ..observe(_viewport!);

    _applyState();
  }

  /// Cancels owned native effects/carriers or removes the legacy listener
  /// and disconnects its observer.
  /// Idempotent.
  void dispose() {
    final viewport = _viewport;
    if (_timelineAnimations.isNotEmpty) {
      while (_timelineAnimations.isNotEmpty) {
        _timelineAnimations.removeLast().cancel();
      }
      if (viewport != null) {
        viewport.style
          ..removeProperty('--co-fade-timeline-mask')
          ..removeProperty('--co-fade-timeline-gradient')
          ..removeProperty('--co-fade-timeline-start')
          ..removeProperty('--co-fade-timeline-end');
      }
    }
    final onScroll = _onScroll;
    if (viewport != null && onScroll != null) {
      viewport.removeEventListener('scroll', onScroll);
    }
    _resizeObserver?.disconnect();
    _resizeObserver = null;
    _onScroll = null;
    _viewport = null;
  }

  void _attachTimeline(web.HTMLElement viewport) {
    final timeline = _ScrollTimeline(
      _ScrollTimelineOptions(
        source: viewport,
        axis: direction == .horizontal ? 'x' : 'y',
      ),
    );
    web.Animation animate(
      String property, {
      required String fill,
      required String rangeStart,
      required String rangeEnd,
      String from = '1',
      String to = '0',
      String playbackDirection = 'normal',
      String easing = 'steps(1, jump-end)',
    }) => viewport.animate(
      [
            {property: from},
            {property: to},
          ].jsify()!
          as JSObject,
      web.KeyframeAnimationOptions(
        duration: 'auto'.toJS,
        timeline: timeline,
        fill: fill,
        direction: playbackDirection,
        easing: easing,
        rangeStart: rangeStart.toJS,
        rangeEnd: rangeEnd.toJS,
      ),
    );
    _timelineAnimations.addAll([
      // A fit timeline is inactive. Keep both physical endpoints strictly
      // inside this range so a previously finished effect cannot mask fit.
      // `initial` is guaranteed-invalid for an unregistered custom property,
      // selecting mask-image's live gradient fallback without inheriting an
      // outer viewport's fit `none` value.
      animate(
        '--co-fade-timeline-mask',
        from: 'initial',
        to: 'initial',
        fill: 'none',
        rangeStart: '-100%',
        rangeEnd: '200%',
      ),
      animate(
        '--co-fade-timeline-start',
        fill: 'both',
        playbackDirection: 'reverse',
        // Core/Flutter fades beyond the exact start and before the exact end.
        // The legacy anti-flicker tolerance is intentionally not used here.
        rangeStart: '0%',
        rangeEnd: '100%',
      ),
      animate(
        '--co-fade-timeline-end',
        fill: 'both',
        rangeStart: '0%',
        rangeEnd: '100%',
      ),
    ]);
  }

  void _applyTimelineCarriers() {
    _viewport!.style
      ..setProperty('--co-fade-timeline-mask', 'none')
      ..setProperty(
        '--co-fade-timeline-gradient',
        'var(--co-fade-scroll-gradient)',
      )
      ..setProperty('--co-fade-timeline-start', '0')
      ..setProperty('--co-fade-timeline-end', '1');
  }

  void _handleScroll(web.Event event) {
    _applyState();
  }

  void _handleResize(JSAny entries, JSAny observer) {
    _applyState();
  }

  void _applyState() {
    final viewport = _viewport;
    if (viewport == null) return;
    final isHorizontal = direction == .horizontal;
    final scrollPos = isHorizontal ? viewport.scrollLeft : viewport.scrollTop;
    final contentSize = isHorizontal
        ? viewport.scrollWidth
        : viewport.scrollHeight;
    final clientSize = isHorizontal
        ? viewport.clientWidth
        : viewport.clientHeight;
    final maxScroll = contentSize - clientSize;
    final atStart = scrollPos <= _kBoundaryToleranceFactor;
    final atEnd = scrollPos >= maxScroll - _kBoundaryToleranceFactor;
    viewport.style.setProperty(
      '--co-fade-start-alpha',
      atStart ? '0' : '1',
    );
    viewport.style.setProperty(
      '--co-fade-end-alpha',
      atEnd ? '0' : '1',
    );
  }
}
