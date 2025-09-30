import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart'
    show Breakpoints, PrefixModifier;
import 'package:coui_web/src/components/display/badge/badge.dart';

/// Marker interface for any utility that can be passed to a [Badge]'s `styles` list.
abstract class _BadgeStyling implements Styling {}

/// Marker interface for any utility that can be passed to a [Badge]'s `styles` list.
typedef BadgeStyling = _BadgeStyling;

/// Represents component-specific utility classes that can be applied to a [Badge] component.
///
/// These modifiers control the appearance of the badge, such as its color,
/// style (e.g., outline), and size.
class BadgeStyle extends ComponentStyle<BadgeStyle>
    with Breakpoints<BadgeStyle>
    implements BadgeStyling {
  /// Constructs a [BadgeStyling].
  ///
  /// [cssClass]: The core CSS class string for this modifier (e.g., "badge-primary").
  /// [type]: The [StyleType] categorizing this modifier.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied to this modifier.
  const BadgeStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  BadgeStyle create(List<PrefixModifier> modifiers) {
    return BadgeStyle(cssClass, modifiers: modifiers, type: type);
  }
}
