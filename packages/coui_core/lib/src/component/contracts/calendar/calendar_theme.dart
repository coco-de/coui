/// Theme data for `Calendar` customisation.
library;

import 'package:coui_core/src/component/contracts/calendar/calendar_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Calendar`.
///
/// Holds the project [style] applied to every `Calendar` whose
/// widget-level `calendarStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreCalendarTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance calendarStyle
/// ```
@immutable
class CoreCalendarTheme {
  /// Creates a [CoreCalendarTheme].
  const CoreCalendarTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreCalendarStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
