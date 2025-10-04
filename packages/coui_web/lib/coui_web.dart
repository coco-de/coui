// Package exports for coui_web library.

// --- BASE ---.
// Core concepts, interfaces, and base classes for the library.
export 'src/base/base_style.dart';
export 'src/base/common_style.dart';
export 'src/base/styling.dart';
export 'src/base/styling_extensions.dart';
export 'src/base/types.dart';
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
// All DaisyUI components organized by category.

// --- CONTROL ---
// User interaction controls.
export 'src/components/control/button/button.dart';
export 'src/components/control/button/button_style.dart' show ButtonStyling;

// --- FORM ---
// Form input components.
export 'src/components/form/checkbox/checkbox.dart';
export 'src/components/form/checkbox/checkbox_style.dart' show CheckboxStyling;
export 'src/components/form/date_picker/date_picker.dart';
export 'src/components/form/date_picker/date_picker_style.dart' show DatePickerStyling;
export 'src/components/form/input/input.dart';
export 'src/components/form/input/input_style.dart' show InputStyling;
export 'src/components/form/input/text_field.dart';
export 'src/components/form/radio/radio.dart';
export 'src/components/form/radio/radio_style.dart' show RadioStyling;
export 'src/components/form/select/select.dart';
export 'src/components/form/select/select_style.dart' show SelectStyling;
export 'src/components/form/slider/slider.dart';
export 'src/components/form/slider/slider_style.dart' show SliderStyling;
export 'src/components/form/textarea/textarea.dart';
export 'src/components/form/textarea/textarea_style.dart' show TextareaStyling;
export 'src/components/form/toggle/toggle.dart';
export 'src/components/form/toggle/toggle_style.dart' show ToggleStyling;

// --- DISPLAY ---
// Display-only components.
export 'src/components/display/accordion/accordion.dart';
export 'src/components/display/accordion/accordion_style.dart' show AccordionStyling;
export 'src/components/display/alert/alert.dart';
export 'src/components/display/alert/alert_style.dart' show AlertStyling;
export 'src/components/display/avatar/avatar.dart';
export 'src/components/display/avatar/avatar_style.dart' show AvatarStyling;
export 'src/components/display/badge/badge.dart';
export 'src/components/display/badge/badge_style.dart' show BadgeStyling;
export 'src/components/display/chip/chip.dart';
export 'src/components/display/chip/chip_style.dart' show ChipStyling;
export 'src/components/display/divider/divider.dart';
export 'src/components/display/divider/divider_style.dart' show DividerStyling;
export 'src/components/display/loading/loading.dart';
export 'src/components/display/loading/loading_style.dart' show LoadingStyling;
export 'src/components/display/progress/progress.dart';
export 'src/components/display/progress/progress_style.dart' show ProgressStyling;
export 'src/components/display/skeleton/skeleton.dart';
export 'src/components/display/skeleton/skeleton_style.dart' show SkeletonStyling;

// --- LAYOUT ---
// Layout components.
export 'src/components/layout/breadcrumb/breadcrumb.dart';
export 'src/components/layout/breadcrumb/breadcrumb_style.dart' show BreadcrumbStyling;
export 'src/components/layout/card/card.dart';
export 'src/components/layout/card/card_style.dart' show CardStyling;

// --- MENU ---
// Menu and dropdown components.
export 'src/components/menu/context_menu/context_menu.dart';
export 'src/components/menu/context_menu/context_menu_style.dart' show ContextMenuStyling;
export 'src/components/menu/dropdown_menu/dropdown_menu.dart';
export 'src/components/menu/dropdown_menu/dropdown_menu_style.dart' show DropdownMenuStyling;

// --- NAVIGATION ---
// Navigation components.
export 'src/components/navigation/navigation_bar/navigation_bar.dart';
export 'src/components/navigation/navigation_bar/navigation_bar_style.dart' show NavigationBarStyling;
export 'src/components/navigation/pagination/pagination.dart';
export 'src/components/navigation/pagination/pagination_style.dart' show PaginationStyling;
export 'src/components/navigation/tabs/tabs.dart';
export 'src/components/navigation/tabs/tabs_style.dart' show TabsStyling;

// --- OVERLAY ---
// Overlay components.
export 'src/components/overlay/dialog/dialog.dart';
export 'src/components/overlay/dialog/dialog_style.dart' show DialogStyling;
export 'src/components/overlay/drawer/drawer.dart';
export 'src/components/overlay/drawer/drawer_style.dart' show DrawerStyling;
export 'src/components/overlay/popover/popover.dart';
export 'src/components/overlay/popover/popover_style.dart' show PopoverStyling;
export 'src/components/overlay/toast/toast.dart';
export 'src/components/overlay/toast/toast_style.dart' show ToastStyling;
export 'src/components/overlay/tooltip/tooltip.dart';
export 'src/components/overlay/tooltip/tooltip_style.dart' show TooltipStyling;

// --- TEXT ---
// Text components.
export 'src/components/text/link/link.dart';
export 'src/components/text/link/link_style.dart' show LinkStyling;

// --- ICON ---
// Icon components.
export 'src/components/icon/icon.dart';
export 'src/components/icon/icon_style.dart' show IconStyling;

// --- ELEMENTS ---.
// Generic HTML element wrappers like Container and Figure.
export 'src/elements/container.dart';
export 'src/elements/figure.dart';
