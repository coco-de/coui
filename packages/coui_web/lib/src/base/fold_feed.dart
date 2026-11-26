/// Conditional barrel selecting the SSR stub or the browser implementation of
/// `WebFoldFeed`.
///
/// Keeps every `package:web` / DOM import isolated to `fold_feed_web.dart` so
/// the app root stays SSR-safe.
library;

export 'fold_feed_stub.dart' if (dart.library.js_interop) 'fold_feed_web.dart';
