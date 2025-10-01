import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Size constraint for the carousel.
abstract class CarouselSizeConstraint {
  /// Creates a carousel size constraint.
  const CarouselSizeConstraint();

  /// Creates a fixed carousel size constraint.
  const factory CarouselSizeConstraint.fixed(double size) =
      CarouselFixedConstraint;

  /// Creates a fractional carousel size constraint.
  const factory CarouselSizeConstraint.fractional(double fraction) =
      CarouselFractionalConstraint;
}

/// A fixed carousel size constraint.
class CarouselFixedConstraint extends CarouselSizeConstraint {
  /// Creates a fixed carousel size constraint.
  const CarouselFixedConstraint(this.size)
    : assert(size > 0, 'size must be greater than 0');

  /// The size of the constraint.
  final double size;
}

/// A fractional carousel size constraint.
class CarouselFractionalConstraint extends CarouselSizeConstraint {
  /// Creates a fractional carousel size constraint.
  const CarouselFractionalConstraint(this.fraction)
    : assert(fraction > 0, 'fraction must be greater than 0');

  /// The fraction of the constraint.
  final double fraction;
}

/// A carousel layout.
abstract class CarouselTransition {
  /// Creates a carousel layout.
  const CarouselTransition();

  /// Creates a sliding carousel layout.
  const factory CarouselTransition.sliding({double gap}) =
      SlidingCarouselTransition;

  /// Creates a fading carousel layout.
  const factory CarouselTransition.fading() = FadingCarouselTransition;

  /// Layouts the carousel items.
  /// * [context] is the build context.
  /// * [progress] is the progress of the carousel.
  /// * [constraints] is the constraints of the carousel.
  /// * [alignment] is the alignment of the carousel.
  /// * [direction] is the direction of the carousel.
  /// * [sizeConstraint] is the size constraint of the carousel.
  /// * [progressedIndex] is the progressed index of the carousel.
  /// * [itemCount] is the item count of the carousel.
  /// * [itemBuilder] is the item builder of the carousel.
  /// * [wrap] is whether the carousel should wrap.
  /// * [reverse] is whether the carousel should reverse.
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  });
}

/// A sliding carousel transition.
class SlidingCarouselTransition extends CarouselTransition {
  /// Creates a sliding carousel transition.
  const SlidingCarouselTransition({this.gap = 0});

  /// The gap between the carousel items.
  final double gap;

  @override
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  }) {
    int additionalPreviousItems = 1;
    int additionalNextItems = 1;
    final originalSize = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    double size;
    if (sizeConstraint is CarouselFixedConstraint) {
      size = sizeConstraint.size;
    } else if (sizeConstraint is CarouselFractionalConstraint) {
      size = originalSize * sizeConstraint.fraction;
    } else {
      size = originalSize;
    }
    final snapOffsetAlignment = (originalSize - size) * alignment.alignment;
    final gapBeforeItem = snapOffsetAlignment;
    final gapAfterItem = originalSize - size - gapBeforeItem;
    additionalPreviousItems += max(0, (gapBeforeItem / size).ceil());
    additionalNextItems += max(0, (gapAfterItem / size).ceil());
    final items = <_PlacedCarouselItem>[];
    int start = progressedIndex.floor() - additionalPreviousItems;
    int end = progressedIndex.floor() + additionalNextItems;
    if (!wrap && itemCount != null) {
      start = start.clamp(0, itemCount - 1);
      end = end.clamp(0, itemCount - 1);
    }
    final currentIndex = progressedIndex + (gap / size) * progressedIndex;
    for (int i = start; i <= end; i += 1) {
      double index;
      index = itemCount == null
          ? wrapDouble(i.toDouble(), 0, itemCount.toDouble())
          : i.toDouble();
      final itemIndex = reverse ? (-index).toInt() : index.toInt();
      final item = itemBuilder(context, itemIndex);
      final position = i.toDouble();
      /// Offset the gap.
      items.add(
        _PlacedCarouselItem._(
          position: position,
          relativeIndex: i,
          child: item,
        ),
      );
    }

    return direction == Axis.horizontal
        ? [
            for (final item in items)
              Positioned(
                height: constraints.maxHeight,
                left:
                    snapOffsetAlignment +
                    (item.position - currentIndex) * size +
                    (gap * item.relativeIndex),
                width: size,
                child: item.child,
              ),
          ]
        : [
            for (final item in items)
              Positioned(
                height: size,
                top:
                    snapOffsetAlignment +
                    (item.position - currentIndex) * size +
                    (gap * item.relativeIndex),
                width: constraints.maxWidth,
                child: item.child,
              ),
          ];
  }
}

