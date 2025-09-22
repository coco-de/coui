import 'package:coui_web/src/base/base_style.dart';
import 'package:coui_web/src/base/component_stylings.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Base class for groups of general utility classes (e.g., `Typography`,
/// `Spacing`, `Effects`).
///
/// These utilities represent common styling patterns applicable across
/// various components.
/// They extend [BaseStyle] to inherit its fluent API for applying
/// [PrefixModifier]s and implement multiple component-specific modifier
/// interfaces.
/// This allows instances of `UtilityGroup` subclasses to be
/// passed to the `modifiers` list of any component that expects its
/// corresponding modifier interface, enabling a flexible and type-safe
/// styling mechanism.
///
/// Type parameter:
///   `T`: The concrete type of the utility group itself (e.g., `Typography`
///        for typography utilities), ensuring methods like `on()` and `at()`
///        return the correct specific type.
abstract class CommonStyle<T extends CommonStyle<T>> extends BaseStyle<T>
    implements AllComponentStylings {
  /// Constructs a [CommonStyle].
  ///
  /// [cssClass]: The core CSS class string (e.g., "text-lg", "mt-4").
  /// [type]: The [StyleType] categorizing this utility (e.g., typography,
  ///         spacing).
  /// [modifiers]: An optional list of [PrefixModifier]s already applied.
  const CommonStyle(super.cssClass, {super.modifiers, required super.type});

  // Subclasses must still implement `create(List<PrefixModifier> modifiers)`.
}

// Colors and backgrounds
class Colors extends CommonStyle<Colors> {
  const Colors(super.cssClass, {super.modifiers})
    : super(type: StyleType.style);

  static const bgPrimary = Colors('bg-primary');
  static const textPrimary = Colors('text-primary');
  static const borderPrimary = Colors('border-primary');

  @override
  Colors create(List<PrefixModifier> modifiers) {
    // Create a new instance with the original cssClass and new modifiers
    return Colors(cssClass, modifiers: modifiers);
  }
}
