import 'package:coui_flutter/coui_flutter.dart';

/// Ambient scope for [CoreFormFieldScope] — the disabled / error
/// constraint a `FormField` or `Fieldset` publishes to the input it
/// wraps.
///
/// Mirrors the Web `FormFieldScope` (`InheritedComponent`) 1:1: a plain
/// [InheritedWidget], pure metadata, no widget of its own. A descendant
/// that reads [maybeOf] inside `build()` / `didChangeDependencies()`
/// rebuilds whenever the published [scope] changes.
///
/// Deliberately NOT a `Data<T>`, even though `FormField` carries its
/// `FormFieldHandle` that way. The kit's overlays (popover, dialog,
/// toast) copy every `Data<T>` between the trigger and the overlay root
/// into the overlay with `Data.capture`, so a `Data`-based scope would
/// follow a dialog or popover opened from inside a disabled `Fieldset`
/// or an erroring `FormField` — every input in that overlay would come
/// up read-only or in the error tone, though none of them is the input
/// the wrapper wraps. An overlay's content is not a child of the
/// wrapper, and on Web it is not either: the portal mounts it under the
/// overlay host, outside the scope. A plain [InheritedWidget] is not
/// captured, so both platforms stop the scope at the overlay boundary.
class FormFieldScope extends InheritedWidget {
  /// Creates a [FormFieldScope] exposing [scope] to [child].
  const FormFieldScope({required this.scope, required super.child, super.key});

  /// The scope value shared with descendants.
  final CoreFormFieldScope scope;

  /// Returns the nearest [CoreFormFieldScope] above [context], or null.
  static CoreFormFieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormFieldScope>()?.scope;

  @override
  bool updateShouldNotify(FormFieldScope oldWidget) => scope != oldWidget.scope;
}
