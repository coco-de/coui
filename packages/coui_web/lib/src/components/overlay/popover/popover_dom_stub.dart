/// SSR-safe stub for `Popover` DOM helpers.
///
/// Server / non-`dart:js_interop` builds get inert no-ops so the
/// component compiles and renders its initial markup without any
/// `package:web` dependency. The real implementations live in
/// [popover_dom_web.dart].
library;

/// SSR stub — no DOM events. Returns an inert disposer.
void Function() registerDocumentClickListener(
  void Function() onOutsideClick, {
  required List<String> Function() containerIds,
}) => () {};

/// SSR stub — no DOM events. Returns an inert disposer.
void Function() registerDocumentOutsidePointerListener(
  void Function() onOutside, {
  required List<String> Function() containerIds,
  required String eventType,
}) => () {};

/// SSR stub — no DOM events. Returns an inert disposer.
void Function() registerDocumentKeydownListener(
  void Function(String key) onKey,
) => () {};

/// SSR stub — no DOM events. Returns an inert disposer.
void Function() registerDocumentShortcutListener(
  void Function({
    required String key,
    required bool metaKey,
    required bool ctrlKey,
    required void Function() preventDefault,
  })
  onKeydown,
) => () {};

/// SSR stub — no DOM events. Returns an inert disposer.
void Function() registerWindowResizeScrollListener(
  void Function() onChange,
) => () {};

/// SSR stub — no rAF on the server. Drops [callback] (the popover
/// state never reaches the rAF-dependent open transition step
/// outside the browser anyway).
void scheduleNextFrame(void Function() callback) {}

/// SSR stub — no `ResizeObserver`. Returns null because the element
/// can't be observed without a DOM.
void Function()? observeElementResize(
  String elementId,
  void Function() onResize,
) => null;
