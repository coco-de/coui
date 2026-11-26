/// Project-level theme overrides for tracker components.
///
/// All visual chrome flows through the single `style` slot — see
/// `CoreTrackerStyle` for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreTrackerStyle.defaultX /
///   defaultsByStatus[status])
///   → CoreTrackerTheme.style                         // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance trackerStyle
/// ```
library;

import 'package:coui_core/src/component/contracts/tracker/tracker_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `Tracker`.
@immutable
class CoreTrackerTheme {
  /// Creates a [CoreTrackerTheme].
  const CoreTrackerTheme({this.style});

  /// Project-wide composite style applied to every `Tracker`.
  ///
  /// Resolved before any per-instance `widget.trackerStyle`.
  final CoreTrackerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTrackerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
