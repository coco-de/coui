import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/textarea/textarea.dart';

/// A marker interface for any utility that can be passed to a [Textarea]'s `style` list.
///
/// This allows for type-safe application of styles for colors, sizes, and variants.
abstract class _TextareaStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Textarea]'s `style` list.
///
/// This allows for type-safe application of styles for colors, sizes, and variants.
typedef TextareaStyling = _TextareaStyling;

/// Defines specific styling options for a [Textarea] component.
///
/// This is the concrete implementation class for textarea-specific modifiers.
/// It implements the [TextareaStyling] interface, making it a valid type for the
/// `style` property of a [Textarea] component.
class TextareaStyle extends ComponentStyle<TextareaStyle>
    with Breakpoints<TextareaStyle>
    implements TextareaStyling {
  /// Constructs a [TextareaStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "textarea-bordered").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const TextareaStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [TextareaStyle] with the provided modifiers.
  @override
  TextareaStyle create(List<PrefixModifier> modifiers) {
    return TextareaStyle(cssClass, modifiers: modifiers, type: type);
  }
}
