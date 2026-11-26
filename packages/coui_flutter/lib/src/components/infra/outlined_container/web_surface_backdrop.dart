/// Flutter Web's browser-composited alternative to ImageFilter.shader.
library;

export 'web_surface_backdrop_stub.dart'
    if (dart.library.js_interop) 'web_surface_backdrop_html.dart';
