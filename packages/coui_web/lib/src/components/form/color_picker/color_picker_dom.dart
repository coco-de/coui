/// Conditional barrel that selects the SSR stub or the web
/// implementation of `ColorPicker`'s DOM helpers based on the
/// presence of `dart:js_interop`.
///
/// Keeps every `package:web` / `dart:js_interop_unsafe` import isolated
/// to [color_picker_dom_web.dart] so [co_color_picker.dart] stays
/// SSR-safe and free of direct DOM dependencies.
library;

export 'color_picker_dom_stub.dart'
    if (dart.library.js_interop) 'color_picker_dom_web.dart';