/// A fading carousel transition.
class FadingCarouselTransition extends CarouselTransition {
  /// Creates a fading carousel transition.
  const FadingCarouselTransition();

  @override
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  }) {
    final originalSize = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    double size;
    if (sizeConstraint is CarouselFixedConstraint) {
      size = sizeConstraint.size;
    } else if (sizeConstraint is CarouselFractionalConstraint) {
      size = originalSize * sizeConstraint.fraction;
    } else {
      size = originalSize;
    }
    final snapOffsetAlignment = (originalSize - size) * alignment.alignment;
    final items = <_PlacedCarouselItem>[];
    int start = progressedIndex.floor() - 1;
    int end = progressedIndex.floor() + 1;
    if (!wrap && itemCount != null) {
      start = start.clamp(0, itemCount - 1);
      end = end.clamp(0, itemCount - 1);
    }
    for (int i = start; i <= end; i += 1) {
      double index;
      index = itemCount == null
          ? wrapDouble(i.toDouble(), 0, itemCount.toDouble())
          : i.toDouble();
      final itemIndex = reverse ? (-index).toInt() : index.toInt();
      final item = itemBuilder(context, itemIndex);
      final position = i.toDouble();
      /// Offset the gap.
      items.add(
        _PlacedCarouselItem._(
          position: position,
          relativeIndex: i,
          child: item,
        ),
      );
    }

    return direction == Axis.horizontal
        ? [
            for (final item in items)
              Positioned(
                height: constraints.maxHeight,
                left: snapOffsetAlignment,
                width: size,
                child: Opacity(
                  opacity: (1 - (progress - item.position).abs()).clamp(
                    0.0,
                    1.0,
                  ),
                  child: item.child,
                ),
              ),
          ]
        : [
            for (final item in items)
              Positioned(
                height: size,
                top: snapOffsetAlignment,
                width: constraints.maxWidth,
                child: Opacity(
                  opacity: (1 - (progress - item.position).abs()).clamp(
                    0.0,
                    1.0,
                  ),
                  child: item.child,
                ),
              ),
          ];
  }
}

/// Builds a carousel item.
/// The [index] is the index of the item.
typedef CarouselItemBuilder = Widget Function(BuildContext context, int index);

/// A controller for the carousel.
class CarouselController extends Listenable {
  final _controller = AnimationQueueController();

  /// Whether the carousel should animate.
  bool get shouldAnimate => _controller.shouldTick;

  /// The current value of the controller.
  double get value => _controller.value;

  /// Animates to the next item.
  void animateNext(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(
        (_controller.value + 1).roundToDouble(),
        duration,
        curve,
      ),
      false,
    );
  }

  /// Animates to the previous item.
  void animatePrevious(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(
        (_controller.value - 1).roundToDouble(),
        duration,
        curve,
      ),
      false,
    );
  }

  /// Animates the current value to the nearest integer.
  void animateSnap(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(_controller.value.roundToDouble(), duration, curve),
    );
  }

  /// Jumps to the specified value.
  void jumpTo(double value) {
    _controller.value = value;
  }

  /// Animates to the specified value.
  void animateTo(
    Duration duration,
    double value, [
    Curve curve = Curves.linear,
  ]) {
    _controller.push(AnimationRequest(value, duration, curve), false);
  }

  /// Animates to the specified value.
  double getCurrentIndex(int? itemCount) {
    return itemCount == null
        ? _controller.value
        : wrapDouble(_controller.value, 0, itemCount.toDouble());
  }

  /// Animates to the specified value.
  void tick(Duration delta) {
    _controller.tick(delta);
  }

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
}

