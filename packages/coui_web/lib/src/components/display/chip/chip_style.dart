import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Marker interface for any utility that can be passed to a Chip's `style` list.
abstract class _ChipStyling implements Styling {}

/// Public interface for ChipStyling.
typedef ChipStyling = _ChipStyling;

/// Represents component-specific utility classes for the Chip component.
///
/// These modifiers control the appearance and state of the chip, such as its
/// color variant, size, and outline style.
class ChipStyle extends ComponentStyle<ChipStyle>
    with Breakpoints<ChipStyle>
    implements ChipStyling {
  /// Constructs a [ChipStyle].
  ///
  /// [cssClass]: The core CSS class string for this modifier (e.g., "badge-primary").
  /// [type]: The [StyleType] categorizing this modifier.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied.
  const ChipStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  ChipStyle create(List<PrefixModifier> modifiers) {
    return ChipStyle(cssClass, modifiers: modifiers, type: type);
  }
}