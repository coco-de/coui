import 'dart:async';
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/scheduler.dart';

/// Unified cross-platform carousel with token-based rendering.
///
/// Supports both convenience API ([items]) and power-user API
/// ([itemBuilder] + [itemCount]). Provides auto-play, dragging,
/// slide indicators, and navigation buttons.
///
/// Example:
/// ```dart
/// Carousel(
///   items: [slide1, slide2, slide3],
///   transition: CarouselTransition.sliding(gap: 16),
///   autoPlay: true,
///   showIndicators: true,
/// )
/// ```
class Carousel extends StatefulWidget implements CoreCarouselContract<Widget> {
  /// Creates a [Carousel].
  const Carousel({
    // === Content ===
    this.items,
    this.itemBuilder,
    this.itemCount,
    // === Transition ===
    required this.transition,
    // === Auto-play ===
    this.duration,
    this.autoPlay,
    this.showIndicators = true,
    this.showNavigation,
    // === Navigation ===
    this.currentIndex = 0,
    this.onIndexChanged,
    // === Behavior ===
    this.wrap = true,
    this.pauseOnHover = true,
    // === Layout / motion / advanced behaviour ===
    this.alignment = CarouselAlignment.center,
    this.autoplayReverse = false,
    this.autoplaySpeed,
    this.controller,
    this.curve = CoreEasing.move,
    this.direction = CoreAxis.horizontal,
    this.disableDraggingVelocity = false,
    this.disableOverheadScrolling = true,
    this.draggable = true,
    this.durationBuilder,
    super.key,
    this.variant = CoreCarouselVariant.defaultVariant,
    this.size = CoreCarouselSize.defaultSize,
    this.reverse = false,
    this.sizeConstraint = const CarouselFractionalConstraint(1),
    this.speed = CoreCarouselStyle.defaultTransitionSpeed,
    this.waitOnStart = false,
    this.carouselStyle,
  }) : assert(
         itemBuilder != null || items != null,
         'Provide either itemBuilder or items.',
       ),
       assert(
         wrap || itemCount != null || items != null,
         'itemCount or items must be provided if wrap is false.',
       );

  // === Content (contract) ===

  @override
  final List<Widget>? items;

  /// Builds slides on demand, as an alternative to [items].
  @override
  final CarouselItemBuilder? itemBuilder;

  @override
  final int? itemCount;

  // === Transition (contract) ===

  /// Motion used between slides (`sliding` / `fading`) plus the gap between
  /// adjacent slides.
  ///
  /// Accepts either a Flutter [CarouselTransition] (which carries its own
  /// slide-placement renderer) or a plain [CoreCarouselTransition]; the
  /// latter is mapped onto the matching built-in renderer.
  @override
  final CoreCarouselTransition transition;

  // === Auto-play (contract) ===

  @override
  final Duration? duration;

  @override
  final bool? autoPlay;

  @override
  final bool showIndicators;

  @override
  final bool? showNavigation;

  // === Navigation (contract) ===

  @override
  final int currentIndex;

  @override
  final ValueChanged<int>? onIndexChanged;

  // === Behavior (contract) ===

  @override
  final bool wrap;

  @override
  final bool pauseOnHover;

  // === Layout / motion / advanced behaviour (contract) ===

  /// Carousel alignment within the viewport.
  @override
  final CarouselAlignment alignment;

  /// Whether auto-play runs in reverse.
  @override
  final bool autoplayReverse;

  /// Auto-play transition animation speed.
  @override
  final Duration? autoplaySpeed;

  /// External controller for programmatic control — Flutter runtime
  /// infrastructure; the Web counterpart is the stateless DOM itself.
  final CarouselController? controller;

  /// Animation easing curve.
  @override
  final CoreCubicBezier curve;

  /// Scroll direction (horizontal or vertical).
  @override
  final CoreAxis direction;

  /// Whether to disable drag velocity inertia.
  @override
  final bool disableDraggingVelocity;

  /// Whether to limit drag to one item per gesture.
  @override
  final bool disableOverheadScrolling;

  /// Whether the carousel is draggable.
  @override
  final bool draggable;

