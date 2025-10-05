import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// A marker interface for any utility that can be passed to a [Divider]'s `style` list.
///
/// This allows for type-safe application of styles for color, direction, and text placement.
abstract class _DividerStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Divider]'s `style` list.
///
/// This allows for type-safe application of styles for color, direction, and text placement.
typedef DividerStyling = _DividerStyling;

/// Defines specific styling options for a [Divider] component.
///
/// This is the concrete implementation class for divider-specific modifiers.
/// It implements the [DividerStyling] interface, making it a valid type for the
/// `style` property of a [Divider] component.
class DividerStyle extends ComponentStyle<DividerStyle>
    with Breakpoints<DividerStyle>
    implements DividerStyling {
  /// Constructs a [DividerStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "divider-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const DividerStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [DividerStyle] with the provided modifiers.
  @override
  DividerStyle create(List<PrefixModifier> modifiers) {
    return DividerStyle(cssClass, modifiers: modifiers, type: type);
  }
}
