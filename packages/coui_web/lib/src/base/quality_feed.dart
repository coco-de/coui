/// Conditional barrel selecting the SSR stub or the browser implementation of
/// `WebQualityFeed`.
///
/// Keeps every `package:web` / DOM import isolated to `quality_feed_web.dart`
/// so the app root stays SSR-safe.
library;

export 'quality_feed_stub.dart'
    if (dart.library.js_interop) 'quality_feed_web.dart';