  /// Per-index duration builder for auto-play.
  @override
  final CarouselDurationBuilder? durationBuilder;

  /// Where the indicator dots sit — over the slide or under the viewport.
  @override
  final CoreCarouselVariant variant;

  /// Which set of interior metrics the parts inside use — today the
  /// indicator dot size.
  @override
  final CoreCarouselSize size;

  /// Whether to reverse item layout order.
  @override
  final bool reverse;

  /// Size constraint for carousel items.
  @override
  final CarouselSizeConstraint sizeConstraint;

  /// Transition animation speed.
  @override
  final Duration speed;

  /// Whether to wait one duration before the first auto-advance.
  @override
  final bool waitOnStart;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `prevNextButtonStyle` slot. See [CoreCarouselStyle] for the
  /// merge chain.
  @override
  final CoreCarouselStyle? carouselStyle;

  /// Returns a copy of this [Carousel] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Carousel copyWith({
    Key? key,
    List<Widget>? items,
    CarouselItemBuilder? itemBuilder,
    int? itemCount,
    CoreCarouselTransition? transition,
    Duration? duration,
    bool? autoPlay,
    bool? showIndicators,
    bool? showNavigation,
    int? currentIndex,
    ValueChanged<int>? onIndexChanged,
    bool? wrap,
    bool? pauseOnHover,
    CarouselAlignment? alignment,
    bool? autoplayReverse,
    Duration? autoplaySpeed,
    CarouselController? controller,
    CoreCubicBezier? curve,
    CoreAxis? direction,
    bool? disableDraggingVelocity,
    bool? disableOverheadScrolling,
    bool? draggable,
    CarouselDurationBuilder? durationBuilder,
    CoreCarouselVariant? variant,
    CoreCarouselSize? size,
    bool? reverse,
    CarouselSizeConstraint? sizeConstraint,
    Duration? speed,
    bool? waitOnStart,
    CoreCarouselStyle? carouselStyle,
  }) {
    return Carousel(
      key: key ?? this.key,
      items: items ?? this.items,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      itemCount: itemCount ?? this.itemCount,
      transition: transition ?? this.transition,
      duration: duration ?? this.duration,
      autoPlay: autoPlay ?? this.autoPlay,
      showIndicators: showIndicators ?? this.showIndicators,
      showNavigation: showNavigation ?? this.showNavigation,
      currentIndex: currentIndex ?? this.currentIndex,
      onIndexChanged: onIndexChanged ?? this.onIndexChanged,
      wrap: wrap ?? this.wrap,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      alignment: alignment ?? this.alignment,
      autoplayReverse: autoplayReverse ?? this.autoplayReverse,
      autoplaySpeed: autoplaySpeed ?? this.autoplaySpeed,
      controller: controller ?? this.controller,
      curve: curve ?? this.curve,
      direction: direction ?? this.direction,
      disableDraggingVelocity:
          disableDraggingVelocity ?? this.disableDraggingVelocity,
      disableOverheadScrolling:
          disableOverheadScrolling ?? this.disableOverheadScrolling,
      draggable: draggable ?? this.draggable,
      durationBuilder: durationBuilder ?? this.durationBuilder,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      reverse: reverse ?? this.reverse,
      sizeConstraint: sizeConstraint ?? this.sizeConstraint,
      speed: speed ?? this.speed,
      waitOnStart: waitOnStart ?? this.waitOnStart,
      carouselStyle: carouselStyle ?? this.carouselStyle,
    );
  }

  @override
  State<Carousel> createState() => _CarouselState();
}

// ── Private constants ──

const _kDragVelocityThreshold = 0.0001;
const _kDragThreshold = 0.01;
const _kDragDecayFactor = 0.2;
const _kDragDecayInterval = 100.0;
const _kVelocityDivisor = 100.0;
const _kMinAlignment = 0.0;