/// CarouselAlignment is used to align the carousel items.
enum CarouselAlignment {
  /// Aligns the carousel items to the center.
  center(0.5),

  /// Aligns the carousel items to the end.
  end(1),

  /// Aligns the carousel items to the start.
  start(0);

  /// The alignment value.
  final double alignment;

  const CarouselAlignment(this.alignment);
}

/// Theme data for [Carousel].
class CarouselTheme {
  const CarouselTheme({
    this.alignment,
    this.autoplaySpeed,
    this.curve,
    this.direction,
    this.draggable,
    this.pauseOnHover,
    this.speed,
    this.wrap,
  });

  final CarouselAlignment? alignment;
  final Axis? direction;
  final bool? wrap;
  final bool? pauseOnHover;
  final Duration? autoplaySpeed;
  final bool? draggable;
  final Duration? speed;

  final Curve? curve;

  @override
  bool operator ==(Object other) {
    return other is CarouselTheme &&
        other.alignment == alignment &&
        other.direction == direction &&
        other.wrap == wrap &&
        other.pauseOnHover == pauseOnHover &&
        other.autoplaySpeed == autoplaySpeed &&
        other.draggable == draggable &&
        other.speed == speed &&
        other.curve == curve;
  }

  @override
  int get hashCode => Object.hash(
    alignment,
    direction,
    wrap,
    pauseOnHover,
    autoplaySpeed,
    draggable,
    speed,
    curve,
  );
}

/// Interactive carousel widget with automatic transitions and customizable layouts.
///
/// A high-level carousel widget that displays a sequence of items with smooth
/// transitions between them. Supports automatic progression, manual navigation,
/// multiple transition types, and extensive customization options.
///
/// ## Features
///
/// - **Multiple transition types**: Sliding and fading transitions with customizable timing
/// - **Automatic progression**: Optional auto-play with configurable duration per item
/// - **Manual navigation**: Programmatic control through [CarouselController]
/// - **Flexible sizing**: Fixed or fractional size constraints for responsive layouts
/// - **Interactive controls**: Pause on hover, wrap-around navigation, and touch gestures
/// - **Flexible alignment**: Multiple alignment options for different layout needs
/// - **Directional support**: Horizontal or vertical carousel orientation
///
/// ## Usage Patterns
///
/// **Basic automatic carousel:**
/// ```dart
/// Carousel(
///   itemCount: images.length,
///   duration: Duration(seconds: 3),
///   itemBuilder: (context, index) => Image.asset(images[index]),
///   transition: CarouselTransition.sliding(gap: 16),
/// )
/// ```
///
/// **Controlled carousel with custom navigation:**
/// ```dart
/// final controller = CarouselController();
///
/// Carousel(
///   controller: controller,
///   itemCount: products.length,
///   itemBuilder: (context, index) => ProductCard(products[index]),
///   transition: CarouselTransition.fading(),
///   pauseOnHover: true,
/// )
/// ```
class Carousel extends StatefulWidget {
  /// Creates a carousel.
  const Carousel({
    this.alignment = CarouselAlignment.center,
    this.autoplayReverse = false,
    this.autoplaySpeed,
    this.controller,
    this.curve = Curves.easeInOut,
    this.direction = Axis.horizontal,
    this.disableDraggingVelocity = false,
    this.disableOverheadScrolling = true,
    this.draggable = true,
    this.duration,
    this.durationBuilder,
    required this.itemBuilder,
    this.itemCount,
    super.key,
    this.onIndexChanged,
    this.pauseOnHover = true,
    this.reverse = false,
    this.sizeConstraint = const CarouselFractionalConstraint(1),
    this.speed = const Duration(milliseconds: 200),
    required this.transition,
    this.waitOnStart = false,
    this.wrap = true,
  }) : assert(
         wrap || itemCount != null,
         'itemCount must be provided if wrap is false',
       );

