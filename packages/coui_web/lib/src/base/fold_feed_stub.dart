/// Server stand-in for `WebFoldFeed` — selected by the conditional export in
/// `fold_feed.dart` where there is no browser. There is nothing to read, so
/// [WebFoldFeed.start] returns null and the viewport stays unmeasured.
library;

import 'package:coui_core/coui_core.dart';

/// Reads the folds the browser reports. Never started on the server.
final class WebFoldFeed {
  WebFoldFeed._();

  /// Returns null: a server has no viewport.
  static WebFoldFeed? start({
    required void Function(CoreFoldLayout layout) onChange,
  }) => null;

  /// The folds as the browser reports them now.
  CoreFoldLayout get current => CoreFoldLayout.unmeasured;

  /// Unmeasured: a server has no viewport to read.
  static CoreFoldLayout read() => CoreFoldLayout.unmeasured;

  /// Stops listening.
  void dispose() {}
}