class _CarouselState extends State<Carousel>
    with SingleTickerProviderStateMixin {
  late CarouselController _controller;
  Duration? _startTime;
  late Ticker _ticker;
  bool _hovered = false;
  bool _dragging = false;
  late double _lastDragValue;
  double _dragVelocity = 0;
  late int _currentIndex;
  Duration? _lastTime;

  int? get _resolvedItemCount => widget.itemCount ?? widget.items?.length;

  CarouselItemBuilder get _resolvedItemBuilder =>
      widget.itemBuilder ??
      (context, index) {
        final items = widget.items!;
        final safeIndex = index % items.length;
        return items[safeIndex < 0 ? safeIndex + items.length : safeIndex];
      };

  // ── Resolved behaviour values (widget-only — semantic / behaviour
  // identifiers stay on the widget prop; the theme carries chrome via
  // `style` only) ──

  CarouselAlignment get _alignment => widget.alignment;

  /// Flutter axis for the Core [Carousel.direction] token.
  Axis get _direction =>
      widget.direction == .horizontal ? .horizontal : .vertical;

  /// Slide-placement renderer for the Core [Carousel.transition] value,
  /// laid at the resolved slide gap.
  ///
  /// The built-in sliding renderer — named as a Flutter
  /// [SlidingCarouselTransition] or as a plain [CoreCarouselTransition] —
  /// is laid at [ResolvedCarousel.slideGap]: the gap a transition states is
  /// a caller's spacing, which the theme density moves, and the renderer
  /// places every slide and advances the line from that one value, so the
  /// slides keep their stops. A renderer a caller wrote (any other
  /// [CarouselTransition], a subclass of the sliding one included) keeps
  /// its own placement.
  CarouselTransition _transitionFor(ResolvedCarousel resolved) {
    final transition = widget.transition;
    if (transition is CarouselTransition &&
        transition.runtimeType != SlidingCarouselTransition) {
      return transition;
    }
    return switch (transition.mode) {
      .fading => const FadingCarouselTransition(),
      .sliding => SlidingCarouselTransition(gap: resolved.slideGap),
    };
  }

  bool get _wrap => widget.wrap;

  bool get _pauseOnHover => widget.pauseOnHover;

  Duration? get _autoplaySpeed => widget.autoplaySpeed;

  bool get _draggable => widget.draggable;

  Duration get _speed => widget.speed;

  Curve get _curve => widget.curve.toValue();

  /// Whether auto-play is on, derived when the caller did not say.
  ///
  /// `null` means "decide from the interval", which is what this widget did
  /// implicitly before `autoPlay` was wired: a slide duration was the only
  /// way to turn auto-play on. Keeping that as the *default* leaves existing
  /// callers untouched while an explicit `true` / `false` now decides.
  bool get _autoPlay =>
      widget.autoPlay ??
      (widget.durationBuilder != null || widget.duration != null);

  /// The interval the ticker advances on, or `null` when auto-play is off.
  ///
  /// `null` is the ticker's own "no auto-play" signal (both gate sites read
  /// it), so the flag lands here rather than beside each of them.
  Duration? get _currentSlideDuration {
    if (!_autoPlay) return null;
    final currentIdx = _controller.getCurrentIndex(_resolvedItemCount);
    final index = currentIdx.floor();
    // An explicit `autoPlay: true` with no interval gets the design-system
    // default — the same fallback the Web twin already applied, so the flag
    // alone is enough on both platforms.
    var dur =
        widget.durationBuilder?.call(index) ??
        widget.duration ??
        CoreCarouselStyle.defaultAutoplayInterval;
    if (_autoplaySpeed != null) {
      dur += _autoplaySpeed!;
    }
    return dur;
  }

  double get _progressedValue {
    return !_wrap && _resolvedItemCount != null
        ? _controller.value.clamp(
            _kMinAlignment,
            _resolvedItemCount!.toDouble() - 1,
          )
        : _controller.value;
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    _controller = widget.controller ?? CarouselController();
    _controller.addListener(_handleControllerChange);
    _currentIndex = _controller.getCurrentIndex(_resolvedItemCount).round();
    _dispatchControllerChange();
  }

  double _resolveSize(BoxConstraints constraints) {
    if (widget.sizeConstraint is CarouselFixedConstraint) {
      return (widget.sizeConstraint as CarouselFixedConstraint).size;
    } else if (widget.sizeConstraint is CarouselFractionalConstraint) {
      return constraints.maxWidth *
          (widget.sizeConstraint as CarouselFractionalConstraint).fraction;
    }
    return constraints.maxWidth;
  }

  // ── Ticker & auto-play ──

  void _check() {
    bool shouldStart = false;
    if (_controller.shouldAnimate) {
      shouldStart = true;
    }
    if (!shouldStart && _currentSlideDuration != null) {
      if (!_pauseOnHover || !_hovered) {
        shouldStart = true;
      }
    }
    if (!shouldStart && _dragVelocity.abs() > _kDragVelocityThreshold) {
      shouldStart = true;
    }
    if (shouldStart) {
      if (!_ticker.isActive) {
        _lastTime = null;
        _startTime = null;
        unawaited(_ticker.start());
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
        _startTime = null;
        _lastTime = null;
      }
    }
  }

  void _handleTick(Duration elapsed) {
    final delta = _lastTime == null ? Duration.zero : elapsed - _lastTime!;
    _lastTime = elapsed;
    final deltaMillis = delta.inMilliseconds;

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
      _handleAutoPlay();
    }
    if (_dragVelocity.abs() > _kDragThreshold && !_dragging) {
      _handleDragDecay(deltaMillis);
    }
    _check();
  }

  void _handleAutoPlay() {
    if (!_wrap &&
        _resolvedItemCount != null &&
        _controller.value >= _resolvedItemCount! - 1) {
      _controller.animateTo(
        _kMinAlignment,
        _autoplaySpeed ?? _speed,
        _curve,
      );
    } else if (!_wrap && _resolvedItemCount != null && _controller.value <= 0) {
      _controller.animateTo(
        (_resolvedItemCount! - 1).toDouble(),
        _autoplaySpeed ?? _speed,
        _curve,
      );
    } else if (widget.autoplayReverse) {
      _controller.animatePrevious(_autoplaySpeed ?? _speed, _curve);
    } else {
      _controller.animateNext(_autoplaySpeed ?? _speed, _curve);
    }
  }

  void _handleDragDecay(int deltaMillis) {
    final targetValue = _progressedValue + _dragVelocity;
    _controller.jumpTo(targetValue);
    _dragVelocity *= pow(
      _kDragDecayFactor,
      deltaMillis / _kDragDecayInterval,
    );
    if (_dragVelocity.abs() < _kDragThreshold) {
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

  void _handleControllerChange() {
    setState(() {});
    if (!_wrap && _resolvedItemCount != null) {
      if (_controller.value < 0) {
        _controller.jumpTo(0);
      } else if (_controller.value >= _resolvedItemCount!) {
        _controller.jumpTo(_resolvedItemCount!.toDouble() - 1);
      }
    }
    _dispatchControllerChange();
  }

  void _dispatchControllerChange() {
    _check();
    final index = _controller.getCurrentIndex(_resolvedItemCount).round();
    if (index != _currentIndex) {
      _currentIndex = index;
      widget.onIndexChanged?.call(index);
    }
  }

  // ── Build helpers ──

  Widget _buildCarousel(
    BuildContext context,
    BoxConstraints constraints,
    ResolvedCarousel resolved,
  ) {
    return Stacks(
      children: _transitionFor(resolved).layout(
        context,
        alignment: _alignment,
        constraints: constraints,
        direction: _direction,
        itemBuilder: _resolvedItemBuilder,
        itemCount: _resolvedItemCount,
        progress: _progressedValue,
        progressedIndex: _progressedValue,
        reverse: widget.reverse,
        sizeConstraint: widget.sizeConstraint,
        wrap: _wrap,
      ),
    );
  }

  Widget _buildHorizontalDragger(
    BuildContext context,
    Widget child,
    BoxConstraints constraints,
  ) {
    final size = _resolveSize(constraints);
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragging = true;
        _lastDragValue = _progressedValue;
        _dragVelocity = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (_draggable) {
          setState(() {
            final increment = -details.primaryDelta! / size;
            _controller.jumpTo(_progressedValue + increment);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        _dragging = false;
        _dragVelocity = widget.disableDraggingVelocity
            ? 0
            : -details.primaryVelocity! / size / _kVelocityDivisor;
        _controller.animateSnap(_speed, _curve);
        _check();
      },
      behavior: .translucent,
      child: child,
    );
  }

  Widget _buildVerticalDragger(
    BuildContext context,
    Widget child,
    BoxConstraints constraints,
  ) {
    final size = _resolveSize(constraints);
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragging = true;
        _lastDragValue = _progressedValue;
        _dragVelocity = 0;
      },
      onVerticalDragUpdate: (details) {
        if (_draggable) {
          setState(() {
            final increment = -details.primaryDelta! / size;
            _controller.jumpTo(_progressedValue + increment);
          });
        }
      },
      onVerticalDragEnd: (details) {
        _dragging = false;
        _dragVelocity = widget.disableDraggingVelocity
            ? 0
            : -details.primaryVelocity! / size / _kVelocityDivisor;
        _controller.animateSnap(_speed, _curve);
        _check();
      },
      behavior: .translucent,
      child: child,
    );
  }

  Widget _buildNavButtons(
    BuildContext context,
    ResolvedCarousel resolved,
  ) {
    // The resolver pre-composes the nav button chrome (default carousel
    // chrome + per-instance `prevNextButtonStyle` + `controlOverlayColor`
    // override). Forward it straight to `Button(buttonStyle: …)` so the
    // button runs its own colour resolution — the chevron `Icon`
    // inherits the button's foreground / icon size via the button's
    // ambient icon theme (Epic #1603 C7 / C8).
    final navButtonStyle = resolved.navButtonStyle;

    // Hover-revealed on pointer devices: hidden until the pointer is
    // over the carousel viewport (`_hovered` from the root
    // `MouseRegion`), fading with the resolved duration token. Touch
    // devices never hover, so the buttons stay visually hidden there —
    // swiping and the indicator dots remain the touch affordances
    // (the buttons stay hit-testable and readable by screen readers).
    // Mirrors the Web `group-hover:opacity-100` CSS gate.
    //
    // `alwaysIncludeSemantics` is what makes the sentence above true.
    // The default is false, which drops a fully transparent subtree out
    // of the semantics tree entirely — so the labelled buttons existed
    // for a screen reader only while a pointer happened to be resting on
    // the carousel, which on a touch device is never. They stayed
    // hit-testable throughout, so the claim was half right and the half
    // that was wrong was the half nobody could see.
    return Position.fill(
      child: AnimatedOpacity(
        opacity: _hovered ? 1 : 0,
        duration: resolved.navFadeDuration,
        curve: CoreEasing.move.toValue(),
        alwaysIncludeSemantics: true,
        child: Padding(
          padding: resolved.navInset,
          child: Row(
            // `slide` puts one button at each end of the viewport; `banner`
            // is a strip too short for that, so the pair gathers at the
            // trailing end with a gap between them. A semantic read of the
            // widget's own `variant`, like `_showsNavigation` above.
            mainAxisAlignment: widget.variant == .banner ? .end : .spaceBetween,
            children: [
              Semantics(
                button: true,
                label: CoUILocalizations.of(context).carouselPreviousSlide,
                child: Button(
                  onPressed: () {
                    _controller.animatePrevious(_speed, _curve);
                  },
                  variant: .ghost,
                  size: .sm,
                  shape: .circle,
                  buttonStyle: navButtonStyle,
                  child: const Icon(LucideIcons.chevronLeft),
                ),
              ),
              if (widget.variant == .banner)
                Gap(gapStyle: resolved.navGapStyle),
              Semantics(
                button: true,
                label: CoUILocalizations.of(context).carouselNextSlide,
                child: Button(
                  onPressed: () {
                    _controller.animateNext(_speed, _curve);
                  },
                  variant: .ghost,
                  size: .sm,
                  shape: .circle,
                  buttonStyle: navButtonStyle,
                  child: const Icon(LucideIcons.chevronRight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether an indicator row renders at all — the caller asked for one
  /// and there is something to indicate.
  bool get _showsIndicators =>
      widget.showIndicators && (_resolvedItemCount ?? 0) > 0;

  /// Whether the prev / next controls are drawn.
  ///
  /// Derived from the variant when the caller states nothing: a `slide`
  /// fills the viewport and gives a pointer nothing else to aim at, while
  /// a `banner` is 88 logical px tall and two 32-px discs would leave no
  /// strip. A stated `showNavigation` wins either way.
  bool get _showsNavigation =>
      widget.showNavigation ?? widget.variant == CoreCarouselVariant.slide;

  /// The dot row itself, centred across the carousel. Shared by both
  /// variants — `slide` anchors it inside the viewport
  /// ([_buildOverlayIndicators]), `banner` stacks it under the viewport.
  Widget _buildIndicatorDots(ResolvedCarousel resolved, int count) {
    return Center(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          int value = _controller.value.round() % count;
          if (value < 0) {
            value += count;
          }
          // Forward the resolved nested `CoreDotIndicatorStyle` slot
          // straight to `DotIndicator` — the dot indicator runs its
          // own colour / size resolution (Epic #1603 C8).
          return DotIndicator(
            onChanged: (value) {
              _controller.animateTo(value.toDouble(), _speed, _curve);
            },
            size: resolved.dotIndicatorSize,
            index: value,
            length: count,
            dotIndicatorStyle: resolved.dotIndicatorStyle,
          );
        },
      ),
    );
  }

  Widget _buildOverlayIndicators(
    BuildContext context,
    ResolvedCarousel resolved,
  ) {
    final count = _resolvedItemCount;
    if (count == null || count == 0) return const SizedBox.shrink();

    // Position reads the resolved per-side EdgeInsets — sides left at
    // `0` collapse to `null` so the indicator row stays a one-axis
    // anchor (typically only `bottom` is non-zero, with `left` / `right`
    // kept at `0` to stretch the row horizontally for `Center`).
    final inset = resolved.indicatorInset;
    return Position(
      top: inset.top == 0 ? null : inset.top,
      right: inset.right,
      bottom: inset.bottom == 0 ? null : inset.bottom,
      left: inset.left,
      child: _buildIndicatorDots(resolved, count),
    );
  }

  /// The active slide forced to its intrinsic cross-axis extent so
  /// it can act as a non-painting sizing anchor for the carousel
  /// stack under unbounded cross-axis constraints.
  Widget _intrinsicGhostSlide() {
    final slide = _resolvedItemBuilder(
      context,
      _currentIndex.clamp(0, max(0, (_resolvedItemCount ?? 1) - 1)),
    );
    return _direction == .horizontal
        ? IntrinsicHeight(child: slide)
        : IntrinsicWidth(child: slide);
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleControllerChange);
      _controller = widget.controller ?? CarouselController();
      _controller.addListener(_handleControllerChange);
      _dispatchControllerChange();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _ticker.dispose();
    super.dispose();
  }

  /// The clipped viewport — slides, drag surface, hover-revealed nav,
  /// and (for the `slide` variant) the indicator row anchored inside.
  Widget _buildViewport(BuildContext context, ResolvedCarousel resolved) {
    final overlayIndicators = widget.variant == .slide && _showsIndicators;
    return ClipRRect(
      borderRadius: resolved.borderRadius,
      // Cross-axis sizing policy: the active slide drives the
      // carousel's intrinsic cross-axis extent. The slide is
      // mounted as a non-positioned `Stacks` child so the stack
      // grows to its intrinsic height (for horizontal carousels),
      // and the transition layout plus nav / indicator overlays
      // sit on top via `Positioned.fill`. When the parent already
      // supplies a finite cross-axis (`SizedBox(height: …)`,
      // `AspectRatio`, list cell, …) it just clips this to that
      // bound — same outcome as before, with no infinite-extent
      // explosion under unbounded parents like `Align(topCenter)`.
      //
      // The ghost slide is painted invisibly and excluded from
      // semantics so it has zero visual, hit-test, or screen-reader
      // effect — only its layout contribution matters. Slide
      // widgets that fill their parent (`Container(alignment: …)`,
      // `Center`, …) are forced to their *content* intrinsic size
      // by `IntrinsicHeight` / `IntrinsicWidth` along the carousel
      // direction's cross-axis.
      child: Stacks(
        children: [
          ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: _intrinsicGhostSlide(),
              ),
            ),
          ),
          Position.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget carousel = _buildCarousel(
                  context,
                  constraints,
                  resolved,
                );
                if (_draggable) {
                  carousel = _direction == .horizontal
                      ? _buildHorizontalDragger(
                          context,
                          carousel,
                          constraints,
                        )
                      : _buildVerticalDragger(
                          context,
                          carousel,
                          constraints,
                        );
                }
                return Stacks(
                  children: [
                    carousel,
                    if (_showsNavigation) _buildNavButtons(context, resolved),
                    if (overlayIndicators)
                      _buildOverlayIndicators(context, resolved),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The `below` placement — viewport, then a `Gap`, then the dots, in a
  /// column that hugs its content.
  ///
  /// Under a tight height the viewport takes what the dots leave: that
  /// is what the `overlay` placement does with the same constraint (the
  /// stack is forced to it), so a caller who gives the carousel a fixed
  /// height sees the same viewport fill either way, minus the row. Under
  /// a loose or unbounded height the viewport keeps its intrinsic
  /// (ghost-slide) extent, again as `overlay` does — an `Expanded` there
  /// would stretch a hugging card to the whole constraint.
  Widget _buildBelowLayout(BuildContext context, ResolvedCarousel resolved) {
    final viewport = _buildViewport(context, resolved);
    final count = _resolvedItemCount ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            if (constraints.hasTightHeight)
              Expanded(child: viewport)
            else
              viewport,
            if (_showsIndicators) ...[
              Gap(gapStyle: resolved.indicatorBelowGapStyle),
              _buildIndicatorDots(resolved, count),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCarousel(
      context,
      size: widget.size,
      variant: widget.variant,
      gap: widget.transition.gap,
      carouselStyle: widget.carouselStyle,
    );
    // The hover region wraps the whole carousel — dots included when
    // they sit below — so `pauseOnHover` and the nav reveal read the
    // pointer over any part of it, exactly as they do when the dots
    // float inside the viewport.
    return MouseRegion(
      onEnter: (event) {
        // setState so the hover-revealed nav buttons fade in — the
        // flag also gates autoplay's pause-on-hover via `_check()`.
        setState(() => _hovered = true);
        _check();
      },
      onExit: (event) {
        setState(() => _hovered = false);
        _check();
      },
      child: switch (widget.variant) {
        .slide => _buildViewport(context, resolved),
        .banner => _buildBelowLayout(context, resolved),
      },
    );
  }
}

/// Chain sugar for merging a [CoreCarouselStyle] patch into
/// [Carousel.carouselStyle] without hand-reconstructing every field.
/// Mirrors the Web `Carousel.withStyle` extension so both platforms read
/// identically. Composition slots (`items` / `itemBuilder`) keep using
/// their own APIs directly — this extension only covers the
/// [CoreCarouselStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCarouselStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreCarouselStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Carousel(transition: ..., items: [...]).radius4
/// ```
extension CarouselStyleChain on Carousel {
  /// Returns a copy of this [Carousel] with [patch] merged into
  /// [carouselStyle] (patch fields win on conflict).
  Carousel withStyle(CoreCarouselStyle patch) => copyWith(
    carouselStyle: (carouselStyle ?? const CoreCarouselStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Carousel get radius0 => withStyle(
    const CoreCarouselStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Carousel get radius2 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Carousel get radius4 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Carousel get radius6 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Carousel get radius8 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Carousel get radius10 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Carousel get radius12 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Carousel get radius14 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Carousel get radius16 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Carousel get radius20 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Carousel get radius24 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Carousel get radius28 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Carousel get radius32 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Carousel get radius36 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Carousel get radius40 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Carousel get radius48 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Carousel get radius56 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Carousel get radius64 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Carousel get radius9999 => withStyle(
    const CoreCarouselStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
