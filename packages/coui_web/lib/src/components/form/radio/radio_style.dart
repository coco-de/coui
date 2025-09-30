import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/radio/radio.dart';

/// A marker interface for any utility that can be passed to a [Radio]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
abstract class _RadioStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Radio]'s `style` list.
///
/// This allows for type-safe application of styles for colors and sizes.
typedef RadioStyling = _RadioStyling;

/// Defines specific styling options for a [Radio] component.
///
/// This is the concrete implementation class for radio-button-specific modifiers.
/// It implements the [RadioStyling] interface, making it a valid type for the
/// `style` property of a [Radio] component.
class RadioStyle extends ComponentStyle<RadioStyle>
    with Breakpoints<RadioStyle>
    implements RadioStyling {
  /// Constructs a [RadioStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier
  ///   (e.g., "radio-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive
  ///   styling.
  const RadioStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [RadioStyle] with the provided modifiers.
  @override
  RadioStyle create(List<PrefixModifier> modifiers) {
    return RadioStyle(cssClass, modifiers: modifiers, type: type);
  }
}
