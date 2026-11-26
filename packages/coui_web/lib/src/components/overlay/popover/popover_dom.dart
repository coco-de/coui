/// Conditional barrel that selects the SSR stub or the web
/// implementation of `Popover`'s DOM helpers based on the presence
/// of `dart:js_interop`.
///
/// Keeps every `package:web` / `dart:js_interop` import isolated to
/// [popover_dom_web.dart] so [co_popover.dart] stays SSR-safe and
/// free of direct DOM dependencies.
library;

export 'popover_dom_stub.dart'
    if (dart.library.js_interop) 'popover_dom_web.dart';
