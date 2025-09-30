import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/toggle/toggle.dart';

/// A marker interface for any utility that can be passed to a [Toggle]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
abstract class _ToggleStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Toggle]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
typedef ToggleStyling = _ToggleStyling;

/// Defines specific styling options for a [Toggle] component.
///
/// This is the concrete implementation class for toggle-specific modifiers.
/// It implements the [ToggleStyling] interface, making it a valid type for the
/// `style` property of a [Toggle] component.
class ToggleStyle extends ComponentStyle<ToggleStyle>
    with Breakpoints<ToggleStyle>
    implements ToggleStyling {
  /// Constructs a [ToggleStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "toggle-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const ToggleStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [ToggleStyle] with the provided modifiers.
  @override
  ToggleStyle create(List<PrefixModifier> modifiers) {
    return ToggleStyle(cssClass, modifiers: modifiers, type: type);
  }
}
