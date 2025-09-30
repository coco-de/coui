import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/display/progress/progress.dart';

/// A marker interface for any utility that can be passed to a [Progress]'s `style` list.
///
/// This allows for type-safe application of styles for color.
/// Note that size is applied via general utilities like `Sizing.w()`.
abstract class _ProgressStyling implements Styling {}

/// A marker interface for any utility that can be passed to a [Progress]'s `style` list.
///
/// This allows for type-safe application of styles for color.
/// Note that size is applied via general utilities like `Sizing.w()`.
typedef ProgressStyling = _ProgressStyling;

/// Defines specific styling options for a [Progress] component.
///
/// This is the concrete implementation class for progress-specific modifiers.
/// It implements the [ProgressStyling] interface, making it a valid type for the
/// `style` property of a [Progress] component.
class ProgressStyle extends ComponentStyle<ProgressStyle>
    with Breakpoints<ProgressStyle>
    implements ProgressStyling {
  /// Constructs a [ProgressStyle].
  ///
  /// - [cssClass]: The core CSS class string for this modifier (e.g., "progress-primary").
  /// - [type]: The [StyleType] categorizing this modifier.
  /// - [modifiers]: An optional list of [PrefixModifier]s for responsive styling.
  const ProgressStyle(super.cssClass, {super.modifiers, required super.type});

  /// Creates a new instance of [ProgressStyle] with the provided modifiers.
  @override
  ProgressStyle create(List<PrefixModifier> modifiers) {
    return ProgressStyle(cssClass, modifiers: modifiers, type: type);
  }
}
