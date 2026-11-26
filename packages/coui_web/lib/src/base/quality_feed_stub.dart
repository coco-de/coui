/// SSR stub for [WebQualityFeed].
///
/// The server measures nothing: there is no display to refresh and no frame to
/// time, and a tier the markup should carry is written by the app root from
/// what the app stated (`forced`, `initialQuality`), not learned.
library;

import 'package:coui_core/coui_core.dart';

/// Stub implementation used during SSR.
final class WebQualityFeed {
  WebQualityFeed._();

  /// No feed on the server.
  static WebQualityFeed? start({
    required CoreAdaptiveQuality stated,
    required void Function(CoreQualityChange change) onChange,
  }) => null;

  /// Holds nothing; there is nothing measuring.
  CoreQualityHold hold() => CoreQualityHold.none();

  /// Nothing to stop.
  void dispose() {}
}
