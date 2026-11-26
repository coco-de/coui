import 'package:coui_core/src/component/contracts/switch_field/switch_field_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for switch field components.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [style] field — see [CoreSwitchFieldStyle] for the merge
/// chain. There are no flat chrome fields: toggle size, gap, active /
/// inactive track colours and label / description text styles all live
/// inside [CoreSwitchFieldStyle].
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   switchField: CoreSwitchFieldTheme(
///     style: CoreSwitchFieldStyle(
///       size: CoreComponentSize.lg,
///       gap: 16.0,
///     ),
///   ),
/// )
/// ```
@immutable
class CoreSwitchFieldTheme {
  /// Creates a [CoreSwitchFieldTheme].
  const CoreSwitchFieldTheme({this.style});

  /// Project-wide composite style applied to every `SwitchField`.
  ///
  /// Resolved before any per-instance `widget.switchFieldStyle`.
  final CoreSwitchFieldStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreSwitchFieldTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
