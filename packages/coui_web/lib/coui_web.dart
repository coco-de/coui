// Package exports for coui_web library.

// --- BASE ---.
// Core concepts, interfaces, and base classes for the library.
export 'src/base/base_style.dart';
export 'src/base/common_style.dart';
export 'src/base/styling.dart';
export 'src/base/styling_extensions.dart';
export 'src/base/tailwind_classes.dart';
export 'src/base/types.dart';
export 'src/base/ui_component.dart';
export 'src/base/ui_component_attributes.dart';
export 'src/base/ui_events.dart';
export 'src/base/ui_prefix_modifier.dart';
export 'src/base/variant_system.dart';
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
export 'src/components/form/date_picker/date_picker_style.dart'
    show DatePickerStyling;
export 'src/components/form/form_field/form_field.dart';
export 'src/components/form/form_field/form_field_style.dart'
    show FormFieldStyling;
export 'src/components/form/input/input.dart';
export 'src/components/form/input/input_style.dart' show InputStyling;
export 'src/components/form/input/text_field.dart';
export 'src/components/form/radio/radio.dart';
export 'src/components/form/radio/radio_style.dart' show RadioStyling;
export 'src/components/form/select/select.dart';
export 'src/components/form/select/select_style.dart' show SelectStyling;
export 'src/components/form/slider/slider.dart';
export 'src/components/form/slider/slider_style.dart' show SliderStyling;
export 'src/components/form/switch_field/switch_field.dart';
export 'src/components/form/switch_field/switch_field_style.dart'
    show SwitchFieldStyling;
export 'src/components/form/textarea/textarea.dart';
export 'src/components/form/textarea/textarea_style.dart' show TextareaStyling;
export 'src/components/form/toggle/toggle.dart';
export 'src/components/form/toggle/toggle_style.dart' show ToggleStyling;

// --- DISPLAY ---
// Display-only components.
export 'src/components/display/accordion/accordion.dart';
export 'src/components/display/accordion/accordion_style.dart'
    show AccordionStyling;
export 'src/components/display/alert/alert.dart';
export 'src/components/display/alert/alert_style.dart' show AlertStyling;
export 'src/components/display/avatar/avatar.dart';
export 'src/components/display/avatar/avatar_style.dart' show AvatarStyling;
export 'src/components/display/badge/badge.dart';
export 'src/components/display/badge/badge_style.dart' show BadgeStyling;
export 'src/components/display/banner/banner.dart';
export 'src/components/display/banner/banner_style.dart' show BannerStyling;
export 'src/components/display/calendar/calendar.dart';
export 'src/components/display/calendar/calendar_style.dart'
    show CalendarStyling;
export 'src/components/display/carousel/carousel.dart';
export 'src/components/display/carousel/carousel_style.dart'
    show CarouselStyling;
export 'src/components/display/chip/chip.dart';
export 'src/components/display/chip/chip_style.dart' show ChipStyling;
export 'src/components/display/code_block/code_block.dart';
export 'src/components/display/code_block/code_block_style.dart'
    show CodeBlockStyling;
export 'src/components/display/command/command.dart';
export 'src/components/display/command/command_style.dart' show CommandStyling;
export 'src/components/display/divider/divider.dart';
export 'src/components/display/divider/divider_style.dart' show DividerStyling;
export 'src/components/display/empty_state/empty_state.dart';
export 'src/components/display/empty_state/empty_state_style.dart'
    show EmptyStateStyling;
export 'src/components/display/hover_card/hover_card.dart';
export 'src/components/display/hover_card/hover_card_style.dart'
    show HoverCardStyling;
export 'src/components/display/kbd/kbd.dart';
export 'src/components/display/kbd/kbd_style.dart' show KbdStyling;
export 'src/components/display/label/label.dart';
export 'src/components/display/label/label_style.dart' show LabelStyling;
export 'src/components/display/loading/loading.dart';
export 'src/components/display/loading/loading_style.dart' show LoadingStyling;
export 'src/components/display/rating/rating.dart';
export 'src/components/display/rating/rating_style.dart' show RatingStyling;
export 'src/components/display/resizable/resizable.dart';
export 'src/components/display/resizable/resizable_style.dart'
    show ResizableStyling;
export 'src/components/display/scroll_area/scroll_area.dart';
export 'src/components/display/scroll_area/scroll_area_style.dart'
    show ScrollAreaStyling;
export 'src/components/display/stat/stat.dart';
export 'src/components/display/stat/stat_style.dart' show StatStyling;
export 'src/components/display/progress/progress.dart';
export 'src/components/display/progress/progress_style.dart'
    show ProgressStyling;
export 'src/components/display/skeleton/skeleton.dart';
export 'src/components/display/skeleton/skeleton_style.dart'
    show SkeletonStyling;
export 'src/components/display/timeline/timeline.dart';
export 'src/components/display/timeline/timeline_style.dart'
    show TimelineStyling;
export 'src/components/display/aspect_ratio/aspect_ratio.dart';
export 'src/components/display/aspect_ratio/aspect_ratio_style.dart'
    show AspectRatioStyling;

// --- LAYOUT ---
// Layout components.
export 'src/components/layout/breadcrumb/breadcrumb.dart';
export 'src/components/layout/breadcrumb/breadcrumb_style.dart'
    show BreadcrumbStyling;
export 'src/components/layout/card/card.dart';
export 'src/components/layout/card/card_style.dart' show CardStyling;
export 'src/components/layout/collapsible/collapsible.dart';
export 'src/components/layout/collapsible/collapsible_style.dart'
    show CollapsibleStyling;
export 'src/components/layout/container/container.dart';
export 'src/components/layout/container/container_style.dart'
    show ContainerStyling;
export 'src/components/layout/gap/gap.dart';
export 'src/components/layout/grid/grid.dart';
export 'src/components/layout/grid/grid_style.dart' show GridStyling;
export 'src/components/layout/scaffold/scaffold.dart';
export 'src/components/layout/scaffold/scaffold_style.dart'
    show ScaffoldStyling;
export 'src/components/layout/separator/separator.dart';
export 'src/components/layout/separator/separator_style.dart'
    show SeparatorStyling;
export 'src/components/layout/stepper/stepper.dart';
export 'src/components/layout/stepper/stepper_style.dart' show StepperStyling;
export 'src/components/layout/table/table.dart';
export 'src/components/layout/table/table_style.dart' show TableStyling;

// --- MENU ---
// Menu and dropdown components.
export 'src/components/menu/context_menu/context_menu.dart';
export 'src/components/menu/context_menu/context_menu_style.dart'
    show ContextMenuStyling;
export 'src/components/menu/dropdown_menu/dropdown_menu.dart';
export 'src/components/menu/dropdown_menu/dropdown_menu_style.dart'
    show DropdownMenuStyling;

// --- NAVIGATION ---
// Navigation components.
export 'src/components/navigation/navigation_bar/navigation_bar.dart';
export 'src/components/navigation/navigation_bar/navigation_bar_style.dart'
    show NavigationBarStyling;
export 'src/components/navigation/pagination/pagination.dart';
export 'src/components/navigation/pagination/pagination_style.dart'
    show PaginationStyling;
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
// Generic HTML element wrappers like Figure.
export 'src/elements/figure.dart';
