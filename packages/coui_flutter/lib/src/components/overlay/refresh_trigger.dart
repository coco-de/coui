import 'dart:async';
import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:coui_flutter/coui_flutter.dart';

typedef RefreshIndicatorBuilder =
    Widget Function(BuildContext context, RefreshTriggerStage stage);

typedef FutureVoidCallback = Future<void> Function();

/// Theme configuration for [RefreshTrigger].
///
/// Example usage:
/// ```dart
/// ComponentTheme(
///   data: RefreshTriggerTheme(
///     minExtent: 100.0,
///     maxExtent: 200.0,
///     curve: Curves.easeInOut,
///     completeDuration: Duration(milliseconds: 800),
///   ),
///   child: RefreshTrigger(
///     onRefresh: () async {
///       // Refresh logic here
///     },
///     child: ListView(
///       children: [
///         // List items
///       ],
///     ),
///   ),
/// )
/// ```
class RefreshTriggerTheme {
  /// Creates a [RefreshTriggerTheme].
  const RefreshTriggerTheme({
    this.completeDuration,
    this.curve,
    this.indicatorBuilder,
    this.maxExtent,
    this.minExtent,
  });

  /// Minimum pull extent required to trigger refresh.
  final double? minExtent;

  /// Maximum pull extent allowed.
  final double? maxExtent;

  /// Builder for the refresh indicator.
  final RefreshIndicatorBuilder? indicatorBuilder;

  /// Animation curve for the refresh trigger.
  final Curve? curve;

  /// Duration for the completion animation.
  final Duration? completeDuration;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RefreshTriggerTheme &&
        other.minExtent == minExtent &&
        other.maxExtent == maxExtent &&
        other.indicatorBuilder == indicatorBuilder &&
        other.curve == curve &&
        other.completeDuration == completeDuration;
  }

  @override
  String toString() {
    return 'RefreshTriggerTheme('
        'minExtent: $minExtent, '
        'maxExtent: $maxExtent, '
        'indicatorBuilder: $indicatorBuilder, '
        'curve: $curve, '
        'completeDuration: $completeDuration)';
  }

  @override
  int get hashCode => Object.hash(
    minExtent,
    maxExtent,
    indicatorBuilder,
    curve,
    completeDuration,
  );
}

