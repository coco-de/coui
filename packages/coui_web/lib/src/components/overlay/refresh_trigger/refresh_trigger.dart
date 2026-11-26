import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/loading/loading.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/refresh_trigger/refresh_trigger_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// A pull-to-refresh trigger with a unified stage-driven indicator.
///
/// `RefreshTrigger` wraps scrollable [child] content and shows a
/// surface indicator whose label / tone reacts to the current
/// [CoreRefreshStage]. The stage is driven internally by the pull
/// gesture (pointer events + scroll-boundary detection, mirroring the
/// Flutter twin's overscroll handling); supplying a non-idle [stage]
/// forces a controlled stage instead so the host can drive the
/// indicator from external state.
///
/// Every indicator chrome / dimensional / animation value flows
/// through the single [refreshTriggerStyle] field — see
/// [CoreRefreshTriggerStyle] for the merge chain.
///
/// ```dart
/// RefreshTrigger(
///   onRefresh: () async {
///     await fetchData();
///   },
///   child: div([/* scrollable content */]),
/// )
/// ```
///
/// surface:functional — the indicator rides an absolutely-positioned rail
/// over the list it refreshes.
class RefreshTrigger extends UiStatefulComponent
    implements CoreRefreshTriggerContract<Component> {
  /// Creates a [RefreshTrigger].
  const RefreshTrigger({
    required this.child,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.stage = CoreRefreshStage.defaultStage,
    this.direction = CoreRefreshDirection.defaultDirection,
    this.reverse = false,
    this.pullText,
    this.releaseText,
    this.refreshingText,
    this.completedText,
    this.minExtent = CoreRefreshTriggerStyle.defaultMinExtent,
    this.maxExtent = CoreRefreshTriggerStyle.defaultMaxExtent,
    this.onRefresh,
    this.refreshTriggerStyle,
  });

  @override
  final Component child;

  @override
  final CoreRefreshStage stage;

  @override
  final CoreRefreshDirection direction;

  @override
  final bool reverse;

  @override
  final String? pullText;

  @override
  final String? releaseText;

  @override
  final String? refreshingText;

  @override
  final String? completedText;

  @override
  final double minExtent;

  @override
  final double maxExtent;

  @override
  final Future<void> Function()? onRefresh;

  @override
  final CoreRefreshTriggerStyle? refreshTriggerStyle;

  /// Returns a copy of this [RefreshTrigger] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  RefreshTrigger copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    CoreRefreshStage? stage,
    CoreRefreshDirection? direction,
    bool? reverse,
    String? pullText,
    String? releaseText,
    String? refreshingText,
    String? completedText,
    double? minExtent,
    double? maxExtent,
    Future<void> Function()? onRefresh,
    CoreRefreshTriggerStyle? refreshTriggerStyle,
    Component? child,
  }) {
    return RefreshTrigger(
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      stage: stage ?? this.stage,
      direction: direction ?? this.direction,
      reverse: reverse ?? this.reverse,
      pullText: pullText ?? this.pullText,
      releaseText: releaseText ?? this.releaseText,
      refreshingText: refreshingText ?? this.refreshingText,
      completedText: completedText ?? this.completedText,
      minExtent: minExtent ?? this.minExtent,
      maxExtent: maxExtent ?? this.maxExtent,
      onRefresh: onRefresh ?? this.onRefresh,
      refreshTriggerStyle: refreshTriggerStyle ?? this.refreshTriggerStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<RefreshTrigger> createState() => RefreshTriggerState();
}

/// Chain sugar mirroring the Flutter `RefreshTrigger.withStyle` extension —
/// merges a [CoreRefreshTriggerStyle] patch into
/// [RefreshTrigger.refreshTriggerStyle] via the existing
/// [RefreshTrigger.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreRefreshTriggerStyle.merge` right-side-wins semantics).
extension RefreshTriggerStyleChain on RefreshTrigger {
  /// Returns a copy of this [RefreshTrigger] with [patch] merged into
  /// [refreshTriggerStyle] (patch fields win on conflict).
  RefreshTrigger withStyle(CoreRefreshTriggerStyle patch) => copyWith(
    refreshTriggerStyle:
        (refreshTriggerStyle ?? const CoreRefreshTriggerStyle()).merge(patch),
  );
}

/// Public state for [RefreshTrigger] — exposed so hosts can drive a
/// programmatic refresh via `GlobalStateKey<RefreshTriggerState>` and
/// [refresh] (in addition to the pull gesture).
class RefreshTriggerState extends State<RefreshTrigger> {
  /// Gesture-driven stage — the controlled [RefreshTrigger.stage] wins
  /// whenever it is non-idle (mirrors the Flutter `_effectiveStage`).
  CoreRefreshStage _gestureStage = .idle;

  /// Accumulated pull extent in px, positive along the pull direction.
  double _currentExtent = 0;

  /// `true` between the pointer-down that armed the gesture and its
  /// release — drops the indicator transition so it tracks the pointer.
  bool _dragging = false;

  /// `true` from pointer-down until release; the gesture only arms
  /// (enters `pulling`) once the move starts at the scroll boundary.
  bool _armed = false;

  /// Last pointer coordinate along the pull axis — deltas accumulate
  /// into [_currentExtent] (mirrors the Flutter scroll-delta stream).
  double _lastCoord = 0;

  Future<void>? _currentFuture;
  int _futureCount = 0;

  /// Timer that returns the indicator to idle after the completion
  /// hold. Held so it can be cancelled on dispose.
  Timer? _completeTimer;

  CoreRefreshStage get _effectiveStage =>
      component.stage != .idle ? component.stage : _gestureStage;

  bool get _isVertical => component.direction == .vertical;

  /// Applies the standard decelerate easing — `1 - (1 - t)²`, the same
  /// curve the Flutter twin uses (`CoreEasingFunction.decelerate`) to
  /// shape the over-pull resistance past [RefreshTrigger.minExtent].
  double _decelerate(double t) => 1 - (1 - t) * (1 - t);

  /// Maps the raw pull [extent] (px) onto the displayed indicator
  /// offset — linear up to `minExtent`, decelerating resistance up to
  /// `maxExtent` past it (mirrors the Flutter `_calculateSafeExtent`).
  double _calculateSafeExtent(double extent) {
    if (extent > component.minExtent) {
      final relativeExtent = extent - component.minExtent;
      final maxExtent = component.maxExtent;
      final diff = (maxExtent - component.minExtent) - relativeExtent;
      final diffNormalized = diff / (maxExtent - component.minExtent);

      return maxExtent - _decelerate(diffNormalized.clamp(0.0, 1.0)) * diff;
    }

    return extent;
  }

  /// `true` when [host]'s scroll position sits at the pulled edge, so
  /// a further pull overscrolls (mirrors the Flutter
  /// `extentBefore == 0` / `extentAfter == 0` boundary checks).
  bool _isAtPullBoundary(web.HTMLElement host) {
    // Not a design token — sub-pixel scroll positions round; 1px of
    // slack keeps the boundary check robust.
    const kCssBoundarySlack = 1;
    if (_isVertical) {
      return component.reverse
          ? host.scrollTop + host.clientHeight >=
                host.scrollHeight - kCssBoundarySlack
          : host.scrollTop <= kCssBoundarySlack;
    }
    return component.reverse
        ? host.scrollLeft + host.clientWidth >=
              host.scrollWidth - kCssBoundarySlack
        : host.scrollLeft <= kCssBoundarySlack;
  }

  // `pageX` / `pageY` (declared `double`) instead of `clientX` /
  // `clientY`: pointer events carry sub-pixel coordinates, and the
  // client pair's `int` declaration throws a cast error on them. Page
  // vs client offset is irrelevant here — only deltas are consumed.
  double _pointerCoord(web.PointerEvent event) =>
      _isVertical ? event.pageY : event.pageX;

  /// Records the pointer origin while the trigger can accept a pull.
  void handlePointerDown(web.PointerEvent event, web.HTMLElement host) {
    switch (_effectiveStage) {
      case .refreshing || .completed:
        return;
      case .idle || .pulling:
        break;
    }
    _armed = true;
    _lastCoord = _pointerCoord(event);
    // Pointer capture waits until the pull actually arms (see
    // `handlePointerMove`) — capturing on every press retargets the
    // synthesized click away from buttons inside the content, killing
    // taps on interactive children.
  }

  /// Updates the active pull from pointer movement at the scroll edge.
  void handlePointerMove(web.PointerEvent event, web.HTMLElement host) {
    if (!_armed) {
      return;
    }
    final coord = _pointerCoord(event);
    final delta = coord - _lastCoord;
    _lastCoord = coord;
    // Delta along the pull direction — positive when the gesture drags
    // the content away from the pulled edge. The pull accumulates 1:1
    // up to the trigger threshold (short, predictable release point —
    // same on both platforms); the over-pull resistance past
    // `minExtent` comes from the decelerating display mapping in
    // `_calculateSafeExtent`.
    final pullDelta = component.reverse ? -delta : delta;

    if (_gestureStage == .idle) {
      if (pullDelta > 0 && _isAtPullBoundary(host)) {
        event.preventDefault();
        // Capture only once the pull arms so moves outside the element
        // keep streaming here — capturing earlier (on pointer-down)
        // would break click synthesis for buttons inside the content.
        host.setPointerCapture(event.pointerId);
        setState(() {
          _gestureStage = .pulling;
          _currentExtent = pullDelta;
          _dragging = true;
        });
      }
      return;
    }
    if (_gestureStage == .pulling) {
      event.preventDefault();
      final next = _currentExtent + pullDelta;
      if (next <= 0) {
        // Pushed back past the boundary — cancel the pull and hand the
        // gesture back to native scrolling.
        setState(() {
          _gestureStage = .idle;
          _currentExtent = 0;
          _dragging = false;
        });
        return;
      }
      setState(() {
        _currentExtent = next;
      });
    }
  }

  /// Refreshes a released pull once its trigger extent has been reached.
  void handlePointerUp(web.PointerEvent event, web.HTMLElement host) {
    if (!_armed) {
      return;
    }
    _armed = false;
    if (_gestureStage != .pulling) {
      return;
    }
    if (_currentExtent >= component.minExtent) {
      unawaited(refresh());
    } else {
      setState(() {
        _gestureStage = .idle;
        _currentExtent = 0;
        _dragging = false;
      });
    }
  }

  /// Triggers a refresh imperatively, completing the previous future
  /// first and playing the completion hold when finished (mirrors the
  /// Flutter `refresh()` sequence).
  Future<void> refresh() async {
    final count = _futureCount += 1;
    if (_currentFuture != null) {
      await _currentFuture;
      if (!mounted) return;
    }
    setState(() {
      _dragging = false;
      _gestureStage = .refreshing;
    });
    final future = component.onRefresh?.call() ?? Future<void>.value();
    _currentFuture = future;

    return await future.whenComplete(() {
      if (!mounted || count != _futureCount) {
        return;
      }
      setState(() {
        _currentFuture = null;
        _gestureStage = .completed;
      });
      _completeTimer?.cancel();
      // Completion hold — long enough for the check glyph to actually
      // be seen before returning to idle (mirrors the Flutter twin).
      _completeTimer = Timer(
        CoreRefreshTriggerStyle.defaultCompleteDuration,
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            _gestureStage = .idle;
            _currentExtent = 0;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final stage = _effectiveStage;
    // Refreshing / completed park the indicator at exactly `minExtent`
    // (mirrors the Flutter `stage == refreshing || completed ?
    // minExtent : currentExtent` animation value).
    final restingExtent = switch (stage) {
      .refreshing || .completed => component.minExtent,
      .idle || .pulling => _currentExtent,
    };
    final offset = _calculateSafeExtent(restingExtent);
    final progress = component.minExtent <= 0
        ? 1.0
        : (_currentExtent / component.minExtent).clamp(0.0, 1.0);

    // Single entry point — merge chain + token fallback + per-state
    // chrome (indicator slide offset / padding, label colour, arrow
    // rotation) all resolve in `refresh_trigger_style.dart` via the
    // runtime resolver args. The build below only reads
    // `chrome.X.className / inlineStyles`.
    final resolved = resolveRefreshTrigger(
      context,
      stage: stage,
      direction: component.direction,
      reverse: component.reverse,
      dragging: _dragging,
      offset: offset,
      // The content follows the drag only while pulling — the moment
      // the gesture releases it settles straight back to rest, while
      // the indicator keeps its own offset (parked at minExtent during
      // refreshing). A programmatic refresh never moves it.
      contentOffset: stage == .pulling ? offset : 0,
      progress: progress,
      refreshTriggerStyle: component.refreshTriggerStyle,
    );

    final l10n = CouiLocalizations.of(context);
    // Pulling swaps pull → release once the pull crosses `minExtent`
    // (mirrors the Flutter `clamped < 1 ? pullText : releaseText`).
    final labelText = switch (stage) {
      .idle => component.pullText ?? l10n.refreshTriggerPull,
      .pulling =>
        progress < 1
            ? (component.pullText ?? l10n.refreshTriggerPull)
            : (component.releaseText ?? l10n.refreshTriggerRelease),
      .refreshing => component.refreshingText ?? l10n.refreshTriggerRefreshing,
      .completed => component.completedText ?? l10n.refreshTriggerComplete,
    };

    final arrowNode = div(
      const [Icon(LucideIcons.arrowDown)],
      classes: resolved.arrow.className,
      styles: resolved.arrow.inlineStyles,
    );

    final labelRow = div(
      [
        if (stage == .pulling) arrowNode,
        span([Text(labelText)]),
        if (stage == .pulling) arrowNode,
        // Refreshing stage shows the default spinner beside the label —
        // parity with Flutter's `_buildRefreshing` (`Loading()`).
        if (stage == .refreshing) const Loading(),
        // Completed stage shows the check glyph beside the label —
        // parity with Flutter's `_buildCompleted` checkmark.
        if (stage == .completed) const Icon(LucideIcons.check),
      ],
      classes: resolved.labelRow.className,
      styles: resolved.labelRow.inlineStyles,
    );

    final indicator = div(
      [
        div(
          [labelRow],
          classes: resolved.indicator.className,
          styles: resolved.indicator.inlineStyles,
          attributes: {
            'role': 'status',
            'aria-live': 'polite',
            'data-refresh-stage': stage.name,
          },
        ),
      ],
      classes: resolved.indicatorWrapper.className,
      styles: resolved.indicatorWrapper.inlineStyles,
    );

    final content = div(
      [component.child],
      classes: resolved.content.className,
      styles: resolved.content.inlineStyles,
      events: {
        'pointerdown': EventHandlers.createPointerCurrentTargetEventHandler(
          handlePointerDown,
        ),
        'pointermove': EventHandlers.createPointerCurrentTargetEventHandler(
          handlePointerMove,
        ),
        'pointerup': EventHandlers.createPointerCurrentTargetEventHandler(
          handlePointerUp,
        ),
        'pointercancel': EventHandlers.createPointerCurrentTargetEventHandler(
          handlePointerUp,
        ),
      },
    );

    return div(
      [content, indicator],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'data-refresh-direction': component.direction.name,
      },
      events: component.events.isEmpty ? null : component.events,
    );
  }
}
