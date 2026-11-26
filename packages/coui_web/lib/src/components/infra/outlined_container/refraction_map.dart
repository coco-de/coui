/// Conditional barrel selecting the SSR stub or the web implementation of
/// [SurfaceRefractionRuntime].
///
/// Keeps every `package:web` / DOM import isolated to
/// [refraction_map_web.dart] so `outlined_container.dart` stays SSR-safe.
/// The server must not emit a refraction at all — the displacement map is
/// generated from a measured element, and there is no element to measure
/// until the document exists.
library;

export 'refraction_map_stub.dart'
    if (dart.library.js_interop) 'refraction_map_web.dart';
