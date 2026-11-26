/// Theme data for `DatePicker` / `DateRangePicker` customisation.
library;

import 'package:coui_core/src/component/contracts/date_picker/date_picker_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `DatePicker` /
/// `DateRangePicker`.
///
/// Holds the project [style] applied to every date picker whose
/// widget-level `datePickerStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDatePickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance datePickerStyle
/// ```
///
/// ### Type parameters
///
/// Mirrors [CoreDatePickerStyle]:
///   - `Clr` — colour type (Flutter `Color`, Web `String`).
///   - `Shadow` — shadow type
///     (Flutter `List<BoxShadow>`, Web `String`).
@immutable
class CoreDatePickerTheme {
  /// Creates a [CoreDatePickerTheme].
  const CoreDatePickerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreDatePickerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDatePickerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
