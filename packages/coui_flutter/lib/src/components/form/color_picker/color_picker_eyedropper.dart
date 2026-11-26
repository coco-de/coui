/// Conditional-export barrel for the Flutter `ColorPicker`'s
/// browser-native EyeDropper helper.
///
/// Mirrors the Web implementation in
/// `packages/coui_web/lib/src/components/form/color_picker/`
/// `color_picker_dom_*.dart` — Flutter Web reaches the same
/// `window.EyeDropper` API via `package:web` while non-browser
/// targets (mobile, desktop, tests) get inert no-ops so the picker
/// compiles and renders without pulling in `dart:js_interop`.
library;

export 'color_picker_eyedropper_stub.dart'
    if (dart.library.js_interop) 'color_picker_eyedropper_web.dart';
