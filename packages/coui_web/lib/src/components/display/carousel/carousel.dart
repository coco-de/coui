import 'dart:async';
import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/carousel/carousel_style.dart';
import 'package:coui_web/src/components/display/dot_indicator/dot_indicator.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Default autoplay interval (3000ms) — behavioural timing sourced
/// straight from the contract design-system default.
const Duration _kDefaultAutoplayInterval =
    CoreCarouselStyle.defaultAutoplayInterval;

/// Prev/Next icons — matches Flutter LucideIcons.chevronLeft/Right.
const IconName _kPrevIcon = LucideIcons.chevronLeft;
const IconName _kNextIcon = LucideIcons.chevronRight;

/// Delay after the CSS transition before performing the wrap jump (ms).
const int _kWrapJumpDelay = 20;

/// Delay before re-enabling the transition after a wrap jump (ms).
const int _kWrapReenableDelay = 30;

/// Web typedef for the cross-platform carousel slide builder.
typedef CarouselItemBuilder = CoreCarouselItemBuilder<Component>;

/// Web typedef for the cross-platform per-index autoplay interval builder.
typedef CarouselDurationBuilder = CoreCarouselDurationBuilder;

/// Unified cross-platform carousel for CoUI Web.
///
/// StatefulComponent with autoPlay timer, CSS transition, pointer dragging,
/// prev/next navigation, and dot indicators. `sliding` transitions run a
/// translated flex line (with a clone buffer for seamless wrap-around);
/// `fading` transitions cross-fade absolutely positioned slides in place.
///
/// A vertical carousel needs a bounded height from its parent — CSS cannot
/// derive a viewport height from stacked slides, exactly as the Flutter twin
/// needs a bounded main axis.
class Carousel extends UiStatefulComponent
    implements CoreCarouselContract<Component> {
  /// Creates a [Carousel].
  const Carousel({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    // === Content ===
    this.items,
    this.itemBuilder,
    this.itemCount,
    // === Transition ===
    this.transition = const CoreCarouselTransition.sliding(),
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
    this.alignment = CoreCarouselAlignment.center,
    this.autoplayReverse = false,
    this.autoplaySpeed,
    this.curve = CoreEasing.move,
    this.direction = CoreAxis.horizontal,
    this.disableDraggingVelocity = false,
    this.disableOverheadScrolling = true,
    this.draggable = true,
    this.durationBuilder,
    this.variant = CoreCarouselVariant.defaultVariant,
    this.size = CoreCarouselSize.defaultSize,
    this.reverse = false,
    this.sizeConstraint = const CoreCarouselSizeConstraint.fractional(1),
    this.speed = CoreCarouselStyle.defaultTransitionSpeed,
    this.waitOnStart = false,
    this.carouselStyle,
  });

  // === Content ===

  @override
  final List<Component>? items;

  /// Builds slides on demand, as an alternative to [items].
  @override
  final CarouselItemBuilder? itemBuilder;

  @override
  final int? itemCount;

  // === Transition ===

  /// Motion used between slides (`sliding` / `fading`) plus the gap between
  /// adjacent slides.
  @override
  final CoreCarouselTransition transition;

  // === Auto-play ===

  @override
  final Duration? duration;

  @override
  final bool? autoPlay;

  @override
  final bool showIndicators;

  @override
  final bool? showNavigation;

  // === Navigation ===

  @override
  final int currentIndex;

  @override
  final CoreValueChanged<int>? onIndexChanged;

  // === Behavior ===

  @override
  final bool wrap;

  @override
  final bool pauseOnHover;

  // === Layout / motion / advanced behaviour ===

  /// Carousel alignment within the viewport.
  @override
  final CoreCarouselAlignment alignment;

  /// Whether auto-play runs in reverse.
  @override
  final bool autoplayReverse;

  /// Auto-play transition animation speed.
  @override
  final Duration? autoplaySpeed;

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
  final CoreCarouselSizeConstraint sizeConstraint;

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
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<Component>? items,
    CarouselItemBuilder? itemBuilder,
    int? itemCount,
    CoreCarouselTransition? transition,
    Duration? duration,
    bool? autoPlay,
    bool? showIndicators,
    bool? showNavigation,
    int? currentIndex,
    CoreValueChanged<int>? onIndexChanged,
    bool? wrap,
    bool? pauseOnHover,
    CoreCarouselAlignment? alignment,
    bool? autoplayReverse,
    Duration? autoplaySpeed,
    CoreCubicBezier? curve,
    CoreAxis? direction,
    bool? disableDraggingVelocity,
    bool? disableOverheadScrolling,
    bool? draggable,
    CarouselDurationBuilder? durationBuilder,
    CoreCarouselVariant? variant,
    CoreCarouselSize? size,
    bool? reverse,
    CoreCarouselSizeConstraint? sizeConstraint,
    Duration? speed,
    bool? waitOnStart,
    CoreCarouselStyle? carouselStyle,
  }) {
    return Carousel(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

/// Chain sugar mirroring the Flutter `Carousel.withStyle` extension —
/// merges a [CoreCarouselStyle] patch into [Carousel.carouselStyle] via
/// the existing [Carousel.copyWith].
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
/// Carousel(items: [...]).radius4
/// ```
extension CarouselStyleChain on Carousel {
  /// Returns a copy of this [Carousel] with [patch] merged into
  /// [carouselStyle] (patch fields win on conflict).
  Carousel withStyle(CoreCarouselStyle patch) => copyWith(
    carouselStyle: (carouselStyle ?? const CoreCarouselStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)` — spelled as
  /// [CoreBorderRadius.zero], the same constant.
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

/// Velocity decay factor per 100ms — matches Flutter _kDragDecayFactor.
const _kDragDecayFactor = 0.2;

/// Decay interval in ms — matches Flutter _kDragDecayInterval.
const _kDragDecayInterval = 100.0;

/// Velocity divisor — matches Flutter _kVelocityDivisor.
const _kVelocityDivisor = 100.0;

/// Minimum velocity before snapping — matches Flutter _kDragThreshold.
const _kVelocityThreshold = 0.01;

/// Frame interval for the velocity decay timer (~60fps).
const _kFrameInterval = 16;

/// Milliseconds per second — for px/ms → px/sec conversion.
const _kMsPerSec = 1000.0;

/// Fallback drag extent (px) when the pointer target reports no size, so a
/// drag divides by 1 instead of 0.
const _kFallbackDragExtent = 1.0;

/// Slides a single gesture may advance when `disableOverheadScrolling`.
const _kSingleSlide = 1;

class _CarouselState extends State<Carousel> {
  /// Real slide index. Transiently steps one slide outside
  /// `[0, count - 1]` while a `sliding` wrap-around animates into the
  /// clone buffer, then snaps back on [_scheduleWrapJump].
  late int _index;

  Timer? _autoPlayTimer;
  bool _hovered = false;
  bool _dragging = false;

  /// Pointer coordinate along the carousel axis where the drag started.
  double _dragStart = 0;

  /// Slide extent along the carousel axis, in px, measured at drag start —
  /// one slide of drag travel.
  double _dragSlideExtent = _kFallbackDragExtent;

  /// Fractional drag progress in slide units.
  /// Positive = dragging to show next, negative = show previous.
  double _dragProgress = 0;

  /// Drag velocity in slide units per frame — used for inertia after release.
  double _dragVelocity = 0;

  /// Timer for the velocity decay animation after drag release.
  Timer? _velocityDecayTimer;

  Timer? _wrapJumpTimer;
  Timer? _wrapReenableTimer;

  /// The "display" index for indicators — set immediately on wrap
  /// transitions so indicators update without waiting for the jump.
  int? _pendingDisplayIndex;

  /// Whether the CSS transition is currently disabled (for instant jumps).
  bool _transitionDisabled = false;

  /// Transition duration of the move currently in flight — `speed` for a
  /// manual move, `autoplaySpeed` for an auto-play advance.
  late Duration _activeSpeed;

  /// Timestamp of the last pointermove, for velocity calculation.
  double _lastMoveTime = 0;

  /// Last pointer coordinate along the carousel axis, for velocity.
  double _lastMove = 0;

  int get _itemCount => component.itemCount ?? component.items?.length ?? 0;

  bool get _isVertical => component.direction == .vertical;

  bool get _isFading => component.transition.mode == .fading;

  /// Whether the carousel wraps *and* has enough slides for wrapping to
  /// mean anything.
  bool get _useWrap => component.wrap && _itemCount > 1;

  /// Slides cloned before and after the real list so a `sliding`
  /// wrap-around animates into real content instead of empty space.
  ///
  /// A slide narrower than the viewport leaves neighbours visible, so the
  /// buffer must cover however many slides fit: `ceil(1 / fraction)`. A
  /// fixed slide extent cannot be compared against the viewport without
  /// measuring it, so the whole list is mirrored on both sides.
  int get _cloneCount {
    if (!_useWrap || _isFading) return 0;
    final constraint = component.sizeConstraint;
    if (constraint is CoreCarouselFractionalConstraint) {
      return min(_itemCount, max(1, (1 / constraint.fraction).ceil()));
    }
    return _itemCount;
  }

  /// Continuous slide position including any in-flight drag.
  double get _progress => _index + _dragProgress;

  @override
  void initState() {
    super.initState();
    _index = component.currentIndex;
    _activeSpeed = component.speed;
    _startAutoPlay();
  }

  // ── Auto-play ─────────────────────────────────────────

  /// Resolved interval the slide at [index] stays before auto-advancing.
  ///
  /// `autoplaySpeed` extends the interval so a slow auto-play transition
  /// does not eat into the slide's display time (Flutter parity).
  Duration _autoPlayInterval(int index) {
    var interval =
        component.durationBuilder?.call(index) ??
        component.duration ??
        _kDefaultAutoplayInterval;
    final autoplaySpeed = component.autoplaySpeed;
    if (autoplaySpeed != null) interval += autoplaySpeed;
    return interval;
  }

  /// Whether auto-play is on, derived when the caller did not say.
  ///
  /// Mirrors the Flutter twin: `null` means "decide from the interval". This
  /// side already gated on the flag, so the derivation is what changed —
  /// a lone `duration:` now auto-plays here too instead of being ignored.
  bool get _autoPlay =>
      component.autoPlay ??
      (component.durationBuilder != null || component.duration != null);

  void _startAutoPlay() {
    if (!_autoPlay || _itemCount <= 1) return;
    // `waitOnStart` decides whether the first advance waits a full slide
    // duration; without it the carousel advances as soon as it is mounted.
    _autoPlayTimer = Timer(
      component.waitOnStart ? _autoPlayInterval(_index) : .zero,
      _handleAutoPlayTick,
    );
  }

  void _handleAutoPlayTick() {
    if (!mounted) return;
    if (!(_hovered && component.pauseOnHover)) {
      _activeSpeed = component.autoplaySpeed ?? component.speed;
      if (component.autoplayReverse) {
        _handleGoPrev();
      } else {
        _handleGoNext();
      }
    }
    _autoPlayTimer = Timer(_autoPlayInterval(_index), _handleAutoPlayTick);
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  // ── Navigation ────────────────────────────────────────

  void _handleGoTo(int index) {
    setState(() {
      _index = index;
    });
    component.onIndexChanged?.call(index);
  }

  void _handleGoPrev() {
    if (_itemCount == 0) return;
    if (!component.wrap) {
      if (_index > 0) _handleGoTo(_index - 1);
      return;
    }
    if (_index > 0) {
      _pendingDisplayIndex = null;
      _handleGoTo(_index - 1);
      return;
    }
    if (_isFading) {
      // Cross-fading slides never leave their slot, so the opacity ramp
      // measured the short way around already reads as a wrap — no clone
      // buffer and no jump needed.
      _pendingDisplayIndex = null;
      _handleGoTo(_itemCount - 1);
      return;
    }
    // Animate into the trailing clone (virtual index -1), then jump to the
    // real last slide once the transition has landed.
    setState(() {
      _transitionDisabled = false;
      _index = -1;
      _pendingDisplayIndex = _itemCount - 1;
    });
    _scheduleWrapJump(_itemCount - 1);
  }

  void _handleGoNext() {
    if (_itemCount == 0) return;
    if (!component.wrap) {
      if (_index < _itemCount - 1) _handleGoTo(_index + 1);
      return;
    }
    if (_index < _itemCount - 1) {
      _pendingDisplayIndex = null;
      _handleGoTo(_index + 1);
      return;
    }
    if (_isFading) {
      _pendingDisplayIndex = null;
      _handleGoTo(0);
      return;
    }
    // Animate into the leading clone (virtual index count), then jump to
    // the real first slide once the transition has landed.
    setState(() {
      _transitionDisabled = false;
      _index = _itemCount;
      _pendingDisplayIndex = 0;
    });
    _scheduleWrapJump(0);
  }

  /// After the transition animation completes, instantly jump to the real
  /// index without a transition.
  void _scheduleWrapJump(int realIndex) {
    final speed = _activeSpeed.inMilliseconds;
    _wrapJumpTimer?.cancel();
    _wrapJumpTimer = Timer(
      Duration(milliseconds: speed + _kWrapJumpDelay),
      () {
        if (!mounted) return;
        setState(() {
          _transitionDisabled = true;
          _index = realIndex;
        });
        // Re-enable the transition on the next frame.
        _wrapReenableTimer?.cancel();
        _wrapReenableTimer = Timer(
          const Duration(milliseconds: _kWrapReenableDelay),
          () {
            if (mounted) {
              setState(() {
                _transitionDisabled = false;
                _pendingDisplayIndex = null;
              });
            }
            component.onIndexChanged?.call(realIndex);
          },
        );
      },
    );
  }

  // ── Hover / drag ──────────────────────────────────────

  void _handleMouseEnter(web.MouseEvent event) {
    _hovered = true;
  }

  void _handleMouseLeave(web.MouseEvent event) {
    _hovered = false;
    // Don't end drag here — document listeners handle it
    // so drag continues even when the pointer leaves the carousel,
    // matching Flutter's GestureDetector behavior.
  }

  /// Reads the pointer coordinate along the carousel axis.
  ///
  /// Both are read through the JS-interop helpers — the typed
  /// `MouseEvent.clientX` / `clientY` getters are declared `int`, but real
  /// PointerEvent coordinates are fractional doubles, so a direct getter
  /// throws a runtime TypeError and would kill the handler before the
  /// document move listeners register (drag dead).
  double? _axisCoordinate(Object event) => _isVertical
      ? dom_utils.mouseClientY(event)
      : dom_utils.mouseClientX(event);

  /// One slide of drag travel, in px, for the element the drag started on.
  ///
  /// Mirrors Flutter dividing the drag delta by the *slide* extent rather
  /// than the viewport extent, so a partial-width carousel drags at the
  /// same rate on both platforms.
  double _resolveDragSlideExtent(web.MouseEvent event) {
    final viewport = switch (event.currentTarget) {
      final web.HTMLElement element =>
        _isVertical
            ? element.clientHeight.toDouble()
            : element.clientWidth.toDouble(),
      _ => _kFallbackDragExtent,
    };
    final constraint = component.sizeConstraint;
    final extent = switch (constraint) {
      final CoreCarouselFixedConstraint c => c.size,
      final CoreCarouselFractionalConstraint c => viewport * c.fraction,
      _ => viewport,
    };
    return extent <= 0 ? _kFallbackDragExtent : extent;
  }

  void _handleMouseDown(web.MouseEvent event) {
    if (!component.draggable) return;
    final downCoordinate = _axisCoordinate(event);
    if (downCoordinate == null) return;
    _stopVelocityDecay();
    _dragging = true;
    _dragStart = downCoordinate;
    _dragProgress = 0;
    _dragVelocity = 0;
    _activeSpeed = component.speed;

    _lastMove = _dragStart;
    _lastMoveTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    _dragSlideExtent = _resolveDragSlideExtent(event);

    // Register document-level listeners so drag continues outside carousel.
    dom_utils.registerDragListeners(
      onMove: (e) {
        if (!_dragging) return;
        final coordinate = _axisCoordinate(e);
        if (coordinate == null) return;
        final now = DateTime.now().millisecondsSinceEpoch.toDouble();

        // Track velocity to match Flutter's calculation:
        // Flutter: _dragVelocity = -primaryVelocity / size / 100
        //   primaryVelocity is px/sec, size is the slide extent in px
        // Web: pxPerMs is px/ms = px/sec / 1000
        //   so: -(pxPerMs * 1000) / slideExtent / 100
        final dt = now - _lastMoveTime;
        if (dt > 0) {
          final pxPerMs = (coordinate - _lastMove) / dt;
          final pxPerSec = pxPerMs * _kMsPerSec;
          _dragVelocity = -pxPerSec / _dragSlideExtent / _kVelocityDivisor;
        }
        _lastMove = coordinate;
        _lastMoveTime = now;

        setState(() {
          _dragProgress = -(coordinate - _dragStart) / _dragSlideExtent;
        });
      },
      onUp: (e) {
        if (!_dragging) return;
        _dragging = false;
        if (component.disableDraggingVelocity) _dragVelocity = 0;
        // Start velocity decay animation (matching Flutter's _handleDragDecay).
        _startVelocityDecay();
      },
      downEvent: event,
    );
  }

  /// Starts the velocity decay animation after drag release.
  /// Matches Flutter's ticker-based _handleDragDecay logic.
  void _startVelocityDecay() {
    if (_dragVelocity.abs() < _kVelocityThreshold) {
      // No significant velocity — snap immediately.
      _snapToNearest();
      return;
    }

    _velocityDecayTimer = Timer.periodic(
      const Duration(milliseconds: _kFrameInterval),
      (_) {
        setState(() {
          _dragProgress += _dragVelocity;
          // Exponential decay: matches Flutter's pow(0.2, dt/100).
          _dragVelocity *= pow(
            _kDragDecayFactor,
            _kFrameInterval / _kDragDecayInterval,
          );
        });

        if (_dragVelocity.abs() < _kVelocityThreshold) {
          _stopVelocityDecay();
          _snapToNearest();
        }
      },
    );
  }

  /// Snaps to the nearest integer index from the current drag progress.
  /// Matches Flutter's animateSnap (round to nearest).
  void _snapToNearest() {
    final targetIndex = _progress.round();

    // Reset drag progress.
    _dragProgress = 0;
    _dragVelocity = 0;

    // Determine how many slides to move — `disableOverheadScrolling` caps
    // one gesture at a single slide (Flutter parity).
    var delta = targetIndex - _index;
    if (component.disableOverheadScrolling) {
      delta = delta.clamp(-_kSingleSlide, _kSingleSlide);
    }

    if (delta == 0) {
      setState(() {});
      return;
    }
    final steps = delta.abs();
    final speed = _activeSpeed.inMilliseconds;
    for (var i = 0; i < steps; i++) {
      if (i == 0) {
        if (delta > 0) {
          _handleGoNext();
        } else {
          _handleGoPrev();
        }
        continue;
      }
      // Queue subsequent moves after the transition completes.
      Future.delayed(Duration(milliseconds: speed * i), () {
        if (!mounted) return;
        if (delta > 0) {
          _handleGoNext();
        } else {
          _handleGoPrev();
        }
      });
    }
  }

  void _stopVelocityDecay() {
    _velocityDecayTimer?.cancel();
    _velocityDecayTimer = null;
  }

  // ── Slide content ─────────────────────────────────────

  /// Wraps [index] into `[0, count)` so a negative or overshooting slide
  /// position maps back onto real content.
  int _wrapIndex(int index) {
    final count = _itemCount;
    if (count <= 0) return 0;
    final wrapped = index % count;
    return wrapped < 0 ? wrapped + count : wrapped;
  }

  /// Builds the slide content for the slide at [position].
  ///
  /// [Carousel.reverse] flips which content lands on which position;
  /// [Carousel.itemBuilder] receives the raw (possibly out-of-range)
  /// position exactly as the Flutter twin does, while the eager
  /// [Carousel.items] path wraps it.
  Component _slideContent(BuildContext context, int position) {
    final index = component.reverse ? -position : position;
    final builder = component.itemBuilder;
    if (builder != null) return builder(context, index);
    final items = component.items;
    if (items == null || items.isEmpty) return const Component.empty();
    return items[_wrapIndex(index)];
  }

  @override
  void didUpdateComponent(covariant Carousel oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.currentIndex != component.currentIndex) {
      _index = component.currentIndex;
    }
    if (oldComponent.autoPlay != component.autoPlay ||
        oldComponent.duration != component.duration ||
        oldComponent.durationBuilder != component.durationBuilder ||
        oldComponent.autoplaySpeed != component.autoplaySpeed ||
        oldComponent.waitOnStart != component.waitOnStart) {
      _stopAutoPlay();
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _stopVelocityDecay();
    _wrapJumpTimer?.cancel();
    _wrapReenableTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final count = _itemCount;
    final buffer = _cloneCount;
    // Slide positions rendered, in DOM order. A sliding carousel renders
    // a clone buffer on both sides so the wrap-around animates into real
    // content, while a cross-fading one needs none because every slide
    // keeps its slot.
    final slidePositions = [
      for (var position = -buffer; position < count + buffer; position++)
        position,
    ];

    final resolved = resolveCarousel(
      context,
      alignment: component.alignment,
      animate: !_dragging && !_transitionDisabled,
      curve: component.curve,
      direction: component.direction,
      gap: component.transition.gap,
      variant: component.variant,
      itemCount: count,
      mode: component.transition.mode,
      progress: _progress,
      sizeConstraint: component.sizeConstraint,
      slidePositions: slidePositions,
      speed: _activeSpeed,
      wrap: component.wrap,
      carouselStyle: component.carouselStyle,
    );

    // Inner chevron icon size — {Button}.sm icon-shape size token (the
    // glyph of a `circle` button, which has no label to sit beside; the
    // Flutter twin takes the same size from the button's ambient icon
    // theme), applied to both prev / next buttons so the glyph stays
    // consistent when the resolved nav button chrome scales.
    final navIconSize = CoreButtonStyle
        .defaultsBySize[CoreComponentSize.sm]!
        .iconShapeIconStyle!
        .size!;
    final navIconStyle = CoreIconStyle(size: navIconSize);

    // Build the slide wrappers. A clone is the same content a second time:
    // leaving it reachable makes a screen reader read the slide twice and
    // Tab visit its controls twice, in a track the user cannot see the
    // ends of — so clones are inert.
    final slides = <Component>[];
    for (var i = 0; i < slidePositions.length; i++) {
      final position = slidePositions[i];
      final isClone = position < 0 || position >= count;
      slides.add(
        div(
          [_slideContent(context, position)],
          classes: resolved.slides[i].className,
          styles: resolved.slides[i].inlineStyles,
          attributes: isClone ? const {'inert': ''} : null,
        ),
      );
    }

    // Resolve the display index for indicators.
    // Use the pending index during wrap transitions for instant update.
    final displayIndex =
        _pendingDisplayIndex ?? _index.clamp(0, count > 0 ? count - 1 : 0);
    final showsIndicators = component.showIndicators && count > 1;
    // Derived from the variant when the caller states nothing: a `slide`
    // fills the viewport and gives a pointer nothing else to aim at, while
    // a `banner` is 88 logical px tall and two 32-px discs would leave no
    // strip. A stated `showNavigation` wins either way. Mirrors Flutter's
    // `_showsNavigation`.
    final showsNavigation =
        component.showNavigation ?? component.variant == .slide;
    final isBelow = component.variant == .banner;

    // The dot row — shared by both variants. `slide` wraps it in the
    // absolute indicatorRow; `banner` places it in flow under the viewport.
    final dots = DotIndicator(
      onChanged: (value) {
        _activeSpeed = component.speed;
        _handleGoTo(value);
      },
      // A semantic identifier, so it stays a widget read — and the enum
      // converts itself, which is what keeps Flutter's answer the same.
      size: component.size.toDotIndicatorSize(),
      index: displayIndex,
      length: count,
      direction: component.direction,
      dotIndicatorStyle: resolved.dotIndicatorStyle,
    );

    // The prev / next buttons. An icon-only button has no accessible name of
    // its own — a chevron glyph is not text. Unnamed, it announced as
    // "button" with nothing to distinguish it from the one on the other side.
    // The Flutter twin has labelled these all along.
    Component prevButton() => Button(
      onPressed: _handleGoPrev,
      variant: .ghost,
      size: .sm,
      shape: .circle,
      buttonStyle: resolved.navButtonStyle,
      classes: resolved.prevNavButton.className,
      css: resolved.prevNavButton.inlineStyles,
      attributes: {
        'aria-label': CouiLocalizations.of(context).carouselPreviousSlide,
      },
      child: Icon(_kPrevIcon, iconStyle: navIconStyle),
    );
    Component nextButton() => Button(
      onPressed: _handleGoNext,
      variant: .ghost,
      size: .sm,
      shape: .circle,
      buttonStyle: resolved.navButtonStyle,
      classes: resolved.nextNavButton.className,
      css: resolved.nextNavButton.inlineStyles,
      attributes: {
        'aria-label': CouiLocalizations.of(context).carouselNextSlide,
      },
      child: Icon(_kNextIcon, iconStyle: navIconStyle),
    );
    final groupsNavigation = isBelow && component.direction == .horizontal;

    // Everything the viewport holds: the slides, and the nav buttons that
    // overlay them in both placements. For `overlay` these land directly
    // on the root (which carries the viewport chrome); for `below` they
    // are wrapped in a viewport `<div>` inside the column root.
    final viewportChildren = <Component>[
      // Invisible in-flow height anchor — cross-faded slides are all
      // absolutely positioned, so without it the viewport collapses.
      if (_isFading && count > 0)
        div(
          [_slideContent(context, displayIndex)],
          classes: resolved.sizingSlide.className,
          styles: resolved.sizingSlide.inlineStyles,
          attributes: const {'inert': '', 'aria-hidden': 'true'},
        ),
      // Slide container.
      div(
        slides,
        classes: resolved.track.className,
        styles: resolved.track.inlineStyles,
      ),
      // Prev / next — each inside an anchor that carries the position and
      // the hover reveal. The fade is not on the `Button`: its shared
      // `transition` is `!important` and names no `opacity`.
      //
      // `slide` anchors one button at each end of the viewport. `banner` on a
      // horizontal carousel is a strip too short for that, so the pair
      // shares the trailing anchor — the next button's — side by side with
      // the gap between them, as the Flutter twin's `Row` does.
      if (showsNavigation && count > 1)
        if (groupsNavigation)
          div(
            [prevButton(), Gap(gapStyle: resolved.navGapStyle), nextButton()],
            classes: resolved.nextNavReveal.className,
            styles: resolved.nextNavReveal.inlineStyles,
          )
        else ...[
          div(
            [prevButton()],
            classes: resolved.prevNavReveal.className,
            styles: resolved.prevNavReveal.inlineStyles,
          ),
          div(
            [nextButton()],
            classes: resolved.nextNavReveal.className,
            styles: resolved.nextNavReveal.inlineStyles,
          ),
        ],
    ];

    return div(
      [
        if (isBelow)
          div(
            viewportChildren,
            classes: resolved.viewport.className,
            styles: resolved.viewport.inlineStyles,
          )
        else
          ...viewportChildren,
        // Indicators — anchored inside the viewport, or stacked under it
        // after the resolved spacer.
        if (showsIndicators && !isBelow)
          div(
            [dots],
            classes: resolved.indicatorRow.className,
            styles: resolved.indicatorRow.inlineStyles,
          ),
        if (showsIndicators && isBelow) ...[
          Gap(gapStyle: resolved.indicatorBelowGapStyle),
          dots,
        ],
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?component.css]),
      attributes: {
        ...component.componentAttributes,
        'role': CoreSemanticRole.region.ariaRole,
        'aria-label': CouiLocalizations.of(context).carouselLabel,
      },
      events: {
        ...component.events,
        'mouseenter': EventHandlers.createMouseEventHandler(_handleMouseEnter),
        'mouseleave': EventHandlers.createMouseEventHandler(_handleMouseLeave),
        // Trigger on pointerdown because the drag listeners are pointer
        // events — on touch devices the compatibility mousedown fires after
        // the gesture's pointerup and would leak them.
        'pointerdown': EventHandlers.createMouseEventHandler(_handleMouseDown),
      },
    );
  }
}