/// A widget that provides pull-to-refresh functionality.
///
/// The [RefreshTrigger] wraps a scrollable widget and provides pull-to-refresh
/// functionality. When the user pulls the content beyond the [minExtent],
/// the [onRefresh] callback is triggered.
///
/// You can customize the appearance and behavior using [RefreshTriggerTheme]:
/// ```dart
/// ComponentTheme(
///   data: RefreshTriggerTheme(
///     minExtent: 100.0,
///     maxExtent: 200.0,
///     curve: Curves.bounceOut,
///   ),
///   child: RefreshTrigger(...),
/// )
/// ```
/// Pull-to-refresh gesture handler with customizable visual indicators.
///
/// Wraps scrollable content to provide pull-to-refresh functionality similar to
/// native mobile applications. Supports both vertical and horizontal refresh
/// gestures with fully customizable visual indicators and animation behavior.
///
/// Key Features:
/// - **Pull Gesture Detection**: Recognizes pull gestures beyond scroll boundaries
/// - **Visual Feedback**: Customizable refresh indicators with progress animation
/// - **Flexible Direction**: Supports vertical and horizontal refresh directions
/// - **Reverse Mode**: Can trigger from opposite direction (e.g., bottom-up)
/// - **Theme Integration**: Full theme support with customizable appearance
/// - **Async Support**: Handles async refresh operations with loading states
/// - **Physics Integration**: Works with any ScrollPhysics implementation
///
/// Operation Flow:
/// 1. User pulls scrollable content beyond normal bounds
/// 2. Visual indicator appears and updates based on pull distance
/// 3. When minimum threshold reached, indicator shows "ready to refresh" state
/// 4. On release, onRefresh callback is triggered
/// 5. Loading indicator shows during async refresh operation
/// 6. Completion animation plays when refresh finishes
/// 7. Content returns to normal scroll position
///
/// The component integrates seamlessly with ListView, GridView, CustomScrollView,
/// and other scrollable widgets without requiring changes to existing scroll behavior.
///
/// Example:
/// ```dart
/// RefreshTrigger(
///   minExtent: 80.0,
///   maxExtent: 150.0,
///   onRefresh: () async {
///     await Future.delayed(Duration(seconds: 2));
///     // Refresh data here
///   },
///   child: ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) => ListTile(
///       title: Text(items[index]),
///     ),
///   ),
/// )
/// ```
class RefreshTrigger extends StatefulWidget {
  /// Creates a [RefreshTrigger] with pull-to-refresh functionality.
  ///
  /// Wraps the provided child widget with refresh gesture detection and
  /// visual indicator management.
  ///
  /// Parameters:
  /// - [child] (Widget, required): Scrollable content to wrap with refresh capability
  /// - [onRefresh] (FutureVoidCallback?, optional): Async callback triggered on refresh
  /// - [direction] (Axis, default: Axis.vertical): Pull gesture direction
  /// - [reverse] (bool, default: false): Whether to trigger from opposite direction
  /// - [minExtent] (double?, optional): Minimum pull distance to trigger refresh
  /// - [maxExtent] (double?, optional): Maximum allowed pull distance
  /// - [indicatorBuilder] (RefreshIndicatorBuilder?, optional): Custom indicator widget builder
  /// - [curve] (Curve?, optional): Animation curve for refresh transitions
  /// - [completeDuration] (Duration?, optional): Duration of completion animation
  ///
  /// The [onRefresh] callback should return a Future that completes when the
  /// refresh operation is finished. During this time, a loading indicator will be shown.
  ///
  /// Example:
  /// ```dart
  /// RefreshTrigger(
  ///   onRefresh: () async {
  ///     final newData = await fetchDataFromAPI();
  ///     setState(() => items = newData);
  ///   },
  ///   minExtent: 60,
  ///   direction: Axis.vertical,
  ///   child: ListView(children: widgets),
  /// )
  /// ```
  const RefreshTrigger({
    required this.child,
    this.completeDuration,
    this.curve,
    this.direction = Axis.vertical,
    this.indicatorBuilder,
    super.key,
    this.maxExtent,
    this.minExtent,
    this.onRefresh,
    this.reverse = false,
  });

  static Widget defaultIndicatorBuilder(
    BuildContext context,
    RefreshTriggerStage stage,
  ) {
    return DefaultRefreshIndicator(stage: stage);
  }

  final double? minExtent;
  final double? maxExtent;
  final FutureVoidCallback? onRefresh;
  final Widget child;
  final Axis direction;
  final bool reverse;
  final RefreshIndicatorBuilder? indicatorBuilder;
  final Curve? curve;

  final Duration? completeDuration;

  @override
  State<RefreshTrigger> createState() => RefreshTriggerState();
}

class DefaultRefreshIndicator extends StatefulWidget {
  const DefaultRefreshIndicator({super.key, required this.stage});

  final RefreshTriggerStage stage;

  @override
  State<DefaultRefreshIndicator> createState() =>
      _DefaultRefreshIndicatorState();
}

