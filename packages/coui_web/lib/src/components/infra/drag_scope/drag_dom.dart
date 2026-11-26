/// Conditional barrel that selects the SSR stub or the web implementation
/// of the drag engine's DOM helpers.
///
/// Keeps every `package:universal_web` import isolated to
/// [drag_dom_web.dart] so `drag_scope.dart`, `drag_item.dart` and
/// `drop_zone.dart` stay SSR-safe and free of direct DOM dependencies.
library;

export 'drag_dom_stub.dart' if (dart.library.js_interop) 'drag_dom_web.dart';
