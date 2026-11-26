/// Conditional barrel that selects the SSR stub or the web implementation
/// of `DrawerBodyMeasurer` based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// `drawer_body_measurer_web.dart` so `drawer.dart` stays SSR-safe.
library;

export 'drawer_body_measurer_stub.dart'
    if (dart.library.js_interop) 'drawer_body_measurer_web.dart';
