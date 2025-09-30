import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/loading/loading.dart';

/// A marker interface for any utility that can be passed to a [Loading]'s `style` list.
///
/// This allows for type-safe application of styles for animation type and size.
/// Note that color is applied via general text utilities like `TextUtil.primary`.
abstract class _LoadingStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Loading]'s `style` list.
///
/// This allows for type-safe application of styles for animation type and size.
/// Note that color is applied via general text utilities like `TextUtil.primary`.
typedef LoadingStyling = _LoadingStyling;

/// Defines specific styling options for a [Loading] component.
///
/// This is the concrete implementation class for loading-specific modifiers.
/// It implements the [LoadingStyling] interface, making it a valid type for the
/// `style` property of a [Loading] component.
class LoadingStyle extends ComponentStyle<LoadingStyle>
    with Breakpoints<LoadingStyle>
    implements LoadingStyling {
  /// Constructs a [LoadingStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "loading-spinner").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const LoadingStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [LoadingStyle] with the provided modifiers.
  @override
  LoadingStyle create(List<PrefixModifier> modifiers) {
    return LoadingStyle(cssClass, modifiers: modifiers, type: type);
  }
}
