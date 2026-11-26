// Package exports for coui_web library.

// --- COUI CORE ---.
// Re-export coui_core for cross-platform API parity (same as coui_flutter).
export 'package:coui_core/coui_core.dart';
// --- JASPR (re-exported with collisions hidden) ---
// Users import only `package:coui_web/coui_web.dart` and get jaspr's
// Component / BuildContext / StatelessComponent / Styles / dom helpers
// without needing a separate `import 'package:jaspr/jaspr.dart';`.
//
// We hide every jaspr identifier that conflicts with a CoUI class so
// the CoUI version always wins:
//   - Text          : our `Text` widget (src/components/text/text.dart)
//   - ColorScheme   : our theme's color scheme (src/theme/color_scheme.dart)
//   - Spacing       : deprecated alias hidden — use `CoreSpace`
//   - AutoComplete  : `AutoComplete`'s public alias
//   - AspectRatio   : superseded by `AspectRatioBox`; jaspr's
//                     native `AspectRatio` is hidden to free the name
//                     for the unified primitive's documentation.
//   - Filter        : `Filter` overlay
export 'package:jaspr/dom.dart'
    hide
        AspectRatio,
        AutoComplete,
        ColorScheme,
        Filter,
        Flex,
        FontStyle,
        Gap,
        Position,
        Spacing;
export 'package:jaspr/jaspr.dart' hide Text;

// --- BASE ---.
// Core concepts, interfaces, and base classes for the library.
export 'src/base/adaptive_quality_scope.dart';
export 'src/base/animation/easing_functions.dart';
export 'src/base/asset_source_scope.dart';
export 'src/base/brightness_scope.dart' show BrightnessScope;
export 'src/base/density_scope.dart';
export 'src/base/fold_scope.dart' show FoldScope;
export 'src/base/main_landmark_scope.dart';
export 'src/base/surface_style_scope.dart';
export 'src/base/theme_config.dart';
export 'src/base/theme_controller.dart';
export 'src/base/types.dart';
export 'src/base/typography_tier_scope.dart' show TypographyTierScope;
export 'src/base/ui_component.dart';
export 'src/base/ui_component_attributes.dart';
export 'src/base/ui_events.dart';
export 'src/base/ui_stateful_component.dart';
export 'src/base/web_chrome.dart';
export 'src/base/web_dom_utils.dart' show listenForViewportResize, viewportSize;
export 'src/base/web_element_chrome.dart';
export 'src/base/web_layout.dart';
export 'src/base/web_resolved_chrome.dart';
// --- CONTROL ---
// User interaction controls.
export 'src/components/control/button/button.dart';
// --- UTILITIES ---.
// General-purpose styling classes for layout, spacing, typography, etc.
// --- COMPONENTS ---.
// All CoUI components organized by category.

export 'src/components/control/button/button_style.dart'
    show ResolvedButton, resolveButton;
export 'src/components/control/command/command.dart';
export 'src/components/control/command/command_style.dart'
    show
        ResolvedCommand,
        ResolvedCommandRules,
        kCommandRowMarker,
        kCommandWashMarker,
        resolveCommand,
        resolveCommandRules;
export 'src/components/control/command_search/command_search.dart';
export 'src/components/control/command_search/command_search_style.dart'
    show
        ResolvedCommandSearch,
        ResolvedCommandSearchRules,
        resolveCommandSearch,
        resolveCommandSearchRules;
export 'src/components/control/fab/fab.dart';
export 'src/components/control/fab/fab_style.dart' show ResolvedFab, resolveFab;
export 'src/components/control/filter/filter.dart';
export 'src/components/control/hover/hover.dart';
export 'src/components/control/hover/hover_style.dart'
    show ResolvedHover, resolveHover, resolveHoverTiming;
export 'src/components/control/theme_controller/theme_controller.dart';
export 'src/components/control/toggle_group/toggle_group.dart';
export 'src/components/control/toggle_group/toggle_group_style.dart'
    show ResolvedToggleGroup, resolveToggleGroup;
// --- DISPLAY ---
// Display-only components.
export 'src/components/display/aspect_ratio_box/aspect_ratio_box.dart';
export 'src/components/display/aspect_ratio_box/aspect_ratio_box_style.dart'
    show ResolvedAspectRatioBox, resolveAspectRatioBox;
