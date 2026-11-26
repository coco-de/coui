/// Conditional-export barrel for the browser half of the top-layer
/// promotion (see `top_layer.dart`).
///
/// SSR / non-`dart:js_interop` builds get the inert
/// `top_layer_dom_stub.dart`; browser builds get `top_layer_dom_web.dart`
/// which talks to `package:web` directly.
library;

export 'top_layer_dom_stub.dart'
    if (dart.library.js_interop) 'top_layer_dom_web.dart';
