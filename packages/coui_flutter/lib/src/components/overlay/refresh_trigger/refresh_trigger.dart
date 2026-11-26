import 'dart:async';
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart';

/// Curve decay normaliser upper bound.
const _kExtentClampMax = 1.0;

/// A pull-to-refresh trigger with a unified stage-driven indicator.
///
/// `RefreshTrigger` wraps scrollable [child] content and shows a
/// surface-card indicator whose label / tone reacts to the current
/// [CoreRefreshStage]. On Flutter the stage is also driven internally
/// by the pull gesture (overscroll + scroll-boundary detection);
/// supplying a non-idle [stage] forces a controlled stage instead so
/// the host can drive the indicator from external state.
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
///   child: ListView(children: items),
/// )
/// ```
///
/// surface:functional — the indicator rides an absolutely-positioned rail
/// over the list it refreshes.
class RefreshTrigger extends StatefulWidget
    implements CoreRefreshTriggerContract<Widget> {
  /// Creates a [RefreshTrigger].
  const RefreshTrigger({
    required this.child,
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
    super.key,
  });

  @override
  final Widget child;

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
    Widget? child,
  }) {
    return RefreshTrigger(
      key: key ?? this.key,
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

/// Chain sugar for merging a [CoreRefreshTriggerStyle] patch into
/// [RefreshTrigger.refreshTriggerStyle] without hand-reconstructing every
/// field. Mirrors the Web `RefreshTrigger.withStyle` extension so both
/// platforms read identically.
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

/// Applies the standard decelerate easing to [value] — shapes the
/// over-pull resistance past [RefreshTrigger.minExtent].
double _decelerateCurve(double value) {
  return CoreEasingFunction.decelerate.toValue().transform(value);
}

/// Public state for [RefreshTrigger] — exposed so hosts can drive a
/// programmatic refresh via `GlobalKey<RefreshTriggerState>` and
/// [refresh] (in addition to the pull gesture).
class RefreshTriggerState extends State<RefreshTrigger>
    with SingleTickerProviderStateMixin {
  double _currentExtent = 0;
  bool _scrolling = false;

  /// Live pull fraction (extent / minExtent) the indicator's arrow
  /// rotation and pull↔release label subscribe to. A plain rebuild
  /// cannot reach them: the stage cross-fade snapshots its child per
  /// stage key, so only a stable listenable crossing that snapshot
  /// keeps them live.
  final ValueNotifier<double> _pulledFraction = ValueNotifier(0);
  ScrollDirection _userScrollDirection = .idle;
  CoreRefreshStage _gestureStage = .idle;
  Future<void>? _currentFuture;
  int _currentFutureCount = 0;

  /// Timer that returns the indicator to idle after the completion
  /// hold. Held so it can be cancelled on dispose.
  Timer? _completeTimer;

  /// Effective stage — the explicitly supplied [RefreshTrigger.stage]
  /// wins whenever it is non-idle; otherwise the gesture-driven
  /// stage is used.
  CoreRefreshStage get _effectiveStage =>
      widget.stage != .idle ? widget.stage : _gestureStage;

  bool get _isVertical => widget.direction == .vertical;

  Offset get _offset {
    return _isVertical
        ? Offset(0, widget.reverse ? 1 : -1)
        : Offset(widget.reverse ? 1 : -1, 0);
  }

  /// Triggers a refresh imperatively, completing the previous future
  /// first and playing the completion animation when finished.
  Future<void> refresh() async {
    _scrolling = false;
    final count = _currentFutureCount += 1;
    if (_currentFuture != null) {
      await _currentFuture;
      if (!mounted) {
        return;
      }
    }
    final future = _refresh();
    setState(() {
      _currentFuture = future;
    });

    return await _currentFuture!.whenComplete(() {
      if (!mounted || count != _currentFutureCount) {
        return;
      }
      setState(() {
        _currentFuture = null;
        _gestureStage = .completed;
      });
      _completeTimer?.cancel();
      // Completion hold — long enough for the cross-fade plus the
      // checkmark reveal to actually be seen before returning to idle.
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

  double _calculateSafeExtent(double extent) {
    final value = widget.reverse ? -extent : extent;
    if (value > widget.minExtent) {
      final relativeExtent = value - widget.minExtent;
      final maxExtent = widget.maxExtent;
      final diff = (maxExtent - widget.minExtent) - relativeExtent;
      final diffNormalized = diff / (maxExtent - widget.minExtent);

      return maxExtent -
          _decelerateCurve(
                diffNormalized.clamp(0, _kExtentClampMax).toDouble(),
              ) *
              diff;
    }

    return value;
  }

  Widget _wrapPositioned(Widget child) {
    return _isVertical
        ? Position(
            top: widget.reverse ? null : 0,
            right: 0,
            bottom: widget.reverse ? 0 : null,
            left: 0,
            child: child,
          )
        : Position(
            top: 0,
            right: widget.reverse ? 0 : null,
            bottom: 0,
            left: widget.reverse ? null : 0,
            child: child,
          );
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return;
    }
    if (notification is ScrollEndNotification && _scrolling) {
      setState(() {
        final normalizedExtent = widget.reverse
            ? -_currentExtent
            : _currentExtent;
        if (normalizedExtent >= widget.minExtent) {
          _scrolling = false;
          unawaited(refresh());
        } else {
          _gestureStage = .idle;
          _currentExtent = 0;
        }
      });
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null) {
        final axisDirection = notification.metrics.axisDirection;
        final normalizedDelta =
            (axisDirection == .down || axisDirection == .right)
            ? -delta
            : delta;
        if (_gestureStage == .pulling) {
          final forward = normalizedDelta > 0;
          if (forward
              ? _userScrollDirection == .forward
              : _userScrollDirection == .reverse) {
            setState(() {
              _currentExtent += widget.reverse
                  ? -normalizedDelta
                  : normalizedDelta;
            });
          } else {
            if (_currentExtent >= widget.minExtent) {
              _scrolling = false;
              unawaited(refresh());
            } else {
              setState(() {
                _currentExtent += widget.reverse
                    ? -normalizedDelta
                    : normalizedDelta;
              });
            }
          }
        } else if (_gestureStage == .idle &&
            (widget.reverse
                ? notification.metrics.extentAfter == 0
                : notification.metrics.extentBefore == 0) &&
            (widget.reverse ? -normalizedDelta : normalizedDelta) > 0) {
          setState(() {
            _currentExtent = 0;
            _scrolling = true;
            _gestureStage = .pulling;
          });
        }
      }
    } else if (notification is UserScrollNotification) {
      _userScrollDirection = notification.direction;
    } else if (notification is OverscrollNotification) {
      final axisDirection = notification.metrics.axisDirection;
      final overscroll = (axisDirection == .down || axisDirection == .right)
          ? -notification.overscroll
          : notification.overscroll;
      if (overscroll > 0) {
        if (_gestureStage == .idle) {
          setState(() {
            _currentExtent = 0;
            _scrolling = true;
            _gestureStage = .pulling;
          });
        } else {
          setState(() {
            _currentExtent += overscroll;
          });
        }
      }
    }
  }

  Future<void> _refresh() {
    if (_gestureStage != .refreshing) {
      setState(() {
        _gestureStage = .refreshing;
      });
    }

    return widget.onRefresh?.call() ?? Future.value();
  }

  void _syncPulledFraction() {
    final normalized = widget.reverse ? -_currentExtent : _currentExtent;
    _pulledFraction.value = widget.minExtent <= 0
        ? 1
        : normalized / widget.minExtent;
  }

  /// Builds one pull frame — the content translated by its own settle
  /// animation and the indicator overlay translated by the indicator
  /// animation (parked at `minExtent` during refreshing).
  Widget _buildPullFrame({
    required Animation<double> indicatorAnimation,
    required Animation<double> contentAnimation,
    required ResolvedRefreshTrigger resolved,
    required CoreRefreshStage stage,
    required String pullText,
    required String releaseText,
    required String refreshingText,
    required String completedText,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([indicatorAnimation, contentAnimation]),
      builder: (context, child) {
        final indicatorExtent = _calculateSafeExtent(
          indicatorAnimation.value,
        );
        final contentExtent = _calculateSafeExtent(contentAnimation.value);
        final sign = widget.reverse ? -1.0 : 1.0;
        final contentOffset = _isVertical
            ? Offset(0, sign * contentExtent)
            : Offset(sign * contentExtent, 0);
        return Stacks(
          fit: .passthrough,
          children: [
            Transform.translate(
              offset: contentOffset,
              child: widget.child,
            ),
            Position.fill(
              child: ClipRect(
                child: Stacks(
                  children: [
                    _wrapPositioned(
                      FractionalTranslation(
                        translation: _offset,
                        child: Transform.translate(
                          offset: _isVertical
                              ? Offset(0, indicatorExtent)
                              : Offset(indicatorExtent, 0),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: _RefreshIndicator(
        resolved: resolved,
        stage: stage,
        direction: widget.direction,
        extent: _pulledFraction,
        pullText: pullText,
        releaseText: releaseText,
        refreshingText: refreshingText,
        completedText: completedText,
      ),
    );
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _pulledFraction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveRefreshTrigger(
      context,
      refreshTriggerStyle: widget.refreshTriggerStyle,
    );
    final localizations = CoUILocalizations.of(context);
    final pullText = widget.pullText ?? localizations.refreshTriggerPull;
    final releaseText =
        widget.releaseText ?? localizations.refreshTriggerRelease;
    final refreshingText =
        widget.refreshingText ?? localizations.refreshTriggerRefreshing;
    final completedText =
        widget.completedText ?? localizations.refreshTriggerComplete;
    final stage = _effectiveStage;
    // Mouse joins the drag devices for this subtree only — the default
    // ScrollBehavior is touch-only on desktop, which would leave the
    // pull gesture dead under a mouse while the Web twin's pointer
    // engine handles mouse and touch alike. Clamping physics replaces
    // the app-wide bouncing for the wrapped scrollable: the list must
    // not bounce on its own (RefreshTrigger translates the content
    // itself, together with the indicator — the Web model), and the
    // clamped overscroll streams raw 1:1 deltas so the trigger
    // threshold sits at exactly `minExtent` of finger travel on both
    // platforms. Scoping it here keeps app-wide list behaviour intact.
    final scrollBehavior = ScrollConfiguration.of(context);

    // Web twin: role="status" + aria-live — pull-to-refresh state has to be
    // announced, not only drawn.
    return Semantics(
      liveRegion: true,
      child: ScrollConfiguration(
        behavior: scrollBehavior.copyWith(
          dragDevices: {
            ...scrollBehavior.dragDevices,
            .mouse,
          },
          physics: const ClampingScrollPhysics(),
        ),
        child: NotificationListener<ScrollNotification>(
          // Returns `false` so the notification keeps bubbling — the
          // pull-state mutation happens in `_handleScrollNotification`.
          onNotification: (notification) {
            _handleScrollNotification(notification);
            _syncPulledFraction();
            return false;
          },
          child: AnimatedValueBuilder<double>.animation(
            value: stage == .refreshing || stage == .completed
                ? widget.minExtent
                : _currentExtent,
            duration: _scrolling ? .zero : resolved.animationDuration,
            curve: CoreEasing.easeOutSine.toValue(),
            builder: (context, animation) {
              return AnimatedValueBuilder<double>.animation(
                // Content follows the drag only while pulling — the
                // moment the gesture releases (refresh or bail) it
                // settles straight back to rest, while the indicator
                // keeps its own animation (parked at minExtent during
                // refreshing). Mirrors the Web twin's content offset.
                value: stage == .pulling ? _currentExtent : 0.0,
                duration: _scrolling ? .zero : resolved.animationDuration,
                curve: CoreEasing.easeOutSine.toValue(),
                // Builder callback, not an event handler
                // (CrossFadedTransition precedent).
                builder: (context, contentAnimation) => _buildPullFrame(
                  indicatorAnimation: animation,
                  contentAnimation: contentAnimation,
                  resolved: resolved,
                  stage: stage,
                  pullText: pullText,
                  releaseText: releaseText,
                  refreshingText: refreshingText,
                  completedText: completedText,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The unified refresh indicator surface — a surface card whose label
/// and tone react to the current [CoreRefreshStage].
class _RefreshIndicator extends StatelessWidget {
  const _RefreshIndicator({
    required this.resolved,
    required this.stage,
    required this.direction,
    required this.extent,
    required this.pullText,
    required this.releaseText,
    required this.refreshingText,
    required this.completedText,
  });

  final ResolvedRefreshTrigger resolved;
  final CoreRefreshStage stage;
  final CoreRefreshDirection direction;

  /// Live pull fraction (extent / minExtent) — a stable listenable so
  /// the arrow rotation and pull↔release label stay live inside the
  /// stage cross-fade's per-stage child snapshot.
  final ValueListenable<double> extent;
  final String pullText;
  final String releaseText;
  final String refreshingText;
  final String completedText;

  Widget _buildRefreshing(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Text(
            refreshingText,
            style: resolved.refreshingTextStyle,
          ),
        ),
        Gap(gapStyle: resolved.indicatorGapStyle),
        const Loading(),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Text(
            completedText,
            style: resolved.completedTextStyle,
          ),
        ),
        Gap(gapStyle: resolved.indicatorGapStyle),
        // The unified Icon (the Web twin renders the same lucide check)
        // rather than a hand-painted checkmark.
        Icon(LucideIcons.check, iconStyle: resolved.completedIconStyle),
      ],
    );
  }

  Widget _buildIdle(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Text(
            pullText,
            style: resolved.idleTextStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildPulling(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: extent,
      builder: (context, fraction, child) {
        final clamped = fraction.clamp(0, 1).toDouble();
        // 0 → 1 maps to a 0 → 180° (vertical) arrow flip.
        final angle = direction == .vertical
            ? -pi * clamped
            : -pi / 2 + -pi * clamped;
        final label = clamped < 1 ? pullText : releaseText;

        return Row(
          mainAxisSize: .min,
          children: [
            Transform.rotate(
              angle: angle,
              child: Icon(
                LucideIcons.arrowDown,
                iconStyle: resolved.arrowIconStyle,
              ),
            ),
            Gap(gapStyle: resolved.indicatorGapStyle),
            Flexible(
              child: Text(
                label,
                style: resolved.idleTextStyle,
              ),
            ),
            Gap(gapStyle: resolved.indicatorGapStyle),
            Transform.rotate(
              angle: angle,
              child: Icon(
                LucideIcons.arrowDown,
                iconStyle: resolved.arrowIconStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (stage) {
      .refreshing => _buildRefreshing(context),
      .completed => _buildCompleted(context),
      .pulling => _buildPulling(context),
      .idle => _buildIdle(context),
    };

    // Scaling is pre-applied in the resolver — padding / radius are
    // read straight (Epic #1603 C12 — scaling resolved in one place).
    final padding = stage == .pulling
        ? resolved.pullingPadding
        : resolved.indicatorPadding;

    return Center(
      child: OutlinedContainer(
        containerStyle: resolved.containerStyle,
        role: .functional,
        child: Padding(
          padding: padding,
          child: CrossFadedTransition(
            child: KeyedSubtree(
              key: ValueKey(stage),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