// Top-level public builders for `AvatarGroup` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveAvatarGroup` per the Phase 16 PoC.
// `AvatarBadgeScope` is internal: the avatar mounts it around its own badge
// slot.
export 'src/components/display/avatar/avatar.dart' hide AvatarBadgeScope;
export 'src/components/display/avatar/avatar_style.dart'
    show
        ResolvedAvatar,
        ResolvedAvatarBadge,
        ResolvedAvatarGroup,
        resolveAvatar,
        resolveAvatarBadge,
        resolveAvatarGroup;
export 'src/components/display/badge/badge.dart';
export 'src/components/display/badge/badge_style.dart'
    show ResolvedBadge, ResolvedBadgeRules, resolveBadge, resolveBadgeRules;
export 'src/components/display/banner/banner.dart';
export 'src/components/display/calendar/calendar.dart';
export 'src/components/display/calendar/calendar_style.dart'
    show
        ResolvedCalendar,
        ResolvedCalendarMarker,
        resolveCalendar,
        resolveCalendarMarker;
export 'src/components/display/carousel/carousel.dart';
export 'src/components/display/carousel/carousel_style.dart'
    show ResolvedCarousel, resolveCarousel;
export 'src/components/display/carousel_banner/carousel_banner.dart';
// --- CATEGORY BREAKDOWN ---
// Category share (horizontal bars / donut + legend).
export 'src/components/display/category_breakdown/category_breakdown.dart';
export 'src/components/display/category_breakdown/category_breakdown_style.dart'
    show
        ResolvedCategoryBreakdown,
        ResolvedCategoryBreakdownSeries,
        resolveCategoryBreakdown;
export 'src/components/display/chat/chat.dart';
export 'src/components/display/chat/chat_style.dart';
export 'src/components/display/chip/chip.dart';
// Top-level public builders for `Chip` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveChip` per the Phase 14/15/16 PoC.
export 'src/components/display/chip/chip_style.dart'
    show ResolvedChip, resolveChip;
export 'src/components/display/chip_group/chip_group.dart';
export 'src/components/display/code_diff/code_diff.dart';
// Top-level public builders for `CodeDiff` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveCodeDiff` per the Phase 16 PoC.
export 'src/components/display/code_diff/code_diff_style.dart'
    show ResolvedCodeDiff, ResolvedCodeDiffRow, resolveCodeDiff;
export 'src/components/display/code_snippet/code_snippet.dart';
// Top-level public builders for `CodeSnippet` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveCodeSnippet` per the Phase 16 PoC.
export 'src/components/display/code_snippet/code_snippet_style.dart'
    show ResolvedCodeSnippet, resolveCodeSnippet;
export 'src/components/display/countdown/countdown.dart';
export 'src/components/display/countdown/countdown_style.dart'
    show ResolvedCountdown, resolveCountdown;
export 'src/components/display/description_card/description_card.dart';
export 'src/components/display/description_card/description_card_style.dart'
    show
        ResolvedDescriptionCard,
        ResolvedDescriptionCardRow,
        resolveDescriptionCard,
        resolveDescriptionCardRow;
export 'src/components/display/diff/diff.dart';
export 'src/components/display/diff/diff_style.dart'
    show ResolvedDiff, resolveDiff;
export 'src/components/display/disclosure_badge/disclosure_badge.dart';
export 'src/components/display/disclosure_badge/disclosure_badge_style.dart'
    show ResolvedDisclosureBadge, resolveDisclosureBadge;
export 'src/components/display/divider/divider.dart';
export 'src/components/display/divider/divider_style.dart'
    show ResolvedDivider, resolveDivider;
export 'src/components/display/dot_indicator/dot_indicator.dart';
// Top-level public builders for `DotIndicator` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveDotIndicator` per the PoC v3 옵션 B 최종 contract (single
// resolver entry point, per-dot Cat B chrome bundles live in
// `resolved.dots`).
export 'src/components/display/dot_indicator/dot_indicator_style.dart'
    show ResolvedDotIndicator, ResolvedDotIndicatorDot, resolveDotIndicator;
