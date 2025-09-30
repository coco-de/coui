import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Marker interface for any utility that can be passed to a Skeleton's `style` list.
abstract class _SkeletonStyling implements Styling {}

/// Public interface for SkeletonStyling.
typedef SkeletonStyling = _SkeletonStyling;

/// Represents component-specific utility classes for the Skeleton component.
///
/// These modifiers control the appearance of skeleton loading placeholders.
class SkeletonStyle extends ComponentStyle<SkeletonStyle>
    with Breakpoints<SkeletonStyle>
    implements SkeletonStyling {
  /// Constructs a [SkeletonStyle].
  ///
  /// [cssClass]: The core CSS class string for this modifier.
  /// [type]: The [StyleType] categorizing this modifier.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied.
  const SkeletonStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  SkeletonStyle create(List<PrefixModifier> modifiers) {
    return SkeletonStyle(cssClass, modifiers: modifiers, type: type);
  }
}