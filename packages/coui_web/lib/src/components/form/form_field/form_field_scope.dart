import 'package:coui_core/coui_core.dart' show CoreFormFieldScope;
import 'package:jaspr/jaspr.dart';

/// Ambient scope for [CoreFormFieldScope].
///
/// Mirrors `FormFieldHandleScope` / `CouiLocalizationsScope` 1:1: pure
/// metadata, no DOM of its own — a wrapped `TextField` (or any other
/// form input) reads the value via [FormFieldScope.maybeOf].
class FormFieldScope extends InheritedComponent {
  /// Creates a scope exposing [scope] to [child].
  const FormFieldScope({
    required this.scope,
    required super.child,
    super.key,
  });

  /// The scope value shared with descendants.
  final CoreFormFieldScope scope;

  /// Returns the nearest [CoreFormFieldScope] above [context], or null.
  static CoreFormFieldScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<FormFieldScope>()
        ?.scope;
  }

  @override
  bool updateShouldNotify(covariant FormFieldScope oldComponent) {
    return scope != oldComponent.scope;
  }
}