export 'src/components/display/empty_state/empty_state.dart';
export 'src/components/display/empty_state/empty_state_style.dart'
    show ResolvedEmptyState, resolveEmptyState;
export 'src/components/display/hover_gallery/hover_gallery.dart';
export 'src/components/display/hover_gallery/hover_gallery_style.dart'
    show ResolvedHoverGallery, resolveHoverGallery;
export 'src/components/display/indicator/indicator.dart';
export 'src/components/display/indicator/indicator_style.dart'
    show ResolvedIndicator, resolveIndicator;
export 'src/components/display/kbd/kbd.dart';
export 'src/components/display/kbd/kbd_style.dart' show ResolvedKbd, resolveKbd;
export 'src/components/display/label/label.dart';
export 'src/components/display/label/label_style.dart'
    show ResolvedLabel, resolveLabel;
export 'src/components/display/loading/loading.dart';
export 'src/components/display/loading/loading_style.dart'
    show ResolvedLoading, kLoadingDotsCount, resolveLoading, resolveLoadingCss;
// `LoadingRegionScope` is internal: on its own it would silence the
// skeletons below with nothing announcing in their place.
export 'src/components/display/loading_region/loading_region.dart'
    hide LoadingRegionScope;
export 'src/components/display/mockup_browser/mockup_browser.dart';
// Top-level public builders for `MockupBrowser` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveMockupBrowser` per the Phase 14/15/16 PoC.
export 'src/components/display/mockup_browser/mockup_browser_style.dart'
    show ResolvedMockupBrowser, resolveMockupBrowser;
export 'src/components/display/mockup_code/mockup_code.dart';
// Top-level public builders for `MockupCode` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveMockupCode` per the Phase 16 PoC.
export 'src/components/display/mockup_code/mockup_code_style.dart'
    show ResolvedMockupCode, resolveMockupCode;
export 'src/components/display/mockup_device/mockup_device.dart';
export 'src/components/display/mockup_device/mockup_device_style.dart'
    show
        ResolvedMockupDevice,
        ResolvedMockupDeviceStatusBar,
        ResolvedMockupDeviceStatusContent,
        ResolvedMockupDeviceStatusItem,
        resolveMockupDevice;
export 'src/components/display/mockup_foldable/mockup_foldable.dart';
export 'src/components/display/mockup_foldable/mockup_foldable_style.dart'
    show
        ResolvedMockupFoldable,
        ResolvedMockupFoldableRuntime,
        ResolvedMockupFoldableScreen,
        resolveMockupFoldable;
export 'src/components/display/number_ticker/number_ticker.dart';
// Top-level public builders for `NumberTicker` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveNumberTicker` per the Phase 16 PoC.
export 'src/components/display/number_ticker/number_ticker_style.dart'
    show ResolvedNumberTicker, resolveNumberTicker, resolveNumberTickerDuration;
export 'src/components/display/progress/progress.dart';
export 'src/components/display/progress/progress_style.dart'
    show
        ResolvedProgress,
        ResolvedRadialProgress,
        resolveProgress,
        resolveProgressIndeterminateCss,
        resolveRadialProgress,
        resolveRadialProgressGeometry;
export 'src/components/display/skeleton/skeleton.dart';
// Top-level public builders for `Skeleton` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveSkeleton` per the Phase 14/15/16 PoC.
export 'src/components/display/skeleton/skeleton_style.dart'
    show ResolvedSkeleton, resolveSkeleton;
export 'src/components/display/stat/stat.dart';
export 'src/components/display/stat/stat_style.dart'
    show ResolvedStat, resolveStat;
export 'src/components/display/status/status.dart';
export 'src/components/display/status/status_style.dart'
    show ResolvedStatus, resolveStatus;
export 'src/components/display/swap/swap.dart';
// Top-level public builders for `Swap` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveSwap` per the Phase 14/15/16 PoC.
export 'src/components/display/swap/swap_style.dart'
    show ResolvedSwap, resolveSwap;
export 'src/components/display/tag/tag.dart';
export 'src/components/display/tag/tag_style.dart' show ResolvedTag, resolveTag;
export 'src/components/display/timeline/timeline.dart';
export 'src/components/display/timeline/timeline_style.dart'
    show ResolvedTimeline, resolveTimeline;
