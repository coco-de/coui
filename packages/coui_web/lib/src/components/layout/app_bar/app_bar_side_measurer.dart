/// Conditional barrel that selects the SSR stub or the web implementation
/// of `AppBarSideMeasurer` based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// `app_bar_side_measurer_web.dart` so `app_bar.dart` stays SSR-safe.
library;

export 'app_bar_side_measurer_stub.dart'
    if (dart.library.js_interop) 'app_bar_side_measurer_web.dart';
