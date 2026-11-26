/// SSR-safe DOM access for the landing's theme controls.
///
/// The same split as `chain_code_dom.dart`: the server build gets inert
/// stubs and only the browser build reaches `package:web`.
library;

export 'site_theme_dom_stub.dart' if (dart.library.js_interop) 'site_theme_dom_web.dart';