  /// The carousel transition.
  final CarouselTransition transition;

  /// The item builder.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// The duration of the carousel.
  final Duration? duration;

  /// The duration builder of the carousel.
  final Duration? Function(int index)? durationBuilder;

  /// The item count of the carousel.
  final int? itemCount;

  /// The carousel controller.
  final CarouselController? controller;

  /// The carousel alignment.
  final CarouselAlignment alignment;

  /// The carousel direction.
  final Axis direction;

  /// Whether the carousel should wrap.
  final bool wrap;

  /// Whether the carousel should pause on hover.
  final bool pauseOnHover;

  /// Whether the carousel should wait the item duration on start.
  final bool waitOnStart;

  /// The autoplay speed of the carousel.
  final Duration? autoplaySpeed;

  /// Whether the carousel should autoplay in reverse.
  final bool autoplayReverse;

  /// Whether the carousel is draggable.
  final bool draggable;

  /// Whether the carousel is reverse in layout direction.
  final bool reverse;

  /// The size constraint of the carousel.
  final CarouselSizeConstraint sizeConstraint;

  /// The speed of the carousel.
  final Duration speed;

  /// The curve of the carousel.
  final Curve curve;

  /// The index change callback.
  final ValueChanged<int>? onIndexChanged;

  /// Whether to disable overhead scrolling.
  final bool disableOverheadScrolling;

  /// Whether to disable dragging velocity.
  final bool disableDraggingVelocity;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel>
    with SingleTickerProviderStateMixin {
  CarouselController _controller;
  Duration? _startTime;
  Ticker _ticker;
  bool hovered = false;
  bool dragging = false;

  double _lastDragValue;
  double _dragVelocity = 0;

  int _currentIndex;

  CarouselTheme? _theme;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _controller = widget.controller ?? CarouselController();
    _controller.addListener(_onControllerChange);
    _currentIndex = _controller.getCurrentIndex(widget.itemCount).round();
    _dispatchControllerChange();
  }

  void _check() {
    bool shouldStart = false;
    if (_controller.shouldAnimate) {
      shouldStart = true;
    }
    if ((!shouldStart) && (_currentSlideDuration != null)) {
      if (!_pauseOnHover || !hovered) {
        shouldStart = true;
      }
    }
    if (!shouldStart && _dragVelocity.abs() > 0.0001) {
      shouldStart = true;
    }
    if (shouldStart) {
      if (!_ticker.isActive) {
        _lastTime = null;
        _startTime = null;
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
        _startTime = null;
        _lastTime = null;
      }
    }
  }

  void _tick(Duration elapsed) {
    final delta = _lastTime == null ? Duration.zero : elapsed - _lastTime!;
    _lastTime = elapsed;
    final deltaMillis = delta.inMilliseconds;
    /// Animate the index progress.
    _controller.tick(delta);
    bool shouldAutoPlay = false;
    if (_currentSlideDuration != null) {
      if (_startTime == null) {
        _startTime = elapsed;
        shouldAutoPlay = !widget.waitOnStart;
      } else {
        final elapsedDuration = elapsed - _startTime!;
        if (elapsedDuration >= _currentSlideDuration!) {
          shouldAutoPlay = true;
          _startTime = null;
        }
      }
    }
    if (shouldAutoPlay) {
      if (!_wrap &&
          widget.itemCount != null &&
          _controller.value >= widget.itemCount! - 1) {
        _controller.animateTo(0, _autoplaySpeed ?? _speed, _curve);
      } else if (!_wrap && widget.itemCount != null && _controller.value <= 0) {
        _controller.animateTo(
          widget.itemCount! - 1,
          _autoplaySpeed ?? _speed,
          _curve,
        );
      } else if (widget.autoplayReverse) {
        _controller.animatePrevious(_autoplaySpeed ?? _speed, _curve);
      } else {
        _controller.animateNext(_autoplaySpeed ?? _speed, _curve);
      }
    }
    if (_dragVelocity.abs() > 0.01 && !dragging) {
      final targetValue = progressedValue + _dragVelocity;
      _controller.jumpTo(targetValue);
      // decrease the drag velocity (consider the delta time)
      _dragVelocity *= pow(0.2, deltaMillis / 100);
      if (_dragVelocity.abs() < 0.01) {
        _dragVelocity = 0;
        if (widget.disableOverheadScrolling) {
          if (_lastDragValue < targetValue) {
            _controller.animateTo(
              _lastDragValue.floorToDouble() + 1,
              _speed,
              _curve,
            );
          } else {
            _controller.animateTo(
              _lastDragValue.floorToDouble() - 1,
              _speed,
              _curve,
            );
          }
        } else {
          _controller.animateSnap(_speed, _curve);
        }
      }
    }

    _check();
  }

