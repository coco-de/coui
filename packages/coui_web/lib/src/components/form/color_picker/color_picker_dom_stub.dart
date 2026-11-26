/// SSR-safe stub for `ColorPicker` DOM helpers.
///
/// Server / non-`dart:js_interop` builds get inert no-ops so the
/// component compiles and renders its initial markup without any
/// `package:web` dependency. The real implementations live in
/// [color_picker_dom_web.dart].
library;

/// Reads `target.value` from an `<input>` event target.
String? readInputValue(Object? target) => null;

/// SSR stub — no DOM, no rect math.
({double x, double y})? readMouseEventLocalRatio(
  Object event,
  String elementId,
) => null;

/// SSR stub — no DOM events.
bool isMouseEventDragging(Object event) => false;

/// Returns whether the host browser supports the `EyeDropper` API.
bool get isEyeDropperSupported => false;

/// Opens the browser's native EyeDropper picker, returning the picked
/// `#RRGGBB` hex string (or `null` if the user cancelled / the API is
/// unavailable).
///
/// Returns a [Future] for signature parity with the web implementation;
/// SSR target resolves immediately to `null`.
Future<String?> pickColorWithEyeDropper() => .value();
