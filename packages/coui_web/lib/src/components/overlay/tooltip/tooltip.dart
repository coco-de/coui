import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip_style.dart';
import 'package:jaspr/jaspr.dart';

/// Position of the tooltip relative to its child element.
enum TooltipPosition {
  /// Tooltip appears below the element.
  bottom,

  /// Tooltip appears to the left of the element.
  left,

  /// Tooltip appears to the right of the element.
  right,

  /// Tooltip appears above the element.
  top,
}
