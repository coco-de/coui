import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/icon/icon.dart';

/// Marker interface for any utility that can be passed to an [Icon]'s `modifiers` list.
abstract class _IconStyling implements Styling {}

/// Marker interface for any utility that can be passed to an [Icon]'s `modifiers` list.
typedef IconStyling = _IconStyling;

/// Defines specific styling options for an [Icon] component,
/// such as fill state or font weight, often specific to the icon font being used.
/// Implements the [IconStyling] interface.
class IconStyle extends ComponentStyle<IconStyle>
    with Breakpoints<IconStyle>
    implements IconStyling {
  // Implements the IconModifier INTERFACE
  const IconStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  IconStyle create(List<PrefixModifier> modifiers) {
    return IconStyle(cssClass, modifiers: modifiers, type: type);
  }
}
