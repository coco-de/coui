/// Conditional barrel that selects the SSR stub or the web implementation
/// of [FadeScrollMeasurer] based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// [fade_scroll_measurer_web.dart] so [co_fade_scroll.dart] stays SSR-safe
/// and free of direct DOM dependencies.
library;

export 'fade_scroll_measurer_stub.dart'
    if (dart.library.js_interop) 'fade_scroll_measurer_web.dart';