// --- TRACKER ---
// Tracker component (status segments).
export 'src/components/display/tracker/tracker.dart';
export 'src/components/display/tracker/tracker_style.dart'
    show ResolvedTracker, resolveTracker;
// --- TREND CHART ---
// Time-series chart (line / bar + period chips + reference line).
export 'src/components/display/trend_chart/trend_chart.dart';
export 'src/components/display/trend_chart/trend_chart_style.dart'
    show ResolvedTrendChart, ResolvedTrendChartSeries, resolveTrendChart;
export 'src/components/display/validation_badge/validation_badge.dart';
export 'src/components/display/validation_badge/validation_badge_style.dart'
    show ResolvedValidationBadge, resolveValidationBadge;
// --- FORM ---
// Form input components.
export 'src/components/form/autocomplete/autocomplete.dart';
export 'src/components/form/checkbox/checkbox.dart';
export 'src/components/form/checkbox/checkbox_style.dart';
export 'src/components/form/chip_input/chip_input.dart';
export 'src/components/form/color_picker/color_picker.dart';
export 'src/components/form/color_picker/color_picker_style.dart';
export 'src/components/form/date_picker/date_picker.dart';
export 'src/components/form/date_picker/date_picker_style.dart'
    show ResolvedDatePicker, resolveDatePicker;
export 'src/components/form/fieldset/fieldset.dart';
export 'src/components/form/fieldset/fieldset_style.dart';
export 'src/components/form/file_input/file_input.dart';
export 'src/components/form/file_input/file_input_style.dart';
export 'src/components/form/form/form.dart';
export 'src/components/form/form/form_controller.dart';
export 'src/components/form/form_field/form_field.dart';
export 'src/components/form/form_field/form_field_scope.dart';
export 'src/components/form/form_label/form_label.dart';
export 'src/components/form/form_label/form_label_style.dart';
// `FormSortable` (legacy `form_sortable`) is superseded by the unified
// `Sortable` (exported below from `form/sortable/`) — same
// itemCount / itemBuilder(index, dragHandle, removeButton) / onReorder
// / onRemove / enabled / removable API. The legacy file was removed.
export 'src/components/form/formatted_input/formatted_input.dart';
export 'src/components/form/formatted_input/formatted_input_style.dart';
export 'src/components/form/formatter/formatter.dart';
export 'src/components/form/image_properties/image_properties.dart';
export 'src/components/form/input_otp/input_otp.dart';
export 'src/components/form/input_otp/input_otp_style.dart';
export 'src/components/form/item_picker/item_picker.dart';
export 'src/components/form/multi_answer_card/multi_answer_card.dart';
export 'src/components/form/multiple_choice/multiple_choice.dart';
export 'src/components/form/number_input/number_input.dart';
export 'src/components/form/number_input/number_input_style.dart';
export 'src/components/form/object_input/object_input.dart';
export 'src/components/form/option_item/option_item.dart';
export 'src/components/form/option_list/option_list.dart';
export 'src/components/form/phone_input/phone_input.dart';
export 'src/components/form/phone_input/phone_input_style.dart';
export 'src/components/form/radio_group/radio_group.dart';
export 'src/components/form/radio_group/radio_group_style.dart';
export 'src/components/form/range/range.dart';
export 'src/components/form/rich_editor/rich_editor.dart';
export 'src/components/form/select/select.dart';
export 'src/components/form/select/select_style.dart'
    show ResolvedSelect, resolveSelect;
export 'src/components/form/slider/slider.dart';
export 'src/components/form/slider/slider_style.dart';
export 'src/components/form/sortable/sortable.dart';
export 'src/components/form/sortable/sortable_style.dart';
export 'src/components/form/star_rating/star_rating.dart';
export 'src/components/form/star_rating/star_rating_style.dart';
export 'src/components/form/switch_field/switch_field.dart';
export 'src/components/form/text_area/text_area.dart';
export 'src/components/form/text_field/text_field.dart';
export 'src/components/form/time_picker/time_picker.dart';
export 'src/components/form/time_picker/time_picker_style.dart'
    show
        ResolvedTimePicker,
        ResolvedTimePickerRules,
        resolveTimePicker,
        resolveTimePickerRules;
