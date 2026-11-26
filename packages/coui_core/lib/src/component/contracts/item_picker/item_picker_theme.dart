/// Theme data for `ItemPicker` customisation.
library;

import 'package:coui_core/src/component/contracts/item_picker/item_picker_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ItemPicker`.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreItemPickerStyle] for the merge
/// chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreItemPickerTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance itemPickerStyle
/// ```
@immutable
class CoreItemPickerTheme {
  /// Creates a [CoreItemPickerTheme].
  const CoreItemPickerTheme({this.style});

  /// Project-wide composite style applied to every `ItemPicker`.
  final CoreItemPickerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreItemPickerTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}
