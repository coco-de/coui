import 'dart:async';
import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/infra/scrollview/scrollview_style.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// `MouseEvent.button` value reported for the middle mouse button.
const _kMiddleMouseButton = 1;

/// Web auto-scroll tick interval (~one animation frame, 16ms).
///
/// Frame cadence is a Web implementation detail — Flutter drives the
/// same per-second velocity through a vsync `Ticker`. Not a design
/// token.
const _kTickIntervalMs = 16;

/// Monotonic id source so each interceptor instance owns a unique
/// wrapper element id for DOM measurement.
int _coScrollViewInterceptorIdCounter = 0;

/// A unified middle-mouse-button hold-scroll interceptor for CoUI Web.
///
/// While the user holds the middle mouse button over [child],
/// `ScrollViewInterceptor` runs a per-frame timer that scrolls the
/// nearest scrollable ancestor by a velocity tracking the pointer's
/// distance from the press origin — the familiar desktop "autoscroll"
/// gesture. Matches the Flutter `ScrollViewInterceptor` contract
/// one-to-one and shares the same cubic velocity formula.
///
/// ```dart
/// ScrollViewInterceptor(
///   child: div([...], classes: 'overflow-auto'),
/// )
/// ```
class ScrollViewInterceptor extends UiStatefulComponent
    implements CoreScrollViewInterceptorContract<Component> {
  /// Creates a [ScrollViewInterceptor].
  const ScrollViewInterceptor({
    required this.child,
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
    this.enabled = true,
    this.scrollViewInterceptorStyle,
  });

  @override
  final Component? child;

  @override
  final bool enabled;

  @override
  final CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle;

  /// Returns a copy of this [ScrollViewInterceptor] with the given
  /// fields replaced.
  ScrollViewInterceptor copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    Component? child,
    bool? enabled,
    CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle,
  }) {
    return ScrollViewInterceptor(
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
      enabled: enabled ?? this.enabled,
      scrollViewInterceptorStyle:
          scrollViewInterceptorStyle ?? this.scrollViewInterceptorStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<ScrollViewInterceptor> createState() => _ScrollViewInterceptorState();
}

class _ScrollViewInterceptorState extends State<ScrollViewInterceptor> {
  late final String _wrapperId;

  /// Root element id — a caller-supplied id wins (passthrough) and is
  /// also the element `scrollNearestAncestorBy` targets; else the
  /// generated wrapper id.
  String get _effectiveWrapperId => component.id ?? _wrapperId;
  Timer? _ticker;
  bool _dragging = false;

  /// Pointer position at the press origin.
  double _originX = 0;
  double _originY = 0;

  /// Latest pointer position while the gesture is held.
  double _pointerX = 0;
  double _pointerY = 0;

  /// Per-build resolved auto-scroll tuning — populated by [build] and
  /// consumed by the per-frame [handleTick] callback that fires between
  /// builds. Kept off [ResolvedScrollViewInterceptor] (pure chrome)
  /// per the number_ticker separate-resolver pattern.
  ({double dragSpeed, double maxScrollSpeed})? _tuning;

  @override
  void initState() {
    super.initState();
    final id = _coScrollViewInterceptorIdCounter++;
    _wrapperId = 'co-scrollview-interceptor-$id';
  }

  void handlePointerDown(web.MouseEvent event) {
    if (!component.enabled) return;
    if (event.button != _kMiddleMouseButton || _ticker != null) return;
    // Suppress the browser's own middle-click autoscroll.
    event.preventDefault();
    // `mouseClientX/Y` re-read the coordinates as doubles — browsers
    // deliver sub-pixel mouse positions and the `int`-declared getters
    // throw a cast error on them.
    _originX = mouseClientX(event) ?? 0;
    _originY = mouseClientY(event) ?? 0;
    _pointerX = _originX;
    _pointerY = _originY;
    _ticker = Timer.periodic(
      const Duration(milliseconds: _kTickIntervalMs),
      handleTick,
    );
    setState(() => _dragging = true);
  }

  void handlePointerMove(web.MouseEvent event) {
    if (_ticker == null) return;
    _pointerX = mouseClientX(event) ?? _pointerX;
    _pointerY = mouseClientY(event) ?? _pointerY;
  }

  void handlePointerUp(web.MouseEvent event) {
    if (_ticker == null) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() => _dragging = false);
  }

  void handleTick(Timer timer) {
    final tuning = _tuning;
    if (tuning == null) return;

    // velocity = ((offset * dragSpeed) ^ cubicPower) / dt(ms)
    // — identical cubic formula to the Flutter interceptor: a small
    // pointer travel scrolls gently, a large travel scrolls fast.
    final offsetX = _pointerX - _originX;
    final offsetY = _pointerY - _originY;
    double incX =
        pow(
          offsetX * tuning.dragSpeed,
          CoreScrollViewInterceptorStyle.cubicPower,
        ) /
        _kTickIntervalMs;
    double incY =
        pow(
          offsetY * tuning.dragSpeed,
          CoreScrollViewInterceptorStyle.cubicPower,
        ) /
        _kTickIntervalMs;
    incX = incX.clamp(-tuning.maxScrollSpeed, tuning.maxScrollSpeed).toDouble();
    incY = incY.clamp(-tuning.maxScrollSpeed, tuning.maxScrollSpeed).toDouble();
    if (incX == 0 && incY == 0) return;
    scrollNearestAncestorBy(_effectiveWrapperId, deltaX: incX, deltaY: incY);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (!component.enabled) {
      return Component.element(
        tag: 'div',
        id: component.id,
        classes: component.classes,
        styles: component.css,
        attributes: component.componentAttributes,
        events: component.events,
        children: [?component.child],
      );
    }

    // Chrome resolver finishes the root className (`cursor-all-scroll`
    // flip). `co_*` reads the paint-ready string directly.
    final resolved = resolveScrollViewInterceptor(
      context,
      dragging: _dragging,
    );
    // Behavioural auto-scroll tuning resolved off the merge chain via the
    // separate `resolve*` entry point — read by the per-frame
    // `handleTick` callback between builds. Kept off
    // `ResolvedScrollViewInterceptor` (pure chrome) per the
    // number_ticker pattern.
    _tuning = resolveScrollViewInterceptorTuning(
      context,
      scrollViewInterceptorStyle: component.scrollViewInterceptorStyle,
    );

    return Component.element(
      tag: 'div',
      id: _effectiveWrapperId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: {
        ...component.events,
        'pointerdown': EventHandlers.createMouseEventHandler(
          handlePointerDown,
        ),
        'pointermove': EventHandlers.createMouseEventHandler(
          handlePointerMove,
        ),
        'pointerup': EventHandlers.createMouseEventHandler(handlePointerUp),
        'pointercancel': EventHandlers.createMouseEventHandler(
          handlePointerUp,
        ),
      },
      children: [?component.child],
    );
  }
}

/// Chain sugar for merging a [CoreScrollViewInterceptorStyle] patch into
/// [ScrollViewInterceptor.scrollViewInterceptorStyle] via the existing
/// [ScrollViewInterceptor.copyWith]. Mirrors the Flutter
/// `ScrollViewInterceptor.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreScrollViewInterceptorStyle.merge` right-side-wins
/// semantics).
extension ScrollViewInterceptorStyleChain on ScrollViewInterceptor {
  /// Returns a copy of this [ScrollViewInterceptor] with [patch] merged
  /// into [scrollViewInterceptorStyle] (patch fields win on conflict).
  ScrollViewInterceptor withStyle(CoreScrollViewInterceptorStyle patch) =>
      copyWith(
        scrollViewInterceptorStyle:
            (scrollViewInterceptorStyle ??
                    const CoreScrollViewInterceptorStyle())
                .merge(patch),
      );
}
