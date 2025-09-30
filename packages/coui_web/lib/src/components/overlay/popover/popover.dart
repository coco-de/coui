import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:jaspr/jaspr.dart';

/// Position of the popover relative to trigger element.
enum PopoverPosition {
  /// Popover appears below the trigger.
  bottom,

  /// Popover appears to the left of the trigger.
  left,

  /// Popover appears to the right of the trigger.
  right,

  /// Popover appears above the trigger.
  top,
}

/// Trigger mode for showing the popover.
enum PopoverTrigger {
  /// Popover shows on click.
  click,

  /// Popover shows on hover.
  hover,
}
