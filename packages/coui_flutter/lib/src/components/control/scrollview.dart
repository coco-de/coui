import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:coui_flutter/coui_flutter.dart';

// This helps to simulate middle hold scroll on web and desktop platforms
class ScrollViewInterceptor extends StatefulWidget {
  const ScrollViewInterceptor({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;

  final bool enabled;

  @override
  State<ScrollViewInterceptor> createState() => _ScrollViewInterceptorState();
}

const kScrollDragSpeed = 0.02;
const kMaxScrollSpeed = 10;

class DesktopPointerScrollEvent extends PointerScrollEvent {
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

class _ScrollViewInterceptorState extends State<ScrollViewInterceptor>
    with SingleTickerProviderStateMixin {
  Ticker _ticker;

  Duration? _lastTime;

  PointerDownEvent? _event;
  Offset? _lastOffset;
  MouseCursor? _cursor;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    final delta = _lastTime == null ? Duration.zero : elapsed - _lastTime!;
    _lastTime = elapsed;
    if (delta.inMilliseconds == 0) return;
    final positionDelta = _event!.position - _lastOffset!;
    double incX =
        pow(-positionDelta.dx * kScrollDragSpeed, 3) / delta.inMilliseconds;
    double incY =
        pow(-positionDelta.dy * kScrollDragSpeed, 3) / delta.inMilliseconds;
    incX = incX.clamp(-kMaxScrollSpeed, kMaxScrollSpeed);
    incY = incY.clamp(-kMaxScrollSpeed, kMaxScrollSpeed);
    final instance = GestureBinding.instance;
    final result = HitTestResult();
    instance.hitTestInView(result, _event!.position, _event!.viewId);
    final pointerScrollEvent = DesktopPointerScrollEvent(
      device: _event!.device,
      embedderId: _event!.embedderId,
      kind: _event!.kind,
      position: _event!.position,
      scrollDelta: Offset(incX, incY),
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      viewId: _event!.viewId,
    );
    for (final path in result.path) {
      try {
        path.target.handleEvent(pointerScrollEvent, path);
      } catch (e, s) {
        FlutterError.reportError(
          FlutterErrorDetails(
            context: ErrorDescription(
              'while dispatching a pointer scroll event',
            ),
            exception: e,
            library: 'coui_flutter',
            stack: s,
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

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Listener(
          onPointerDown: (event) {
            /// Check if middle button is pressed.
            if (event.buttons != 4 || _ticker.isActive) return;
            _event = event;
            _lastOffset = event.position;
            _lastTime = null;
            _ticker.start();
            setState(() {
              _cursor = SystemMouseCursors.allScroll;
            });
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
              setState(() {
                _cursor = null;
              });
            }
          },
          child: widget.child,
        ),
        if (_cursor != null)
          Positioned.fill(
            child: MouseRegion(
              cursor: _cursor!,
              hitTestBehavior: HitTestBehavior.translucent,
            ),
          ),
      ],
    );
  }
}