export 'src/components/form/toggle/toggle.dart';
export 'src/components/form/toggle/toggle_style.dart';
export 'src/components/form/validated/validated.dart';
export 'src/components/form/validated/validated_style.dart';
export 'src/components/form/validator_hint/validator_hint.dart';
export 'src/components/form/validator_hint/validator_hint_style.dart';
// --- ICON ---
// Icon components.
export 'src/components/icon/icon.dart';
export 'src/components/infra/clickable/clickable.dart';
export 'src/components/infra/clickable/clickable_style.dart'
    show
        ResolvedClickable,
        ResolvedClickableRules,
        ResolvedClickableTiming,
        resolveClickable,
        resolveClickableRules,
        resolveClickableTiming;
export 'src/components/infra/drag_item/drag_item.dart';
export 'src/components/infra/drag_overlay/drag_overlay.dart';
export 'src/components/infra/drag_scope/drag_scope.dart';
export 'src/components/infra/drop_zone/drop_zone.dart';
export 'src/components/infra/focus_outline/focus_outline.dart';
export 'src/components/infra/liquid_morph/liquid_morph_clip.dart';
export 'src/components/infra/outlined_container/outlined_container.dart';
export 'src/components/infra/outlined_container/outlined_container_style.dart'
    show ResolvedOutlinedContainer, resolveOutlinedContainer;
export 'src/components/infra/popup/popup.dart';
export 'src/components/infra/popup/popup_style.dart';
export 'src/components/infra/scrollbar/scrollbar.dart';
export 'src/components/infra/scrollview/scrollview_interceptor.dart';
export 'src/components/infra/subfocus/subfocus.dart';
// --- LAYOUT ---
// Layout components.
export 'src/components/layout/accordion/accordion.dart';
export 'src/components/layout/app_bar/app_bar.dart';
export 'src/components/layout/app_bar/app_bar_style.dart'
    show ResolvedAppBar, resolveAppBar;
export 'src/components/layout/bar_action/bar_action.dart';
export 'src/components/layout/basic/basic.dart';
export 'src/components/layout/basic/basic_style.dart' show ResolvedBasic;
export 'src/components/layout/bottom_action_bar/bottom_action_bar.dart';
export 'src/components/layout/bottom_action_bar/bottom_action_bar_style.dart'
    show ResolvedBottomActionBar, resolveBottomActionBar;
export 'src/components/layout/bottom_sheet/bottom_sheet.dart';
export 'src/components/layout/breakpoint/breakpoint.dart';
export 'src/components/layout/card/card.dart';
export 'src/components/layout/card/card_style.dart'
    show ResolvedCard, resolveCard;
export 'src/components/layout/card_image/card_image.dart';
export 'src/components/layout/card_image/card_image_style.dart'
    show ResolvedCardImage;
export 'src/components/layout/collapsible/collapsible.dart';
export 'src/components/layout/disclosure/disclosure.dart';
export 'src/components/layout/disclosure/disclosure_style.dart';
export 'src/components/layout/dock/dock.dart';
export 'src/components/layout/dock/dock_style.dart'
    show
        ResolvedDock,
        ResolvedDockItem,
        resolveDock,
        resolveDockItem,
        resolveDockSize;
export 'src/components/layout/draggable_panel/draggable_panel.dart';
export 'src/components/layout/fade_scroll/fade_scroll.dart';
export 'src/components/layout/fade_scroll/fade_scroll_style.dart'
    show ResolvedFadeScroll, resolveFadeScroll;
export 'src/components/layout/footer/footer.dart';
export 'src/components/layout/footer/footer_style.dart' show ResolvedFooter;
export 'src/components/layout/frame/frame.dart';
export 'src/components/layout/frame/frame_style.dart'
    show ResolvedFrame, resolveFrame;
export 'src/components/layout/gap/gap.dart';
export 'src/components/layout/gap/max_gap.dart';
export 'src/components/layout/gap/sliver_gap.dart';
export 'src/components/layout/hero/hero.dart';
export 'src/components/layout/hero/hero_style.dart'
    show ResolvedHero, resolveHero;
export 'src/components/layout/hidden/hidden.dart';
export 'src/components/layout/hidden/hidden_style.dart'
    show ResolvedHidden, resolveHidden;
