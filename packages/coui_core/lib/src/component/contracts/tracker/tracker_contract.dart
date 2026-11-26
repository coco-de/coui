/// Platform-independent contract for unified tracker components.
///
/// Defines the interface that all Tracker implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/tracker/tracker_style.dart';

/// Status level for tracker segments.
enum CoreTrackerStatus {
  /// Green - healthy/good state.
  fine,

  /// Orange - cautionary state.
  warning,

  /// Red - urgent/critical state.
  critical,

  /// Gray - unknown/undefined state.
  unknown,
}

/// Platform-independent data for a tracker segment.
class CoreTrackerSegment {
  /// Creates a [CoreTrackerSegment].
  const CoreTrackerSegment({
    required this.status,
    this.tooltip,
  });

  /// Status level determining visual appearance.
  final CoreTrackerStatus status;

  /// Optional tooltip text shown on hover.
  final String? tooltip;
}

/// Contract for a unified tracker component.
///
/// Displays a row of color-coded segments representing status data.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [trackerStyle] slot. Behavioural fields (`segments`,
/// `rounded`) stay flat.
abstract interface class CoreTrackerContract {
  /// Tracker segment data points.
  List<CoreTrackerSegment> get segments;

  /// Whether to apply rounded corners on the outer ends of the row.
  bool get rounded;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreTrackerStyle.defaultX /
  ///   defaultsByStatus[status])
  ///   → CoreTrackerTheme.style
  ///   → parent component slot override
  ///   → widget.trackerStyle
  /// ```
  CoreTrackerStyle? get trackerStyle;
}
