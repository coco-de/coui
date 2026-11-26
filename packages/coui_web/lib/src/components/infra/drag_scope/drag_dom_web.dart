/// Web implementation of the drag engine's DOM helpers.
///
/// Selected via the conditional export in `drag_dom.dart` for browser
/// builds — kept out of the adapter widgets so they stay SSR-safe and free
/// of direct `package:web` / `dart:js_interop` dependencies.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// Reads a pointer event's viewport position as fractional CSS pixels.
///
/// `package:web` types `clientX` / `clientY` as `int`, but browsers report
/// sub-pixel values on high-DPI displays — reading them through the typed
/// getters throws at runtime. This view reads the same two properties as
/// the doubles they actually are.
extension type const _PointerClientPosition._(JSObject _) implements JSObject {
  external double get clientX;
  external double get clientY;
}

/// The viewport position of a pointer [event].
CoreDragPoint viewportPointOf(Object event) {
  final position = _PointerClientPosition._(event as JSObject);

  return CoreDragPoint(position.clientX, position.clientY);
}

/// Streams a live drag from the document until the pointer is released.
///
/// Listening on the document rather than capturing the pointer on the
/// grabbed element is deliberate: `setPointerCapture` **retargets** the
/// subsequent `pointerup` and `click` to the capturing element, so any
/// handler on an ancestor silently stops seeing them — a tap right after
/// a drag then does nothing. Document listeners keep the pointer stream
/// complete without moving anyone else's events.
///
/// Returns a disposer that removes every listener it installed.
void Function() registerDragPointerListeners({
  required void Function(CoreDragPoint position) onMove,
  required void Function() onUp,
  required void Function() onCancel,
}) {
  // Only pointer events reach this listener (it is registered for
  // `pointermove` alone), and `package:web` extension types carry no
  // runtime identity to narrow against — read the position directly.
  final moveHandler = ((web.Event event) {
    onMove(viewportPointOf(event));
  }).toJS;
  final upHandler = ((web.Event _) => onUp()).toJS;
  final cancelHandler = ((web.Event _) => onCancel()).toJS;

  web.document
    ..addEventListener('pointermove', moveHandler)
    ..addEventListener('pointerup', upHandler)
    ..addEventListener('pointercancel', cancelHandler);

  return () {
    web.document
      ..removeEventListener('pointermove', moveHandler)
      ..removeEventListener('pointerup', upHandler)
      ..removeEventListener('pointercancel', cancelHandler);
  };
}

/// Measures the element with [elementId] relative to the element with
/// [originId], so every participant in a scope shares one coordinate
/// space no matter where the scope sits on the page.
///
/// Returns null until both elements are attached.
CoreDragRect? measureRectWithin(String elementId, String originId) {
  final element = web.document.getElementById(elementId);
  final origin = web.document.getElementById(originId);
  if (element == null || origin == null) return null;

  final rect = element.getBoundingClientRect();
  final originRect = origin.getBoundingClientRect();

  return CoreDragRect(
    left: rect.left.toDouble() - originRect.left.toDouble(),
    top: rect.top.toDouble() - originRect.top.toDouble(),
    width: rect.width.toDouble(),
    height: rect.height.toDouble(),
  );
}

/// The viewport rect of the element with [elementId].
///
/// Pointer events arrive in viewport coordinates; this is what turns them
/// into scope coordinates without every caller reaching into the DOM.
CoreDragRect? measureViewportRect(String elementId) {
  final element = web.document.getElementById(elementId);
  if (element == null) return null;

  final rect = element.getBoundingClientRect();

  return CoreDragRect(
    left: rect.left.toDouble(),
    top: rect.top.toDouble(),
    width: rect.width.toDouble(),
    height: rect.height.toDouble(),
  );
}

/// The nearest ancestor of [elementId] that actually scrolls.
///
/// Returns null when nothing above it scrolls, which is how auto-scroll
/// stays inert on a page that has no scroll container to move.
web.Element? _scrollParentOf(String elementId) {
  var current = web.document.getElementById(elementId)?.parentElement;
  while (current != null) {
    final style = web.window.getComputedStyle(current);
    final overflow = '${style.overflowY} ${style.overflowX}';
    final scrolls = overflow.contains('auto') || overflow.contains('scroll');
    if (scrolls &&
        (current.scrollHeight > current.clientHeight ||
            current.scrollWidth > current.clientWidth)) {
      return current;
    }
    current = current.parentElement;
  }

  return null;
}

/// The viewport rect of the scroll container around [elementId].
///
/// The viewport — not the dragged content — is the edge band that matters:
/// a list taller than its window would otherwise only pull at its own far
/// ends, which the user can never reach.
CoreDragRect? scrollViewportRect(String elementId) {
  final parent = _scrollParentOf(elementId);
  if (parent == null) return null;

  final rect = parent.getBoundingClientRect();

  return CoreDragRect(
    left: rect.left.toDouble(),
    top: rect.top.toDouble(),
    width: rect.width.toDouble(),
    height: rect.height.toDouble(),
  );
}

/// Scrolls the container around [elementId], reporting what actually moved.
///
/// The applied delta differs from the requested one at the extremes, and
/// callers need the real number to keep a drag session in step with it.
CoreDragOffset scrollContainerBy(String elementId, CoreDragOffset delta) {
  final parent = _scrollParentOf(elementId);
  if (parent == null) return .zero;

  final beforeX = parent.scrollLeft;
  final beforeY = parent.scrollTop;
  parent
    ..scrollLeft = (beforeX + delta.x).round()
    ..scrollTop = (beforeY + delta.y).round();

  return CoreDragOffset(
    x: (parent.scrollLeft - beforeX).toDouble(),
    y: (parent.scrollTop - beforeY).toDouble(),
  );
}

/// Runs [onFrame] every animation frame until the returned disposer runs.
///
/// [onFrame] receives the time since the previous frame, so callers
/// integrate a velocity rather than assuming a fixed refresh rate.
void Function() registerFrameLoop(void Function(Duration delta) onFrame) {
  var running = true;
  var last = 0.0;

  void schedule() {
    // The request id is deliberately unused — the loop stops through the
    // `running` flag instead of `cancelAnimationFrame`.
    final _ = web.window.requestAnimationFrame(
      ((double timestamp) {
        if (!running) return;
        if (last != 0) {
          // rAF timestamps are fractional milliseconds.
          onFrame(
            Duration(
              microseconds:
                  ((timestamp - last) * Duration.microsecondsPerMillisecond)
                      .round(),
            ),
          );
        }
        last = timestamp;
        schedule();
      }).toJS,
    );
  }

  schedule();

  return () => running = false;
}

/// Reports layout-size changes of the element with [elementId].
///
/// Cached rects are what keep a drag smooth; this is how the adapter
/// learns they went stale. Returns a disposer, or null if the element
/// isn't attached yet.
void Function()? observeLayoutChanges(
  String elementId,
  void Function() onChange,
) {
  final element = web.document.getElementById(elementId);
  if (element == null) return null;

  final observer = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver __) {
      onChange();
    }).toJS,
  )..observe(element);

  // Tear-offs of `package:web` extension members aren't supported by DDC —
  // wrap in an explicit closure so the disposer compiles as a normal call.
  return () => observer.disconnect();
}