export 'src/components/layout/join/join.dart';
export 'src/components/layout/listing/listing.dart';
export 'src/components/layout/listing/listing_style.dart' show ResolvedListing;
export 'src/components/layout/mask/mask.dart';
export 'src/components/layout/mask/mask_style.dart'
    show ResolvedMask, resolveMask;
export 'src/components/layout/media_query/media_query_style.dart'
    show
        ResolvedMediaQueryVisibility,
        resolveMediaQueryVisibility,
        resolveMediaQueryVisibilityCss;
export 'src/components/layout/media_query/media_query_visibility.dart';
export 'src/components/layout/overflow_marquee/overflow_marquee.dart';
export 'src/components/layout/overflow_marquee/overflow_marquee_style.dart'
    show
        OverflowMarqueeConfig,
        ResolvedOverflowMarquee,
        composeOverflowMarqueeCss,
        resolveOverflowMarquee,
        resolveOverflowMarqueeConfig;
export 'src/components/layout/page_header/page_header.dart';
export 'src/components/layout/page_header/page_header_style.dart'
    show ResolvedPageHeader, resolvePageHeader;
export 'src/components/layout/panel_header/panel_header.dart';
export 'src/components/layout/panel_header/panel_header_style.dart'
    show ResolvedPanelHeader, resolvePanelHeader;
export 'src/components/layout/resizable/resizable.dart';
export 'src/components/layout/resizable/resizable_style.dart';
export 'src/components/layout/responsive_container/responsive_container.dart';
export 'src/components/layout/responsive_container/responsive_container_style.dart'
    show ResolvedResponsiveContainer, resolveResponsiveContainer;
export 'src/components/layout/responsive_grid/grid_item.dart';
export 'src/components/layout/responsive_grid/responsive_grid.dart';
export 'src/components/layout/responsive_grid/responsive_grid_style.dart';
export 'src/components/layout/responsive_row_column/responsive_row_column.dart';
export 'src/components/layout/responsive_row_column/responsive_row_column_style.dart';
export 'src/components/layout/scaffold/scaffold.dart';
export 'src/components/layout/scroll_area/scroll_area.dart';
// Top-level chrome builders for `ScrollArea` are intentionally not
// exported — the chrome composition is closure-local inside
// `resolveScrollArea` per the Phase 16 PoC. The Category C scoped-CSS
// resolver ([resolveScrollAreaCss]) is exported because the widget
// calls it at build time with the runtime scope id (Epic #1603 옵션 B
// 최종 — behavioural/composed data lives on a separate resolver, not on
// the pure-chrome `ResolvedScrollArea`).
export 'src/components/layout/scroll_area/scroll_area_style.dart'
    show ResolvedScrollArea, resolveScrollArea;
export 'src/components/layout/scrollable_client/scrollable_client.dart';
export 'src/components/layout/scrollable_client/scrollable_client_style.dart';
export 'src/components/layout/stacks/stacks.dart';
export 'src/components/layout/stage_container/stage_container.dart';
export 'src/components/layout/step_item/step_item.dart';
export 'src/components/layout/stepper/stepper.dart';
export 'src/components/layout/steps/steps.dart';
export 'src/components/layout/swipe_actions/swipe_action_scope.dart';
export 'src/components/layout/swipe_actions/swipe_actions.dart';
export 'src/components/layout/swipe_actions/swipe_actions_style.dart';
export 'src/components/layout/table/resizable_table.dart';
export 'src/components/layout/table/resizable_table_controller.dart';
export 'src/components/layout/table/table.dart';
export 'src/components/layout/table/table_style.dart'
    show coreTableSizeToCssTrack;