class _DefaultRefreshIndicatorState extends State<DefaultRefreshIndicator> {
  static Widget buildRefreshingContent(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(localizations.refreshTriggerRefreshing)),
        const CircularProgressIndicator(),
      ],
    ).gap(8);
  }

  static Widget buildCompletedContent(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = CoUILocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(localizations.refreshTriggerComplete)),
        SizedBox(
          width: theme.scaling * 12.0,
          height: theme.scaling * 8.0,
          child: AnimatedValueBuilder(
            initialValue: 0.0,
            value: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: const Interval(0.5, 1),
            builder: (context, value, _) {
              return CustomPaint(
                painter: AnimatedCheckPainter(
                  color: theme.colorScheme.foreground,
                  progress: value,
                  strokeWidth: theme.scaling * 1.5,
                ),
              );
            },
          ),
        ),
      ],
    ).gap(8);
  }

  Widget buildPullingContent(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return AnimatedBuilder(
      animation: widget.stage.extent,
      builder: (context, child) {
        double angle;
        // 0 -> 1 (0 -> 180)
        angle = widget.stage.direction == Axis.vertical
            ? -pi * widget.stage.extentValue.clamp(0, 1).toDouble()
            : -pi / 2 + -pi * widget.stage.extentValue.clamp(0, 1).toDouble();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: angle,
              child: const Icon(Icons.arrow_downward),
            ),
            Flexible(
              child: Text(
                widget.stage.extentValue < 1
                    ? localizations.refreshTriggerPull
                    : localizations.refreshTriggerRelease,
              ),
            ),
            Transform.rotate(
              angle: angle,
              child: const Icon(Icons.arrow_downward),
            ),
          ],
        ).gap(8);
      },
    );
  }

  static Widget buildIdleContent(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: Text(localizations.refreshTriggerPull))],
    ).gap(8);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (widget.stage.stage) {
      case TriggerStage.refreshing:
        child = buildRefreshingContent(context);

      case TriggerStage.completed:
        child = buildCompletedContent(context);

      case TriggerStage.pulling:
        child = buildPullingContent(context);

      case TriggerStage.idle:
        child = buildIdleContent(context);
    }
    final theme = Theme.of(context);

    return Center(
      child: SurfaceCard(
        borderRadius: theme.borderRadiusXl,
        padding: widget.stage.stage == TriggerStage.pulling
            ? const EdgeInsets.all(4) * theme.scaling
            : const EdgeInsets.symmetric(vertical: 4, horizontal: 12) *
                  theme.scaling,
        child: CrossFadedTransition(
          child: KeyedSubtree(
            key: ValueKey(widget.stage.stage),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RefreshTriggerTween extends Animatable<double> {
  const _RefreshTriggerTween(this.minExtent);

  final double minExtent;

  @override
  double transform(double t) {
    return t / minExtent;
  }
}

class RefreshTriggerState extends State<RefreshTrigger>
    with SingleTickerProviderStateMixin {
  double _currentExtent = 0;
  bool _scrolling = false;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;
  TriggerStage _stage = TriggerStage.idle;
  Future<void>? _currentFuture;
  int _currentFutureCount = 0;

  // Computed theme values
  late double _minExtent;
  late double _maxExtent;
  late RefreshIndicatorBuilder _indicatorBuilder;
  late Curve _curve;
  late Duration _completeDuration;

  static double _decelerateCurve(double value) {
    return Curves.decelerate.transform(value);
  }

  void _updateThemeValues() {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<RefreshTriggerTheme>(context);

    _minExtent = styleValue(
      widgetValue: widget.minExtent,
      themeValue: compTheme?.minExtent,
      defaultValue: theme.scaling * 75.0,
    );
    _maxExtent = styleValue(
      widgetValue: widget.maxExtent,
      themeValue: compTheme?.maxExtent,
      defaultValue: theme.scaling * 150.0,
    );
    _indicatorBuilder =
        widget.indicatorBuilder ??
        compTheme?.indicatorBuilder ??
        RefreshTrigger.defaultIndicatorBuilder;
    _curve = widget.curve ?? compTheme?.curve ?? Curves.easeOutSine;
    _completeDuration =
        widget.completeDuration ??
        compTheme?.completeDuration ??
        const Duration(milliseconds: 500);
  }

  double _calculateSafeExtent(double extent) {
    if (widget.reverse) {
      extent = -extent;
    }
    if (extent > _minExtent) {
      final relativeExtent = extent - _minExtent;
      final maxExtent = _maxExtent;
      final diff = (maxExtent - _minExtent) - relativeExtent;
      final diffNormalized = diff / (maxExtent - _minExtent);

      return maxExtent -
          _decelerateCurve(diffNormalized.clamp(0, 1).toDouble()) * diff;
    }

    return extent;
  }

  Widget _wrapPositioned(Widget child) {
    return widget.direction == Axis.vertical
        ? Positioned(
            left: 0,
            top: widget.reverse ? null : 0,
            right: 0,
            bottom: widget.reverse ? 0 : null,
            child: child,
          )
        : Positioned(
            left: widget.reverse ? null : 0,
            top: 0,
            right: widget.reverse ? 0 : null,
            bottom: 0,
            child: child,
          );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    if (notification is ScrollEndNotification && _scrolling) {
      setState(() {
        final normalizedExtent = widget.reverse
            ? -_currentExtent
            : _currentExtent;
        if (normalizedExtent >= _minExtent) {
          _scrolling = false;
          refresh();
        } else {
          _stage = TriggerStage.idle;
          _currentExtent = 0;
        }
      });
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null) {
        final axisDirection = notification.metrics.axisDirection;
        final normalizedDelta =
            (axisDirection == AxisDirection.down ||
                axisDirection == AxisDirection.right)
            ? -delta
            : delta;
        if (_stage == TriggerStage.pulling) {
          final forward = normalizedDelta > 0;
          if ((forward && _userScrollDirection == ScrollDirection.forward) ||
              (!forward && _userScrollDirection == ScrollDirection.reverse)) {
            setState(() {
              _currentExtent += widget.reverse
                  ? -normalizedDelta
                  : normalizedDelta;
            });
          } else {
            if (_currentExtent >= _minExtent) {
              _scrolling = false;
              refresh();
            } else {
              setState(() {
                _currentExtent += widget.reverse
                    ? -normalizedDelta
                    : normalizedDelta;
              });
            }
          }
        } else if (_stage == TriggerStage.idle &&
            (widget.reverse
                ? notification.metrics.extentAfter == 0
                : notification.metrics.extentBefore == 0) &&
            (widget.reverse ? -normalizedDelta : normalizedDelta) > 0) {
          setState(() {
            _currentExtent = 0;
            _scrolling = true;
            _stage = TriggerStage.pulling;
          });
        }
      }
    } else if (notification is UserScrollNotification) {
      _userScrollDirection = notification.direction;
    } else if (notification is OverscrollNotification) {
      final axisDirection = notification.metrics.axisDirection;
      final overscroll =
          (axisDirection == AxisDirection.down ||
              axisDirection == AxisDirection.right)
          ? -notification.overscroll
          : notification.overscroll;
      if (overscroll > 0) {
        if (_stage == TriggerStage.idle) {
          setState(() {
            _currentExtent = 0;
            _scrolling = true;
            _stage = TriggerStage.pulling;
          });
        } else {
          setState(() {
            _currentExtent += overscroll;
          });
        }
      }
    }

    return false;
  }

  Future<void> _refresh([FutureVoidCallback? refresh]) {
    if (_stage != TriggerStage.refreshing) {
      setState(() {
        _stage = TriggerStage.refreshing;
      });
    }
    refresh ??= widget.onRefresh;

    return refresh?.call() ?? Future.value();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateThemeValues();
  }

  @override
  void didUpdateWidget(RefreshTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateThemeValues();
  }

  Offset get _offset {
    return widget.direction == Axis.vertical
        ? Offset(0, widget.reverse ? 1 : -1)
        : Offset(widget.reverse ? 1 : -1, 0);
  }

  Future<void> refresh([FutureVoidCallback? refreshCallback]) async {
    _scrolling = false;
    final count = _currentFutureCount += 1;
    if (_currentFuture != null) {
      await _currentFuture;
    }
    setState(() {
      _currentFuture = _refresh(refreshCallback);
    });

    return _currentFuture!.whenComplete(() {
      if (!mounted || count != _currentFutureCount) {
        return;
      }
      setState(() {
        _currentFuture = null;
        _stage = TriggerStage.completed;
        // Future.delayed works the same
        Timer(_completeDuration, () {
          if (!mounted) {
            return;
          }
          setState(() {
            _stage = TriggerStage.idle;
            _currentExtent = 0;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tween = _RefreshTriggerTween(_minExtent);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: AnimatedValueBuilder<double>.animation(
        value:
            _stage == TriggerStage.refreshing ||
                _stage == TriggerStage.completed
            ? _minExtent
            : _currentExtent,
        duration: _scrolling ? Duration.zero : kDefaultDuration,
        curve: _curve,
        builder: (context, animation) {
          return Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: ClipRect(
                      child: Stack(
                        children: [
                          _wrapPositioned(
                            FractionalTranslation(
                              translation: _offset,
                              child: Transform.translate(
                                offset: widget.direction == Axis.vertical
                                    ? Offset(
                                        0,
                                        _calculateSafeExtent(animation.value),
                                      )
                                    : Offset(
                                        _calculateSafeExtent(animation.value),
                                        0,
                                      ),
                                child: child,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: _indicatorBuilder(
                  context,
                  RefreshTriggerStage(
                    widget.direction,
                    tween.animate(animation),
                    _stage,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum TriggerStage {
  completed,
  idle,
  pulling,
  refreshing,
}

class RefreshTriggerStage {
  const RefreshTriggerStage(this.direction, this.extent, this.stage);

  final TriggerStage stage;
  final Animation<double> extent;
  final Axis direction;

  double get extentValue => extent.value;
}
