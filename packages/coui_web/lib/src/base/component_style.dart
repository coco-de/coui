import 'package:coui_web/src/base/base_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Base class for component-specific utility classes (e.g., `ButtonModifier`).
///
/// These utilities are typically defined within a specific component's file and
/// provide strongly-typed modifiers unique to that component. They extend
/// [BaseStyle] to inherit its fluent API for applying [PrefixModifier]s
/// and to be compatible with systems expecting a [Styling].
///
/// Type parameter:
///   `T`: The concrete type of the component-specific utility itself,
///        ensuring methods like `on()` and `at()` return the correct
///        specific type.
abstract class ComponentStyle<T extends ComponentStyle<T>>
    extends BaseStyle<T> {
  /// Constructs a [ComponentStyle].
  ///
  /// [cssClass]: The core CSS class string (e.g., "btn-primary").
  /// [type]: The [StyleType] categorizing this utility.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied.
  const ComponentStyle(super.cssClass, {super.modifiers, required super.type});

  // Concrete subclasses must implement `create(...)`.
}
