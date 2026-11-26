import 'package:coui_core/src/component/contracts/stepper/stepper_style.dart';
import 'package:meta/meta.dart';

/// Stepper component theme overrides.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreStepperStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreStepperTheme.style
///   → parent component slot override
///   → widget per-instance stepperStyle
/// ```
@immutable
class CoreStepperTheme {
  /// Creates a [CoreStepperTheme].
  const CoreStepperTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreStepperStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepperTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
