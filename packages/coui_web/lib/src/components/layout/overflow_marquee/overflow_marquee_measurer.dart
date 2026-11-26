/// Conditional barrel that selects the SSR stub or the web implementation
/// of [OverflowMarqueeMeasurer] based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// [overflow_marquee_measurer_web.dart] so [co_overflow_marquee.dart] stays
/// SSR-safe and free of direct DOM dependencies.
library;

export 'overflow_marquee_measurer_stub.dart'
    if (dart.library.js_interop) 'overflow_marquee_measurer_web.dart';
