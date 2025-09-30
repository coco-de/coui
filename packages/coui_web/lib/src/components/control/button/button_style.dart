import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/control/button/button.dart';

/// Marker interface for any utility that can be passed to a [Button]'s `modifiers` list.
abstract class _ButtonStyling implements Styling {}

/// Public interface for ButtonStyling.
typedef ButtonStyling = _ButtonStyling;

/// Represents component-specific utility classes for the [Button] component.
///
/// These modifiers control the appearance and state of the button, such as its
/// color, size, shape (e.g., square, circle), and operational state (e.g., disabled).
class ButtonStyle extends ComponentStyle<ButtonStyle>
    with Breakpoints<ButtonStyle>
    implements ButtonStyling {
  /// Constructs a [ButtonStyle].
  ///
  /// [cssClass]: The core CSS class string for this modifier (e.g., "btn-primary").
  /// [type]: The [StyleType] categorizing this modifier.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied to this modifier.
  const ButtonStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  ButtonStyle create(List<PrefixModifier> modifiers) {
    return ButtonStyle(cssClass, modifiers: modifiers, type: type);
  }
}