export 'src/components/layout/toolbar_group/toolbar_group.dart';
export 'src/components/layout/tree/tree.dart';
export 'src/components/layout/window/window.dart';
export 'src/components/layout/window_panel/window_panel.dart';
// --- LOCALE ---
// Localization components.
export 'src/components/locale/coui_localizations/ar_coui_localizations.dart';
export 'src/components/locale/coui_localizations/coui_localizations.dart';
export 'src/components/locale/coui_localizations/coui_localizations_scope.dart';
export 'src/components/locale/coui_localizations/de_coui_localizations.dart';
export 'src/components/locale/coui_localizations/es_coui_localizations.dart';
export 'src/components/locale/coui_localizations/fr_coui_localizations.dart';
export 'src/components/locale/coui_localizations/it_coui_localizations.dart';
export 'src/components/locale/coui_localizations/ja_coui_localizations.dart';
export 'src/components/locale/coui_localizations/ko_coui_localizations.dart';
export 'src/components/locale/coui_localizations/pt_coui_localizations.dart';
export 'src/components/locale/coui_localizations/ru_coui_localizations.dart';
export 'src/components/locale/coui_localizations/zh_hans_coui_localizations.dart';
// --- MENU ---
// Menu and dropdown components.
export 'src/components/menu/context_menu/context_menu.dart';
export 'src/components/menu/context_menu/context_menu_style.dart';
export 'src/components/menu/dropdown_menu/dropdown_menu.dart';
export 'src/components/menu/dropdown_menu/dropdown_menu_style.dart';
export 'src/components/menu/menu/menu.dart';
export 'src/components/menu/menu_item/menu_item.dart';
export 'src/components/menu/menu_item/menu_item_style.dart';
export 'src/components/menu/menubar/menubar.dart';
export 'src/components/menu/menubar/menubar_style.dart';
export 'src/components/menu/navigation_menu/navigation_menu.dart';
export 'src/components/menu/navigation_menu/navigation_menu_style.dart';
// --- NAVIGATION ---
// Navigation components.
export 'src/components/navigation/breadcrumb/breadcrumb.dart';
export 'src/components/navigation/indexed_switcher/indexed_switcher.dart';
export 'src/components/navigation/indexed_switcher/indexed_switcher_style.dart'
    show ResolvedIndexedSwitcher, resolveIndexedSwitcher;
export 'src/components/navigation/navigation_bar/navigation_bar.dart';
export 'src/components/navigation/pagination/pagination.dart';
export 'src/components/navigation/sidebar/sidebar.dart';
export 'src/components/navigation/sidebar/sidebar_style.dart'
    show ResolvedSidebar, resolveSidebar;
export 'src/components/navigation/sidebar_group/sidebar_group.dart';
export 'src/components/navigation/sidebar_group/sidebar_group_style.dart'
    show ResolvedSidebarGroup, resolveSidebarGroup;
export 'src/components/navigation/sidebar_header/sidebar_header.dart';
export 'src/components/navigation/sidebar_header/sidebar_header_style.dart'
    show ResolvedSidebarHeader, resolveSidebarHeader;
export 'src/components/navigation/sidebar_item/sidebar_item.dart';
export 'src/components/navigation/sidebar_item/sidebar_item_style.dart'
    show ResolvedSidebarItem, resolveSidebarItem;
export 'src/components/navigation/sidebar_rail_item/sidebar_rail_item.dart';
export 'src/components/navigation/sidebar_rail_item/sidebar_rail_item_style.dart'
    show ResolvedSidebarRailItem, resolveSidebarRailItem;
export 'src/components/navigation/sidebar_search/sidebar_search.dart';
export 'src/components/navigation/sidebar_search/sidebar_search_style.dart'
    show ResolvedSidebarSearch, resolveSidebarSearch;
export 'src/components/navigation/sidebar_section/sidebar_section.dart';
export 'src/components/navigation/sidebar_section/sidebar_section_style.dart'
    show ResolvedSidebarSection, resolveSidebarSection;
export 'src/components/navigation/switcher/switcher.dart';
export 'src/components/navigation/switcher/switcher_style.dart'
    show ResolvedSwitcher, resolveSwitcher;
export 'src/components/navigation/tabs/tab_pane.dart';
export 'src/components/navigation/tabs/tabs.dart';
// --- OVERLAY ---
// Overlay components.
export 'src/components/overlay/alert/alert.dart';
export 'src/components/overlay/alert/alert_style.dart'
    show ResolvedAlert, resolveAlert;
export 'src/components/overlay/dialog/dialog.dart';
export 'src/components/overlay/drawer/drawer.dart';
export 'src/components/overlay/drawer/drawer_style.dart'
    show
        ResolvedDrawer,
        ResolvedDrawerBackdropRuntime,
        ResolvedDrawerTiming,
        resolveDrawer,
        resolveDrawerBackdropRuntime,
        resolveDrawerTiming;
