import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/text/link/link.dart';

/// A marker interface for any utility that can be passed to a [Link]'s `style` list.
///
/// This allows for type-safe application of styles for color and hover behavior.
abstract class _LinkStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Link]'s `style` list.
///
/// This allows for type-safe application of styles for color and hover behavior.
typedef LinkStyling = _LinkStyling;

/// Defines specific styling options for a [Link] component.
///
/// This is the concrete implementation class for link-specific modifiers.
/// It implements the [LinkStyling] interface, making it a valid type for the
/// `style` property of a [Link] component.
class LinkStyle extends ComponentStyle<LinkStyle>
    with Breakpoints<LinkStyle>
    implements LinkStyling {
  /// Constructs a [LinkStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "link-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const LinkStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [LinkStyle] with the provided modifiers.
  @override
  LinkStyle create(List<PrefixModifier> modifiers) {
    return LinkStyle(cssClass, modifiers: modifiers, type: type);
  }
}
