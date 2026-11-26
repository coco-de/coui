/// Web implementation of the Flutter `ColorPicker`'s EyeDropper
/// helper. Mirrors the equivalent `coui_web` helper so Flutter Web
/// and pure-Web pickers reach the same `window.EyeDropper` API.
///
/// Selected via the conditional export in
/// `co_color_picker_eyedropper.dart` for browser builds — kept out
/// of the main `co_color_picker.dart` so non-web Flutter targets
/// (mobile, desktop, tests) don't pull in `package:web` /
/// `dart:js_interop`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Whether the host browser exposes the `EyeDropper` API
/// (Chromium 95+ — Firefox / Safari currently have no
/// implementation).
bool get isEyeDropperSupported => web.window.has('EyeDropper');

/// Opens the browser's native EyeDropper picker, returning the
/// picked `#RRGGBB` hex string (or `null` if the user cancelled /
/// the API is unavailable).
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
