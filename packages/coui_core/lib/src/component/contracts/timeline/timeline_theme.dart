import 'package:coui_core/src/component/contracts/timeline/timeline_style.dart';
import 'package:meta/meta.dart';

/// Timeline component theme overrides.
///
/// Per Epic #1302 / #1370 all 시각 chrome flows through the single
/// [style] slot — see [CoreTimelineStyle].
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTimelineTheme.style
///   → parent component slot override
///   → widget per-instance timelineStyle
/// ```
@immutable
class CoreTimelineTheme {
  /// Creates a [CoreTimelineTheme].
  const CoreTimelineTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreTimelineStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTimelineTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
