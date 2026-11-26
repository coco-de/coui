import 'package:coui_core/src/component/contracts/hover/hover_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for hover components.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all chrome and behaviour timing fields live on
/// [CoreHoverStyle], the theme just exposes a single slot.
@immutable
class CoreHoverTheme {
  /// Creates a [CoreHoverTheme].
  const CoreHoverTheme({this.style});

  /// Style overrides applied to every `Hover` rendered under this
  /// theme.
  final CoreHoverStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHoverTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
