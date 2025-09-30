import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/display/alert/alert.dart';

/// A marker interface for any utility that can be passed to an [Alert]'s `style` list.
///
/// This allows for type-safe application of styles for colors, variants, and layout direction.
abstract class _AlertStyling implements Styling {}

/// A marker interface for any utility that can be passed to an [Alert]'s `style` list.
///
/// This allows for type-safe application of styles for colors, variants, and layout direction.
typedef AlertStyling = _AlertStyling;

/// Defines specific styling options for an [Alert] component.
///
/// This is the concrete implementation class for alert-specific modifiers.
/// It implements the [AlertStyling] interface, making it a valid type for the
/// `style` property of an [Alert] component.
class AlertStyle extends ComponentStyle<AlertStyle>
    with Breakpoints<AlertStyle>
    implements AlertStyling {
  /// Constructs an [AlertStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "alert-success").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const AlertStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [AlertStyle] with the provided modifiers.
  @override
  AlertStyle create(List<PrefixModifier> modifiers) {
    return AlertStyle(cssClass, modifiers: modifiers, type: type);
  }
}