  void _onControllerChange() {
    setState(() {});
    if (!_wrap && widget.itemCount != null) {
      if (_controller.value < 0) {
        _controller._controller.value = 0;
      } else if (_controller.value >= widget.itemCount!) {
        _controller._controller.value = widget.itemCount!.toDouble() - 1;
      }
    }
    _dispatchControllerChange();
  }

  void _dispatchControllerChange() {
    _check();
    final index = _controller.getCurrentIndex(widget.itemCount).round();
    if (index != _currentIndex) {
      _currentIndex = index;
      widget.onIndexChanged?.call(index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = ComponentTheme.maybeOf<CarouselTheme>(context);
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      _controller = widget.controller ?? CarouselController();
      _controller.addListener(_onControllerChange);
      _dispatchControllerChange();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    // DO NOT DISPOSE CONTROLLER
    // CONTROLLER might not belong to this state
    // Removing our  listener from the controller is enough
    // _controller.dispose();
    _ticker.dispose();
    super.dispose();
  }

  CarouselAlignment get _alignment => styleValue(
    defaultValue: CarouselAlignment.center,
    themeValue: _theme?.alignment,
    widgetValue: widget.alignment,
  );

  Axis get _direction => styleValue(
    defaultValue: Axis.horizontal,
    themeValue: _theme?.direction,
    widgetValue: widget.direction,
  );

  bool get _wrap => styleValue(
    defaultValue: true,
    themeValue: _theme?.wrap,
    widgetValue: widget.wrap,
  );

  bool get _pauseOnHover => styleValue(
    defaultValue: true,
    themeValue: _theme?.pauseOnHover,
    widgetValue: widget.pauseOnHover,
  );

  Duration? get _autoplaySpeed => styleValue(
    defaultValue: null,
    themeValue: _theme?.autoplaySpeed,
    widgetValue: widget.autoplaySpeed,
  );
  bool get _draggable => styleValue(
    defaultValue: true,
    themeValue: _theme?.draggable,
    widgetValue: widget.draggable,
  );

  Duration get _speed => styleValue(
    defaultValue: const Duration(milliseconds: 200),
    themeValue: _theme?.speed,
    widgetValue: widget.speed,
  );

  Curve get _curve => styleValue(
    defaultValue: Curves.easeInOut,
    themeValue: _theme?.curve,
    widgetValue: widget.curve,
  );

  Duration? get _currentSlideDuration {
    final currentIndex = _controller.getCurrentIndex(widget.itemCount);
    final index = currentIndex.floor();
    Duration? duration = widget.durationBuilder?.call(index) ?? widget.duration;
    if (duration != null && _autoplaySpeed != null) {
      duration += _autoplaySpeed!;
    }

    return duration;
  }

  Duration? _lastTime;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        hovered = true;
        _check();
      },
      onExit: (event) {
        hovered = false;
        _check();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget carouselWidget = buildCarousel(context, constraints);
          if (_draggable) {
            carouselWidget = _direction == Axis.horizontal
                ? buildHorizontalDragger(
                    context,
                    carouselWidget,
                    constraints,
                  )
                : buildVerticalDragger(
                    context,
                    carouselWidget,
                    constraints,
                  );
          }

          return carouselWidget;
        },
      ),
    );
  }

  Widget buildHorizontalDragger(
    Widget carouselWidget,
    BoxConstraints constraints,
    BuildContext context,
  ) {
    double size;
    if (widget.sizeConstraint is CarouselFixedConstraint) {
      size = (widget.sizeConstraint as CarouselFixedConstraint).size;
    } else if (widget.sizeConstraint is CarouselFractionalConstraint) {
      size =
          constraints.maxHeight *
          (widget.sizeConstraint as CarouselFractionalConstraint).fraction;
    } else {
      size = constraints.maxHeight;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        dragging = false;
        _dragVelocity = widget.disableDraggingVelocity
            ? 0
            : -details.primaryVelocity! / size / 100.0;
        _controller.animateSnap(_speed, _curve);
        _check();
      },
      onHorizontalDragStart: (details) {
        dragging = true;
        _lastDragValue = progressedValue;
        _dragVelocity = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (_draggable) {
          setState(() {
            final increment = -details.primaryDelta! / size;
            _controller.jumpTo(progressedValue + increment);
          });
        }
      },
      child: carouselWidget,
    );
  }

  Widget buildVerticalDragger(
    Widget carouselWidget,
    BoxConstraints constraints,
    BuildContext context,
  ) {
    double size;
    if (widget.sizeConstraint is CarouselFixedConstraint) {
      size = (widget.sizeConstraint as CarouselFixedConstraint).size;
    } else if (widget.sizeConstraint is CarouselFractionalConstraint) {
      size =
          constraints.maxWidth *
          (widget.sizeConstraint as CarouselFractionalConstraint).fraction;
    } else {
      size = constraints.maxWidth;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        dragging = false;
        _dragVelocity = widget.disableDraggingVelocity
            ? 0
            : -details.primaryVelocity! / size / 100.0;
        _controller.animateSnap(_speed, _curve);
        _check();
      },
      onVerticalDragStart: (details) {
        dragging = true;
        _lastDragValue = progressedValue;
        _dragVelocity = 0;
      },
      onVerticalDragUpdate: (details) {
        if (_draggable) {
          setState(() {
            final increment = -details.primaryDelta! / size;
            _controller.jumpTo(progressedValue + increment);
          });
        }
      },
      child: carouselWidget,
    );
  }

  double get progressedValue {
    return !_wrap && widget.itemCount != null
        ? _controller.value.clamp(0.0, widget.itemCount!.toDouble() - 1)
        : _controller.value;
  }

  Widget buildCarousel(BoxConstraints constraints, BuildContext context) {
    return Stack(
      children: widget.transition.layout(
        context,
        alignment: _alignment,
        constraints: constraints,
        direction: _direction,
        itemBuilder: widget.itemBuilder,
        itemCount: widget.itemCount,
        progress: progressedValue,
        progressedIndex: progressedValue,
        reverse: widget.reverse,
        sizeConstraint: widget.sizeConstraint,
        wrap: _wrap,
      ),
    );
  }
}

class _PlacedCarouselItem {
  const _PlacedCarouselItem._({
    required this.child,
    required this.position,
    required this.relativeIndex,
  });
  final int relativeIndex;
  final Widget child;

  final double position;
}

/// A dot indicator for the carousel.
class CarouselDotIndicator extends StatelessWidget {
  /// Creates a dot indicator for the carousel.
  const CarouselDotIndicator({
    required this.controller,
    this.curve = Curves.easeInOut,
    required this.itemCount,
    super.key,
    this.speed = const Duration(milliseconds: 200),
  });

  /// The item count of the carousel.
  final int itemCount;

  /// The carousel controller.
  final CarouselController controller;

  /// The speed of the value change.
  final Duration speed;

  /// The curve of the value change.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      builder: (context, child) {
        int value = controller.value.round() % itemCount;
        if (value < 0) {
          value += itemCount;
        }

        return DotIndicator(
          index: value,
          length: itemCount,
          onChanged: (value) {
            controller.animateTo(value.toDouble(), speed, curve);
          },
        );
      },
      listenable: controller,
    );
  }
}
