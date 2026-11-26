import 'package:coui_core/src/component/contracts/mockup/mockup_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for the shared mockup chrome.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all chrome lives on [CoreMockupStyle], the theme just
/// exposes a single slot.
///
/// Shared theme for all mockup variants (Browser, Device, Code).
/// Each variant additionally exposes its own
/// `CoreMockupXxxTheme.style` slot for variant-specific overrides; this
/// shared slot lets a project recolour every mockup frame at once.
@immutable
class CoreMockupTheme {
  /// Creates a [CoreMockupTheme].
  const CoreMockupTheme({this.style});

  /// Style overrides applied to every `Mockup*` rendered under this
  /// theme.
  final CoreMockupStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
