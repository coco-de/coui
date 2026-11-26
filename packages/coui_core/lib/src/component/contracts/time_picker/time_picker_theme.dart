/// Theme data for `TimePicker` customisation.
library;

import 'package:coui_core/src/component/contracts/time_picker/time_picker_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `TimePicker`.
///
/// Holds the project [style] applied to every time picker whose
/// widget-level `timePickerStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTimePickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance timePickerStyle
/// ```
///
/// ### Type parameters
///
/// Mirrors [CoreTimePickerStyle]:
///   - `Clr` — colour type (Flutter `Color`, Web `String`).
///   - `Shadow` — shadow type
///     (Flutter `List<BoxShadow>`, Web `String`).
@immutable
class CoreTimePickerTheme {
  /// Creates a [CoreTimePickerTheme].
  const CoreTimePickerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreTimePickerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTimePickerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
