/// Conditional barrel that selects the SSR stub or the web implementation
/// of [OverlayPositioner] based on the presence of `dart:js_interop`.
library;

export 'overlay_positioner_stub.dart'
    if (dart.library.js_interop) 'overlay_positioner_web.dart';
