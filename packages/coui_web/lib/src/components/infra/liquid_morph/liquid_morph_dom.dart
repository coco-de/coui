/// Conditional barrel selecting the SSR stub or the web implementation of
/// [LiquidMorphRuntime].
///
/// Keeps every `package:web` / DOM import isolated to
/// [liquid_morph_dom_web.dart] so `liquid_morph_clip.dart` stays SSR-safe.
library;

export 'liquid_morph_dom_stub.dart'
    if (dart.library.js_interop) 'liquid_morph_dom_web.dart';
