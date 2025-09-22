// Package exports for coui_web library.

// --- BASE ---.
// Core concepts, interfaces, and base classes for the library.
export 'src/base/base_style.dart';
export 'src/base/common_style.dart';
export 'src/base/styling.dart';
export 'src/base/styling_extensions.dart';
export 'src/base/ui_component.dart';
export 'src/base/ui_component_attributes.dart';
export 'src/base/ui_events.dart';
export 'src/base/ui_prefix_modifier.dart';
// --- UTILITIES ---.
// General-purpose styling classes for layout, spacing, typography, etc.
export 'src/base/utilities/alignment.dart';
export 'src/base/utilities/bg_util.dart';
export 'src/base/utilities/border_util.dart';
export 'src/base/utilities/effects.dart';
export 'src/base/utilities/flex.dart';
export 'src/base/utilities/grid.dart';
export 'src/base/utilities/layout.dart';
export 'src/base/utilities/position.dart';
export 'src/base/utilities/size.dart';
export 'src/base/utilities/spacing.dart';
export 'src/base/utilities/text_util.dart';
// --- COMPONENTS ---.
// All DaisyUI components with their respective styling interfaces.

// Alert component.
export 'src/components/alert/alert.dart';
export 'src/components/alert/alert_style.dart' show AlertStyling;
// Badge component.
export 'src/components/badge/badge.dart';
export 'src/components/badge/badge_style.dart' show BadgeStyling;
// Button component.
export 'src/components/button/button.dart';
export 'src/components/button/button_style.dart' show ButtonStyling;
// Card component.
export 'src/components/card/card.dart';
export 'src/components/card/card_style.dart' show CardStyling;
// Checkbox component.
export 'src/components/checkbox/checkbox.dart';
export 'src/components/checkbox/checkbox_style.dart' show CheckboxStyling;
// Divider component.
export 'src/components/divider/divider.dart';
export 'src/components/divider/divider_style.dart' show DividerStyling;
// Icon component.
export 'src/components/icon/icon.dart';
export 'src/components/icon/icon_style.dart' show IconStyling;
// Input component.
export 'src/components/input/input.dart';
export 'src/components/input/input_style.dart' show InputStyling;
// Link component.
export 'src/components/link/link.dart';
export 'src/components/link/link_style.dart' show LinkStyling;
// Loading component.
export 'src/components/loading/loading.dart';
export 'src/components/loading/loading_style.dart' show LoadingStyling;
// Progress component.
export 'src/components/progress/progress.dart';
export 'src/components/progress/progress_style.dart' show ProgressStyling;
// Radio component.
export 'src/components/radio/radio.dart';
export 'src/components/radio/radio_style.dart' show RadioStyling;
// Select component.
export 'src/components/select/select.dart';
export 'src/components/select/select_style.dart' show SelectStyling;
// Textarea component.
export 'src/components/textarea/textarea.dart';
export 'src/components/textarea/textarea_style.dart' show TextareaStyling;
// Toggle component.
export 'src/components/toggle/toggle.dart';
export 'src/components/toggle/toggle_style.dart' show ToggleStyling;
// --- ELEMENTS ---.
// Generic HTML element wrappers like Container and Figure.
export 'src/elements/container.dart';
export 'src/elements/figure.dart';
