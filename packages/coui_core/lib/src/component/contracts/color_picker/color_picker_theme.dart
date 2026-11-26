/// Theme data for `ColorPicker` customisation.
library;

import 'package:coui_core/src/component/contracts/color_picker/color_picker_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ColorPicker`.
///
/// Holds the project [style] applied to every color picker whose
/// widget-level `colorPickerStyle` is null.
///
/// The picker has no visual variant fork, so this theme carries the
/// single [style] slot only — there is no `variantStyles` map.
///
/// Behaviour defaults (showAlpha / showLabel / showHexInput /
/// pickerMode / enableEyeDropper / promptMode) live on
/// `CoreColorPickerContract` as `static const` single-source defaults
/// (the widget reads `widget.X ?? CoreColorPickerContract.defaultX`),
/// not on this theme — a theme carries chrome via [style] only
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreColorPickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance colorPickerStyle
/// ```
@immutable
class CoreColorPickerTheme {
  /// Creates a [CoreColorPickerTheme].
  const CoreColorPickerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreColorPickerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreColorPickerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
