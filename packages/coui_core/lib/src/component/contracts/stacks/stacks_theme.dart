import 'package:coui_core/src/component/contracts/stacks/stacks_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Stacks`.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all chrome lives on [CoreStacksStyle], the theme just
/// exposes a single slot.
@immutable
class CoreStacksTheme {
  /// Creates a [CoreStacksTheme].
  const CoreStacksTheme({this.style});

  /// Style overrides applied to every `Stacks` rendered under this
  /// theme.
  final CoreStacksStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStacksTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
