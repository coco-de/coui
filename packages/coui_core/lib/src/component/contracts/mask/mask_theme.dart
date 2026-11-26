/// Theme overrides for the unified Mask component.
library;

import 'package:coui_core/src/component/contracts/mask/mask_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for mask components.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all chrome lives on [CoreMaskStyle], the theme just exposes
/// a single slot.
@immutable
class CoreMaskTheme {
  /// Creates a [CoreMaskTheme].
  const CoreMaskTheme({this.style});

  /// Style overrides applied to every `Mask` rendered under this
  /// theme.
  final CoreMaskStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMaskTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
