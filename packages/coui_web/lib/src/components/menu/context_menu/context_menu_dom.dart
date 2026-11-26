/// Conditional barrel that selects the SSR stub or the web implementation of
/// the DOM reads and writes `ContextMenu` makes while a finger glides over its
/// rows and while its preview is placed.
///
/// Keeps every `package:web` import isolated to `context_menu_dom_web.dart` so
/// `context_menu.dart` stays SSR-safe.
library;

export 'context_menu_dom_stub.dart'
    if (dart.library.js_interop) 'context_menu_dom_web.dart';
