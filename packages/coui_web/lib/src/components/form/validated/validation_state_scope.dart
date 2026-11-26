import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Ambient validation-state scope installed by `Validated` around its
/// wrapped field.
///
/// A descendant input (e.g. `TextField`) reads the nearest state via
/// [maybeOf] and applies its own error variant — the field's single
/// border + focus ring switch to the error tone instead of a second
/// ring stacking around the field (the Web counterpart to Flutter's
/// `Data<CoreValidationState>.inherit`).
class ValidationStateScope extends InheritedComponent {
  /// Creates a [ValidationStateScope] exposing [state] to [child].
  const ValidationStateScope({
    required this.state,
    required super.child,
    super.key,
  });

  /// The validation state shared with the wrapped field.
  final CoreValidationState state;

  /// Returns the nearest [CoreValidationState] above [context], or null.
  static CoreValidationState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<ValidationStateScope>()
        ?.state;
  }

  @override
  bool updateShouldNotify(ValidationStateScope oldComponent) {
    return state != oldComponent.state;
  }
}
