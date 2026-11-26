/// Conditional barrel that selects the SSR stub or the web
/// implementation of `SubfocusScope`'s DOM helpers based on the
/// presence of `dart:js_interop`.
///
/// Keeps every `package:web` / `dart:js_interop` import isolated to
/// [subfocus_dom_web.dart] so [co_subfocus.dart] stays SSR-safe.
library;

export 'subfocus_dom_stub.dart'
    if (dart.library.js_interop) 'subfocus_dom_web.dart';
