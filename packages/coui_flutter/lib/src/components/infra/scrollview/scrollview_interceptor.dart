import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Bitmask value reported by `PointerEvent.buttons` while the middle
/// mouse button is held.
const _kMiddleMouseButton = 4;

/// Synthetic scroll event emitted by [ScrollViewInterceptor] while
/// middle-mouse hold-scroll is active.
///
/// A distinct subtype lets downstream listeners tell interceptor-driven
/// scrolling apart from a physical wheel event when they need to.
class DesktopPointerScrollEvent extends PointerScrollEvent {
  /// Creates a [DesktopPointerScrollEvent].
  const DesktopPointerScrollEvent({
    required super.device,
    required super.embedderId,
    required super.kind,
    required super.position,
    required super.scrollDelta,
    required super.timeStamp,
    required super.viewId,
  });
}

/// A unified middle-mouse-button hold-scroll interceptor.
///
/// While the user holds the middle mouse button over [child],
/// `ScrollViewInterceptor` synthesises continuous scroll events
/// whose velocity tracks the pointer's distance from the press
/// origin — the familiar desktop "autoscroll" gesture.
///
/// The drag-speed multiplier and the velocity cap flow through the
/// single [scrollViewInterceptorStyle] slot; the behavioural [enabled]
/// flag stays flat on the widget.
///
/// ```dart
/// ScrollViewInterceptor(
///   child: ListView(children: [...]),
/// )
/// ```
class ScrollViewInterceptor extends StatefulWidget
    implements CoreScrollViewInterceptorContract<Widget> {
  /// Creates a [ScrollViewInterceptor].
  const ScrollViewInterceptor({
    required this.child,
    this.enabled = true,
    this.scrollViewInterceptorStyle,
    super.key,
  });

  @override
  final Widget child;

  @override
  final bool enabled;

  @override
  final CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle;

  /// Returns a copy of this [ScrollViewInterceptor] with the given
  /// fields replaced. All fields default to this instance's current
  /// value when omitted.
  ScrollViewInterceptor copyWith({
    Key? key,
    Widget? child,
    bool? enabled,
    CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle,
  }) {
    return ScrollViewInterceptor(
      key: key ?? this.key,
      enabled: enabled ?? this.enabled,
      scrollViewInterceptorStyle:
          scrollViewInterceptorStyle ?? this.scrollViewInterceptorStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<ScrollViewInterceptor> createState() => _ScrollViewInterceptorState();
}

class _ScrollViewInterceptorState extends State<ScrollViewInterceptor>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration? _lastTime;
  PointerDownEvent? _event;
  Offset? _lastOffset;
  MouseCursor? _cursor;
  ResolvedScrollViewInterceptor? _resolved;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
  }

  void _handleTick(Duration elapsed) {
    final delta = _lastTime == null ? Duration.zero : elapsed - _lastTime!;
    _lastTime = elapsed;
    if (delta.inMilliseconds == 0) return;
    final event = _event;
    final lastOffset = _lastOffset;
    final tuning = _resolved;
    if (event == null || lastOffset == null || tuning == null) return;

    final positionDelta = event.position - lastOffset;

    // velocity = ((-offset * dragSpeed) ^ cubicPower) / dt(ms)
    // — a cubic curve so a small pointer travel scrolls gently and a
    // large travel scrolls fast. Identical to the Web tick formula.
    double incX =
        pow(
          -positionDelta.dx * tuning.dragSpeed,
          CoreScrollViewInterceptorStyle.cubicPower,
        ) /
        delta.inMilliseconds;
    double incY =
        pow(
          -positionDelta.dy * tuning.dragSpeed,
          CoreScrollViewInterceptorStyle.cubicPower,
        ) /
        delta.inMilliseconds;
    incX = incX.clamp(-tuning.maxScrollSpeed, tuning.maxScrollSpeed).toDouble();
    incY = incY.clamp(-tuning.maxScrollSpeed, tuning.maxScrollSpeed).toDouble();

    final instance = GestureBinding.instance;
    final result = HitTestResult();
    instance.hitTestInView(result, event.position, event.viewId);
    final scrollEvent = DesktopPointerScrollEvent(
      device: event.device,
      embedderId: event.embedderId,
      kind: event.kind,
      position: event.position,
      scrollDelta: Offset(incX, incY),
      timeStamp: Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch,
      ),
      viewId: event.viewId,
    );
    for (final entry in result.path) {
      try {
        final target = entry.target;
        target.handleEvent(scrollEvent, entry);
      } on Exception catch (e, s) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: s,
            library: 'coui_flutter',
            context: ErrorDescription(
              'while dispatching a pointer scroll event',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    _resolved = resolveScrollViewInterceptor(
      context,
      scrollViewInterceptorStyle: widget.scrollViewInterceptorStyle,
    );

    return Stacks(
      fit: .passthrough,
      clipBehavior: .none,
      children: [
        Listener(
          onPointerDown: (event) {
            // Start auto-scroll only on the middle mouse button.
            if (event.buttons != _kMiddleMouseButton || _ticker.isActive) {
              return;
            }
            _event = event;
            _lastOffset = event.position;
            _lastTime = null;
            unawaited(_ticker.start());
            setState(() => _cursor = SystemMouseCursors.allScroll);
          },
          onPointerMove: (event) {
            if (_ticker.isActive) {
              _lastOffset = event.position;
            }
          },
          onPointerUp: (event) {
            if (_ticker.isActive) {
              _ticker.stop();
              _lastTime = null;
              _event = null;
              _lastOffset = null;
              setState(() => _cursor = null);
            }
          },
          child: widget.child,
        ),
        if (_cursor != null)
          Position.fill(
            child: MouseRegion(
              cursor: _cursor!,
              hitTestBehavior: .translucent,
            ),
          ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreScrollViewInterceptorStyle] patch into
/// [ScrollViewInterceptor.scrollViewInterceptorStyle] without
/// hand-reconstructing every field. Mirrors the Web
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
