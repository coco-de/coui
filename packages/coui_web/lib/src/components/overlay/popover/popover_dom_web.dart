/// Web implementation of `Popover` DOM helpers.
///
/// Selected via the conditional export in `popover_dom.dart` for
/// browser builds — kept out of the main `co_popover.dart` so SSR /
/// non-web targets do not pull in `package:web` / `dart:js_interop`.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Registers a document-level `click` listener that reports whether
/// the click landed inside any of the elements identified by
/// [containerIds] — using DOM `Element.contains(target)` directly so
/// we don't depend on the click target (or any of its ancestors)
/// having its own `id` attribute. Mirrors the React `Popover`
/// outside-click pattern.
///
/// [onOutsideClick] is invoked only when the click target is **not**
/// contained by any of the registered containers (i.e. a true
/// outside-tap). Containers are looked up by id on every click so
/// the popover can register / unregister scope + panel ids without
/// rebuilding the listener.
void Function() registerDocumentClickListener(
  void Function() onOutsideClick, {
  required List<String> Function() containerIds,
}) {
  return registerDocumentOutsidePointerListener(
    onOutsideClick,
    containerIds: containerIds,
    eventType: 'click',
  );
}

/// Registers a document-level listener for [eventType] (e.g. `click`,
/// `pointerdown`, `pointerup`) that invokes [onOutside] only when the
/// event target is **not** contained by any element whose `id` matches
/// one returned by [containerIds]. Returns a disposer.
///
/// Shared outside-pointer primitive: `Popover` keys it to `click`
/// for outside-dismiss; `TextField` keys it to `pointerdown` /
/// `pointerup` for Flutter `onTapOutside` / `onTapUpOutside` parity.
void Function() registerDocumentOutsidePointerListener(
  void Function() onOutside, {
  required List<String> Function() containerIds,
  required String eventType,
}) {
  final handler = ((web.Event event) {
    // `composedPath()` captures the DOM ancestry **at the time the
    // event was dispatched**. Plain `event.target` + `contains` can
    // miss the path when intermediate state changes (jaspr's
    // microtask-based portal re-mount triggered by an in-flight
    // setState) detach the original target from the live document
    // before the document-level listener fires. The composed path
    // survives that race because the event itself stores the ancestor
    // chain. We scan the path for any element whose `id` matches one
    // of the registered container ids.
    final ids = containerIds();
    if (ids.isEmpty) {
      onOutside();
      return;
    }
    final path = event.composedPath();
    final idSet = ids.toSet();
    for (var i = 0; i < path.length; i++) {
      final node = path[i];
      if (!node.isA<web.Element>()) continue;
      final el = node as web.Element;
      if (idSet.contains(el.id)) {
        return;
      }
    }
    onOutside();
  }).toJS;
  web.document.addEventListener(eventType, handler);
  return () => web.document.removeEventListener(eventType, handler);
}

/// Registers a document-level `keydown` listener that forwards the
/// `KeyboardEvent.key` value to [onKey]. Returns a disposer.
void Function() registerDocumentKeydownListener(
  void Function(String key) onKey,
) {
  final handler = ((web.Event event) {
    if (!event.isA<web.KeyboardEvent>()) return;
    final key = (event as web.KeyboardEvent).key;
    onKey(key);
  }).toJS;
  web.document.addEventListener('keydown', handler);
  return () => web.document.removeEventListener('keydown', handler);
}

/// Registers a document-level `keydown` listener that forwards the
/// full key + modifier state to [onKeydown]. Returns a disposer.
///
/// Unlike [registerDocumentKeydownListener] (bare `key` only — used
/// for Escape-to-close), this exposes `metaKey` / `ctrlKey` so
/// callers can recognize platform shortcuts (`Cmd+K` / `Ctrl+K`)
/// without mis-firing on a plain `k` keystroke inside a text field.
/// `preventDefault` is forwarded rather than the raw event so the
/// SSR-safe boundary this file exists for isn't crossed — a caller
/// that needs to suppress the browser's own shortcut (e.g. some
/// browsers bind `Cmd+K` to the address bar) calls it explicitly.
void Function() registerDocumentShortcutListener(
  void Function({
    required String key,
    required bool metaKey,
    required bool ctrlKey,
    required void Function() preventDefault,
  })
  onKeydown,
) {
  final handler = ((web.Event event) {
    if (!event.isA<web.KeyboardEvent>()) return;
    final keyboardEvent = event as web.KeyboardEvent;
    onKeydown(
      key: keyboardEvent.key,
      metaKey: keyboardEvent.metaKey,
      ctrlKey: keyboardEvent.ctrlKey,
      // Wrapped in a closure rather than torn off directly — DDC
      // rejects a direct tear-off of a JS-interop extension type
      // instance method ("Declare a closure that calls this member
      // instead").
      preventDefault: () => keyboardEvent.preventDefault(),
    );
  }).toJS;
  web.document.addEventListener('keydown', handler);
  return () => web.document.removeEventListener('keydown', handler);
}

/// Registers `window` `resize` + `scroll` listeners that both call
/// [onChange]. Used by the popover to reposition its panel when the
/// viewport reflows or the page scrolls. Returns a disposer.
void Function() registerWindowResizeScrollListener(
  void Function() onChange,
) {
  final handler = ((web.Event _) => onChange()).toJS;
  web.window.addEventListener('resize', handler);
  web.window.addEventListener('scroll', handler, true.toJS);
  return () {
    web.window.removeEventListener('resize', handler);
    web.window.removeEventListener('scroll', handler, true.toJS);
  };
}

/// Schedules [callback] for the next browser animation frame via
/// `window.requestAnimationFrame`. Used to defer DOM-class swaps so
/// CSS `transition` declarations register the previous frame's
/// classes as the start state and animate the swap rather than
/// committing both classes within the same paint.
void scheduleNextFrame(void Function() callback) {
  final handler = ((double _) => callback()).toJS;
  // The frame id from rAF is intentionally discarded — popover
  // open/close transitions don't need cancellation; the timer-based
  // exit teardown in `_handleClose` covers state cleanup.
  final _ = web.window.requestAnimationFrame(handler);
}

/// Subscribes to layout-size changes of the element with [elementId]
/// via the native `ResizeObserver` API. Calls [onResize] (without
/// payload) on every reported change. Returns a disposer, or null if
/// the element isn't yet attached.
void Function()? observeElementResize(
  String elementId,
  void Function() onResize,
) {
  final el = web.document.getElementById(elementId);
  if (el == null) return null;
  final observer = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver __) {
      onResize();
    }).toJS,
  )..observe(el);
  // Tear-offs of `package:web` extension members aren't supported by
  // DDC — wrap in an explicit closure so the disposer call site is
  // compiled as a normal method invocation.
  return () => observer.disconnect();
}