export 'src/components/overlay/hover_card/hover_card.dart';
export 'src/components/overlay/hover_card/hover_card_style.dart'
    show ResolvedHoverCard, resolveHoverCard;
export 'src/components/overlay/popover/popover.dart';
export 'src/components/overlay/popover/popover_controller.dart';
// SSR-safe global keyboard-shortcut registration (`Cmd+K` / `Ctrl+K` style) —
// the same conditional stub/web split `Dialog`/`Menubar`/`NavigationMenu`
// already use internally for Escape-to-close, exposed for host apps that
// build their own command palette on top of `Command` (docs_site's global
// search, #3577).
export 'src/components/overlay/popover/popover_dom.dart'
    show registerDocumentShortcutListener;
export 'src/components/overlay/popover/popover_style.dart'
    show ResolvedPopover, resolvePopover;
export 'src/components/overlay/refresh_trigger/refresh_trigger.dart';
export 'src/components/overlay/refresh_trigger/refresh_trigger_style.dart'
    show ResolvedRefreshTrigger, resolveRefreshTrigger;
export 'src/components/overlay/swiper/swiper.dart';
export 'src/components/overlay/toast/toast.dart';
export 'src/components/overlay/tooltip/tooltip.dart';
export 'src/components/overlay/tooltip/tooltip_style.dart'
    show
        ResolvedTooltip,
        ResolvedTooltipTiming,
        resolveTooltip,
        resolveTooltipTiming;
// --- TEXT ---
// Text components.
export 'src/components/text/definition_list/definition_list.dart';
export 'src/components/text/definition_list/definition_list_style.dart'
    show ResolvedDefinitionList, resolveDefinitionList;
export 'src/components/text/font_style.dart';
export 'src/components/text/link/link.dart';
export 'src/components/text/link/link_style.dart' show ResolvedLink;
export 'src/components/text/selectable/selectable_style.dart'
    show ResolvedSelectableText, resolveSelectableText;
export 'src/components/text/selectable/selectable_text.dart';
export 'src/components/text/text.dart';
export 'src/components/text/text_block/text_block.dart';
export 'src/components/text/text_block/text_block_style.dart'
    show ResolvedTextBlock, TextBlockStyle, resolveTextBlock;
export 'src/components/text/text_extension.dart';
// --- APP ---.
// CoUI Web application wrapper.
export 'src/coui_web.dart';
// --- ELEMENTS ---.
// Generic HTML element wrappers like Figure.
// --- OVERLAY INFRASTRUCTURE ---.
// Root portal mount-point used by floating components (popover /
// tooltip / menu / hover-card / dropdown-menu) so their panels leave
// the trigger's ancestors' `overflow: hidden` / `transform`, and are
// promoted into the browser top layer so the host's own ancestors
// (a client island is hosted wherever it hydrates) cannot displace them
// either. Mirrors Flutter `Overlay` + `OverlayManagerLayer`.
export 'src/overlay/overlay_controller.dart';
export 'src/overlay/overlay_host.dart';
export 'src/overlay/overlay_portal.dart';
export 'src/overlay/positioning/positioning.dart';
export 'src/overlay/recent_colors_scope.dart';
// Opt-in for a panel an app mounts through `OverlayController` itself.
export 'src/overlay/top_layer.dart' show TopLayer, kTopLayerPanelAttribute;
// --- THEME ---.
// Theme system: ColorScheme tokens, ThemeData, and InheritedComponent provider.
export 'src/page/page_transition_style.dart'
    show ResolvedPageTransitionRules, resolvePageTransitionRules;
export 'src/theme/color_scheme.dart';
export 'src/theme/coui_theme.dart';
export 'src/theme/icon_theme.dart';
export 'src/theme/theme_context.dart';
export 'src/theme/theme_data.dart';
// --- UTIL ---
// Conversion extensions from CoUI core types to CSS strings.
export 'src/util/co_file_saver.dart';
export 'src/util/core_to_css.dart' hide measuredLengthCss;
export 'src/util/web_constants.dart';
