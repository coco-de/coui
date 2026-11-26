/// Conditional-export barrel for `CoUIWeb` runtime DOM helpers.
///
/// SSR / non-`dart:js_interop` builds get the inert
/// [coui_web_dom_stub.dart]; browser builds get
/// [coui_web_dom_web.dart] which talks to `package:web` directly.
library;

export 'coui_web_dom_stub.dart'
    if (dart.library.js_interop) 'coui_web_dom_web.dart';
