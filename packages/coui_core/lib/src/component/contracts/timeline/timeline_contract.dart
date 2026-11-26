/// Platform-independent contract for unified timeline components.
///
/// Defines the interface that all Timeline implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/timeline/timeline_style.dart';

/// Platform-independent data for a timeline item.
class CoreTimelineItem {
  /// Creates a [CoreTimelineItem].
  const CoreTimelineItem({
    required this.title,
    this.description,
    this.timestamp,
  });

  /// Item title text.
  final String title;

  /// Optional description text.
  final String? description;

  /// Optional timestamp text.
  final String? timestamp;
}

/// Contract for a unified timeline component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [timelineStyle] field — see [CoreTimelineStyle].
abstract interface class CoreTimelineContract {
  /// Timeline items to display.
  List<CoreTimelineItem> get items;

  /// Per-instance timeline chrome / dimensional / slot style.
  ///
  /// Use `timelineStyle: CoreTimelineStyle(spacing: ...)` for the
  /// column-spacing override that used to live on the flat `spacing`
  /// param (Story #1362 Batch 3 — Epic #1302 chrome cleanup).
  CoreTimelineStyle? get timelineStyle;
}
