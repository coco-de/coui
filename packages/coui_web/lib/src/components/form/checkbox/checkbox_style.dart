import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/checkbox/checkbox.dart';

/// A marker interface for any utility that can be passed to a [Checkbox]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
abstract class _CheckboxStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Checkbox]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
typedef CheckboxStyling = _CheckboxStyling;

/// Defines specific styling options for a [Checkbox] component.
///
/// This is the concrete implementation class for checkbox-specific modifiers.
/// It implements the [CheckboxStyling] interface, making it a valid type for the
/// `style` property of a [Checkbox] component.
class CheckboxStyle extends ComponentStyle<CheckboxStyle>
    with Breakpoints<CheckboxStyle>
    implements CheckboxStyling {
  /// Constructs a [CheckboxStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "checkbox-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const CheckboxStyle(
    super.cssClass, {
    super.modifiers,
    required super.type,
  });

  /// Creates a new instance of [CheckboxStyle] with the provided modifiers.
  @override
  CheckboxStyle create(List<PrefixModifier> modifiers) {
    return CheckboxStyle(cssClass, modifiers: modifiers, type: type);
  }
}
