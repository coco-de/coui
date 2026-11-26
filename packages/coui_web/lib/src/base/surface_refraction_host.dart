/// Conditional barrel selecting the SSR stub or the web implementation of
/// [SurfaceRefractionHost].
///
/// Keeps every `package:web` / DOM import isolated to
/// [surface_refraction_host_web.dart] so the app root stays SSR-safe.
library;

export 'surface_refraction_host_stub.dart'
    if (dart.library.js_interop) 'surface_refraction_host_web.dart';
