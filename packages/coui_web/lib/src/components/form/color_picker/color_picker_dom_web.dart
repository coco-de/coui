/// Web implementation of `ColorPicker` DOM helpers.
///
/// Selected via the conditional export in `color_picker_dom.dart` for
/// browser builds — kept out of the main `co_color_picker.dart` so
/// SSR / non-web targets do not pull in `package:web` /
/// `dart:js_interop_unsafe`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Reads `target.value` from an `<input>` event target.
String? readInputValue(Object? target) {
  if (target is web.HTMLInputElement) return target.value;
  return null;
}

/// Local cursor position inside the event's `currentTarget` rect,
/// expressed as 0..1 ratios on each axis. Returns `null` if [event]
/// isn't a `MouseEvent`, the target isn't an attached `Element`, or
/// the rect has zero size.
///
/// Centralises the `MouseEvent` / `Element` extension-type narrowing
/// that the picker's HSV area + hue slider need — keeping the
/// `package:web` interop confined to one place so the picker's
/// renderer stays free of `is web.MouseEvent` / `as web.HTMLElement`
/// noise.
({double x, double y})? readMouseEventLocalRatio(
  Object event,
  String elementId,
) {
  if (event is! web.MouseEvent) return null;
  final element = web.document.getElementById(elementId);
  if (element == null) return null;
  final rect = element.getBoundingClientRect();
  final w = rect.width;
  final h = rect.height;
  if (w <= 0 || h <= 0) return null;
  // Re-read the coordinates as doubles — browsers deliver sub-pixel
  // mouse positions and the `int`-declared `clientX`/`clientY` getters
  // throw a cast error on them.
  final clientX = event.getProperty<JSNumber>('clientX'.toJS).toDartDouble;
  final clientY = event.getProperty<JSNumber>('clientY'.toJS).toDartDouble;
  final x = ((clientX - rect.left) / w).clamp(0.0, 1.0);
  final y = ((clientY - rect.top) / h).clamp(0.0, 1.0);
  return (x: x, y: y);
}

/// Returns true if [event] is a `MouseEvent` with at least one button
/// currently pressed (drag in progress). Returns false for hover-only
/// `mousemove` events. Used to gate the picker's drag handlers.
bool isMouseEventDragging(Object event) {
  if (event is! web.MouseEvent) return false;
  return event.buttons != 0;
}

/// Returns whether the host browser supports the `EyeDropper` API
/// (Chromium 95+ — Firefox / Safari currently have no implementation).
bool get isEyeDropperSupported => web.window.has('EyeDropper');

/// Opens the browser's native EyeDropper picker, returning the picked
/// `#RRGGBB` hex string (or `null` if the user cancelled / the API is
/// unavailable).
Future<String?> pickColorWithEyeDropper() async {
  if (!web.window.has('EyeDropper')) return null;
  final ctor = web.window.getProperty<JSFunction>('EyeDropper'.toJS);
  final instance = ctor.callAsConstructor<JSObject>();
  final promise = instance.callMethod<JSPromise<JSObject>>('open'.toJS);
  try {
    final result = await promise.toDart;
    return result.getProperty<JSString?>('sRGBHex'.toJS)?.toDart;
  } catch (_) {
    // User cancelled (rejected promise) or API unavailable.
    return null;
  }
}
