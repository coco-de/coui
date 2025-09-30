import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Marker interface for any utility that can be passed to an Avatar's `style` list.
abstract class _AvatarStyling implements Styling {}

/// Public interface for AvatarStyling.
typedef AvatarStyling = _AvatarStyling;

/// Represents component-specific utility classes for the Avatar component.
///
/// These modifiers control the appearance and state of the avatar, such as its
/// shape, status indicators (online/offline), and placeholder styling.
class AvatarStyle extends ComponentStyle<AvatarStyle>
    with Breakpoints<AvatarStyle>
    implements AvatarStyling {
  /// Constructs an [AvatarStyle].
  ///
  /// [cssClass]: The core CSS class string for this modifier (e.g., "avatar-online").
  /// [type]: The [StyleType] categorizing this modifier.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied to this modifier.
  const AvatarStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  AvatarStyle create(List<PrefixModifier> modifiers) {
    return AvatarStyle(cssClass, modifiers: modifiers, type: type);
  }
}