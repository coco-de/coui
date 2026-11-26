/// Conditional barrel for the hero entrance's viewport observer.
///
/// SSR and any build without `dart:js_interop` get the inert stub.
/// Browser builds get `hero_appear_dom_web.dart`, which is the only
/// file here allowed to import `package:web`.
library;

export 'hero_appear_dom_stub.dart'
    if (dart.library.js_interop) 'hero_appear_dom_web.dart';
