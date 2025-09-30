import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/form/input/input.dart';

/// A marker interface for any utility that can be passed to an [Input]'s `style` list.
///
/// This allows for type-safe application of styles for colors, sizes, and variants.
abstract class _InputStyling implements Styling {}

/// A marker interface for any utility that can be passed to an [Input]'s `style` list.
///
/// This allows for type-safe application of styles for colors, sizes, and variants.
typedef InputStyling = _InputStyling;

/// Defines specific styling options for an [Input] component.
///
/// This is the concrete implementation class for input-specific modifiers.
/// It implements the [InputStyling] interface, making it a valid type for the
/// `style` property of an [Input] component.
class InputStyle extends ComponentStyle<InputStyle>
    with Breakpoints<InputStyle>
    implements InputStyling {
  /// Constructs an [InputStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "input-bordered").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const InputStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [InputStyle] with the provided modifiers.
  @override
  InputStyle create(List<PrefixModifier> modifiers) {
    return InputStyle(cssClass, modifiers: modifiers, type: type);
  }
}
