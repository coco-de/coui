import 'package:coui_flutter/coui_flutter.dart';

import 'examples/flutter/component_examples.dart';
import '../internal/preview/scenes.dart';
import '../internal/preview/flutter_scene.dart';
import '../internal/preview/scene_unavailable.dart' if (dart.library.io) '../internal/preview/scene_file.dart';

/// Builder function that creates a Flutter widget preview.
typedef FlutterPreviewBuilder = Widget Function(String? variant);

/// Registry of Flutter preview builders for all documented components.
///
/// Each entry maps a component name to a builder function that takes
/// an optional variant and returns a Flutter Widget.
final Map<String, FlutterPreviewBuilder> kFlutterPreviewRegistry = {
  for (final entry in _kFlutterComponentBuilders.entries)
    entry.key: (variant) {
      if (variant != null && variant.startsWith(docsScenePrefix)) {
        return renderFlutterScene(resolveDocsScene(entry.key, variant));
      }
      return entry.value(variant);
    },
};

final Map<String, FlutterPreviewBuilder> _kFlutterComponentBuilders = {
  'form-field': _formFieldPreview,
  'formatter': _formatterPreview,
  'scrollview': _scrollviewPreview,
  'clickable': _clickablePreview,
  'focus-outline': _focusOutlinePreview,
  'outlined-container': _outlinedContainerPreview,
  'subfocus': _subfocusPreview,
  'form-label': _formLabelPreview,
  'validated': _validatedPreview,
  'validator-hint': _validatorHintPreview,
  'aspect-ratio-box': _aspectRatioBoxPreview,
  'text-block': _textBlockPreview,
  'button': _buttonPreview,
  'text-field': _inputPreview,
  'checkbox': _checkboxPreview,
  'toggle': _togglePreview,
  'slider': _sliderPreview,
  'badge': _badgePreview,
  'tag': _tagPreview,
  'sidebar': _sidebarPreview,
  'avatar': _avatarPreview,
  'card': _cardPreview,
  'card-image': _cardImagePreview,
  'alert': _alertPreview,
  'progress': _progressPreview,
  'toast': _toastPreview,
  'breadcrumb': _breadcrumbPreview,
  'tabs': _tabsPreview,
  'tab-pane': _tabPanePreview,
  'pagination': _paginationPreview,
  'dialog': _dialogPreview,
  'draggable-panel': _draggablePanelPreview,
  'tooltip': _tooltipPreview,
  'accordion': _accordionPreview,
  'select': _selectPreview,
  'radio-group': _radioPreview,
  'table': _tablePreview,
  // Phase 1: Simple components (24)
  'divider': _dividerPreview,
  'scrollable-client': _scrollableClientPreview,
  'stack-layout': _stackLayoutPreview,
  'stage-container': _stageContainerPreview,
  'window': _windowPreview,
  'window-panel': _windowPanelPreview,
  'gap': _gapPreview,
  'validation-badge': _validationBadgePreview,
  'definition-list': _definitionListPreview,
  'disclosure-badge': _disclosureBadgePreview,
  'kbd': _kbdPreview,
  'label': _labelPreview,
  'link': _linkPreview,
  'chip': _chipPreview,
  'chip-group': _chipGroupPreview,
  'code-diff': _codeDiffPreview,
  'diff': _diffPreview,
  'loading': _loadingPreview,
  'scroll-area': _scrollAreaPreview,
  'scrollbar': _scrollbarPreview,
  'skeleton': _skeletonPreview,
  'loading-region': _loadingRegionPreview,
  'dot-indicator': _dotIndicatorPreview,
  'status': _statusPreview,
  'stat': _statPreview,
  'description-card': _descriptionCardPreview,
  'empty-state': _emptyStatePreview,
  'fade-scroll': _fadeScrollPreview,
  'banner': _bannerPreview,
  'countdown': _countdownPreview,
  'number-ticker': _numberTickerPreview,
  'overflow-marquee': _overflowMarqueePreview,
  'responsive-container': _responsiveContainerPreview,
  'responsive-grid': _responsiveGridPreview,
  'responsive-row-column': _responsiveRowColumnPreview,
  'steps': _stepsPreview,
  'step-item': _stepItemPreview,
  'timeline': _timelinePreview,
  'collapsible': _collapsiblePreview,
  'disclosure': _disclosurePreview,
  'join': _joinPreview,
  'basic': _basicPreview,
  'dock': _dockPreview,
  'footer': _footerPreview,
  'frame': _framePreview,
  'hero': _heroSectionPreview,
  'hidden': _hiddenPreview,
  'listing': _listingPreview,
  'swipe-actions': _swipeActionsPreview,
  'fab': _fabPreview,
  'swap': _swapPreview,
  'tracker': _trackerPreview,
  'category-breakdown': _categoryBreakdownPreview,
  'trend-chart': _trendChartPreview,
  // Phase 2: Medium components (22)
  'text-area': _textAreaPreview,
  'rich-editor': _richEditorPreview,
  'switch-field': _switchFieldPreview,
  'star-rating': _starRatingPreview,
  'range': _rangePreview,
  'item-picker': _itemPickerPreview,
  'multi-answer-card': _multiAnswerCardPreview,
  'formatted-input': _formattedInputPreview,
  'number-input': _numberInputPreview,
  'object-input': _objectInputPreview,
  'chip-input': _chipInputPreview,
  'input-otp': _inputOtpPreview,
  'fieldset': _fieldsetPreview,
  'form': _formPreview,
  'autocomplete': _autocompletePreview,
  'phone-input': _phoneInputPreview,
  'file-input': _fileInputPreview,
  'filter': _filterPreview,
  'toggle-group': _toggleGroupPreview,
  'stepper': _stepperPreview,
  'popover': _popoverPreview,
  'popup': _popupPreview,
  'drawer': _drawerPreview,
  'hover': _hoverPreview,
  'hover-card': _hoverCardPreview,
  'context-menu': _contextMenuPreview,
  'dropdown-menu': _dropdownMenuPreview,
  'menu': _menuPreview,
  'menu-item': _menuItemPreview,
  'menubar': _menubarPreview,
  'toolbar-group': _toolbarGroupPreview,
  'navigation-menu': _navigationMenuPreview,
  'multiple-choice': _multipleChoicePreview,
  'navigation-bar': _navigationBarPreview,
  'navigation-bar-item': _navigationBarItemPreview,
  'scaffold': _scaffoldPreview,
  'app-bar': _appBarPreview,
  'theme-controller': _themeControllerPreview,
  'switcher': _switcherPreview,
  'indexed-switcher': _indexedSwitcherPreview,
  'drag': _dragPreview,
  'sortable': _sortablePreview,
  // Phase 3: Complex components (15)
  'calendar': _calendarPreview,
  'date-picker': _datePickerPreview,
  'time-picker': _timePickerPreview,
  'color-picker': _colorPickerPreview,
  'carousel': _carouselPreview,
  'carousel-banner': _carouselBannerPreview,
  'chat': _chatPreview,
  'code-snippet': _codeSnippetPreview,
  'resizable': _resizablePreview,
  'mask': _maskPreview,
  'media-query': _mediaQueryPreview,
  'mockup': _mockupPreview,
  'mockup-browser': _mockupBrowserPreview,
  'mockup-code': _mockupCodePreview,
  'mockup-device': _mockupDevicePreview,
  'mockup-foldable': _mockupFoldablePreview,
  'hover-gallery': _hoverGalleryPreview,
  'refresh-trigger': _refreshTriggerPreview,
  'swiper': _swiperPreview,
  'tree': _treePreview,
  'command': _commandPreview,
  'command-search': _commandSearchPreview,
  'page-header': _pageHeaderPreview,
  'panel-header': _panelHeaderPreview,
  'bottom-action-bar': _bottomActionBarPreview,
  'option-item': _optionItemPreview,
  'option-list': _optionListPreview,
  'bottom-sheet': _bottomSheetPreview,
  'text': _textPreview,
  'selectable-text': _selectableTextPreview,
  'icon': _iconPreview,
  'indicator': _indicatorPreview,
  'breakpoint': _breakpointPreview,
};

// ---------------------------------------------------------------------------
// Button
// ---------------------------------------------------------------------------

Widget _buttonPreview(String? variant) {
  return switch (variant) {
    'chain' => const ButtonChainExample(),
    'primary' => const ButtonPrimaryExample(),
    'secondary' => const ButtonSecondaryExample(),
    'tonal' => const ButtonTonalExample(),
    'outline' => const ButtonOutlineExample(),
    'ghost' => const ButtonGhostExample(),
    'destructive' => const ButtonDestructiveExample(),
    'plain' => const ButtonPlainExample(),
    'card' => const ButtonCardExample(),
    'cast-motion' => const ButtonCastMotionExample(),
    _ => const ButtonPrimaryExample(),
  };
}

// ---------------------------------------------------------------------------
// TextField
// ---------------------------------------------------------------------------

Widget _inputPreview(String? variant) {
  return switch (variant) {
    'chain' => const TextFieldChainExample(),
    'error' => const TextFieldErrorExample(),
    _ => const TextFieldDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Checkbox
// ---------------------------------------------------------------------------

Widget _checkboxPreview(String? variant) {
  return switch (variant) {
    'chain' => const CheckboxChainExample(),
    'checked' => const CheckboxCheckedExample(),
    'indeterminate' => const CheckboxIndeterminateExample(),
    'disabled' => const CheckboxDisabledExample(),
    _ => const CheckboxDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Toggle
// ---------------------------------------------------------------------------

Widget _togglePreview(String? variant) {
  return switch (variant) {
    'chain' => const ToggleChainExample(),
    'on' => const ToggleOnExample(),
    'disabled' => const ToggleDisabledExample(),
    _ => const ToggleDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Slider
// ---------------------------------------------------------------------------

Widget _sliderPreview(String? variant) {
  return switch (variant) {
    'chain' => const SliderChainExample(),
    'disabled' => const SliderDisabledExample(),
    _ => const SliderDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

Widget _badgePreview(String? variant) {
  return switch (variant) {
    'tones' => const BadgeTonesExample(),
    'variants' => const BadgeVariantsExample(),
    'status' => const BadgeStatusExample(),
    'count' => const BadgeCountExample(),
    'dot' => const BadgeDotExample(),
    'chain' => const BadgeChainExample(),
    _ => const BadgeDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

Widget _sidebarPreview(String? variant) {
  return switch (variant) {
    'two-pane' => const SidebarTwoPaneExample(),
    'chain' => const SidebarChainExample(),
    'collapsed' => const SidebarCollapsedExample(),
    _ => const SidebarDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tag
// ---------------------------------------------------------------------------

Widget _tagPreview(String? variant) {
  return switch (variant) {
    'colors' => const TagColorsExample(),
    'bold' => const TagBoldExample(),
    'sizes' => const TagSizesExample(),
    'chain' => const TagChainExample(),
    _ => const TagDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

Widget _avatarPreview(String? variant) {
  return switch (variant) {
    'chain' => const AvatarChainExample(),
    'diameter' => const AvatarDiameterExample(),
    'initials' => const AvatarInitialsExample(),
    'placeholder' => const AvatarPlaceholderExample(),
    'rounded' => const AvatarRoundedExample(),
    _ => const AvatarDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

Widget _cardPreview(String? variant) {
  return switch (variant) {
    'chain' => const CardChainExample(),
    'filled' => const CardFilledExample(),
    'elevated' => const CardElevatedExample(),
    _ => const CardDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// CardImage
// ---------------------------------------------------------------------------

Widget _cardImagePreview(String? variant) {
  return switch (variant) {
    'chain' => const CardImageChainExample(),
    _ => const CardImageDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Alert
// ---------------------------------------------------------------------------

Widget _alertPreview(String? variant) {
  return switch (variant) {
    'info' => const AlertInfoExample(),
    'inline' => const AlertInlineExample(),
    'success' => const AlertSuccessExample(),
    'warning' => const AlertWarningExample(),
    'destructive' => const AlertDestructiveExample(),
    'text-only' => const AlertTextOnlyExample(),
    'chain' => const AlertChainExample(),
    _ => const AlertDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

Widget _progressPreview(String? variant) {
  return switch (variant) {
    'chain' => const ProgressChainExample(),
    'indeterminate' => const ProgressIndeterminateExample(),
    'radial' => const ProgressRadialExample(),
    'tone' => const ProgressToneExample(),
    'labelled' => const ProgressLabelledExample(),
    'segments' => const ProgressSegmentsExample(),
    _ => const ProgressDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Toast
// ---------------------------------------------------------------------------

Widget _toastPreview(String? variant) {
  return switch (variant) {
    'chain' => const ToastChainExample(),
    'destructive' => const ToastDestructiveExample(),
    'no-icon' => const ToastNoIconExample(),
    _ => const ToastDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Breadcrumb
// ---------------------------------------------------------------------------

Widget _breadcrumbPreview(String? variant) {
  return switch (variant) {
    'chain' => const BreadcrumbChainExample(),
    _ => const BreadcrumbDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tabs — variants: default (pill Tabs), line (underline Tabs), badge
// (a `CoreTabItem.badge` count on one tab).
// ---------------------------------------------------------------------------

Widget _tabsPreview(String? variant) {
  return switch (variant) {
    'badge' => const TabsBadgeExample(),
    'closable' => const TabsClosableExample(),
    'chain' => const TabsChainExample(),
    'line' => const TabsLineExample(),
    _ => const TabsDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// TabPane — boxed tab strip with self-contained content panels.
// ---------------------------------------------------------------------------

Widget _tabPanePreview(String? variant) {
  return switch (variant) {
    'chain' => const TabPaneChainExample(),
    'editor-strip' => const TabPaneEditorStripExample(),
    _ => const TabPaneExample(),
  };
}

// ---------------------------------------------------------------------------
// Pagination — Uses a stateful wrapper.
// ---------------------------------------------------------------------------

Widget _paginationPreview(String? variant) {
  return switch (variant) {
    'chain' => const PaginationChainExample(),
    _ => const PaginationDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Dialog — Static content preview (showDialog requires BuildContext).
// ---------------------------------------------------------------------------

Widget _dialogPreview(String? variant) {
  return switch (variant) {
    'chain' => const DialogChainExample(),
    'stretch' => const DialogStretchExample(),
    _ => const DialogDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DraggablePanel
// ---------------------------------------------------------------------------

Widget _draggablePanelPreview(String? variant) {
  return switch (variant) {
    'chain' => const DraggablePanelChainExample(),
    'outside' => const DraggablePanelOutsideExample(),
    _ => const DraggablePanelDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tooltip
// ---------------------------------------------------------------------------

Widget _tooltipPreview(String? variant) {
  return switch (variant) {
    'chain' => const TooltipChainExample(),
    _ => const TooltipDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Accordion
// ---------------------------------------------------------------------------

Widget _accordionPreview(String? variant) {
  return switch (variant) {
    'chain' => const AccordionChainExample(),
    _ => const AccordionDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Select
// ---------------------------------------------------------------------------

Widget _selectPreview(String? variant) {
  return switch (variant) {
    'chain' => const SelectChainExample(),
    'suffix' => const SelectSuffixExample(),
    _ => const SelectDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Radio
// ---------------------------------------------------------------------------

Widget _radioPreview(String? variant) {
  return switch (variant) {
    'chain' => const RadioGroupChainExample(),
    'card' => const RadioGroupCardExample(),
    _ => const RadioGroupDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Phase 1: Simple Components (24)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

Widget _dividerPreview(String? variant) {
  return switch (variant) {
    'chain' => const DividerChainExample(),
    'vertical' => const DividerVerticalExample(),
    'with-child' => const DividerWithChildExample(),
    _ => const DividerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// ScrollableClient
// ---------------------------------------------------------------------------

Widget _scrollableClientPreview(String? variant) {
  return const ScrollableClientDefaultExample();
}

// ---------------------------------------------------------------------------
// StackLayout
// ---------------------------------------------------------------------------

Widget _stackLayoutPreview(String? variant) {
  return const StackLayoutDefaultExample();
}

// ---------------------------------------------------------------------------
// StageContainer
// ---------------------------------------------------------------------------

Widget _stageContainerPreview(String? variant) {
  return switch (variant) {
    'chain' => const StageContainerChainExample(),
    _ => const StageContainerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Window (multi-window manager)
// ---------------------------------------------------------------------------

Widget _windowPreview(String? variant) {
  return switch (variant) {
    'chain' => const WindowChainExample(),
    _ => const WindowDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// WindowPanel
// ---------------------------------------------------------------------------

Widget _windowPanelPreview(String? variant) {
  return switch (variant) {
    'chain' => const WindowPanelChainExample(),
    _ => const WindowPanelDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Gap
// ---------------------------------------------------------------------------

Widget _gapPreview(String? variant) {
  return switch (variant) {
    'chain' => const GapChainExample(),
    'max' => const GapMaxExample(),
    'sliver' => const GapSliverExample(),
    _ => const GapDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// ValidationBadge
// ---------------------------------------------------------------------------

Widget _validationBadgePreview(String? variant) {
  return switch (variant) {
    'chain' => const ValidationBadgeChainExample(),
    'pending' => const ValidationBadgePendingExample(),
    'invalid' => const ValidationBadgeInvalidExample(),
    'medium' => const ValidationBadgeMediumExample(),
    _ => const ValidationBadgeDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DefinitionList
// ---------------------------------------------------------------------------

Widget _definitionListPreview(String? variant) {
  return switch (variant) {
    'chain' => const DefinitionListChainExample(),
    'columns' => const DefinitionListColumnsExample(),
    'inline' => const DefinitionListInlineExample(),
    _ => const DefinitionListDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DisclosureBadge
// ---------------------------------------------------------------------------

Widget _disclosureBadgePreview(String? variant) {
  return switch (variant) {
    'chain' => const DisclosureBadgeChainExample(),
    'commitment' => const DisclosureBadgeCommitmentExample(),
    'private' => const DisclosureBadgePrivateExample(),
    _ => const DisclosureBadgeDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Kbd
// ---------------------------------------------------------------------------

Widget _kbdPreview(String? variant) {
  return switch (variant) {
    'chain' => const KbdChainExample(),
    'combo' => const KbdComboExample(),
    'single' => const KbdSingleExample(),
    'four' => const KbdFourExample(),
    _ => const KbdDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Label
// ---------------------------------------------------------------------------

Widget _labelPreview(String? variant) {
  return switch (variant) {
    'chain' => const LabelChainExample(),
    'required' => const LabelRequiredExample(),
    'with-icon' => const LabelWithIconExample(),
    'disabled' => const LabelDisabledExample(),
    _ => const LabelDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Link
// ---------------------------------------------------------------------------

Widget _linkPreview(String? variant) {
  return switch (variant) {
    'chain' => const LinkChainExample(),
    'external' => const LinkExternalExample(),
    'icons' => const LinkIconsExample(),
    'muted' => const LinkMutedExample(),
    'underline' => const LinkUnderlineExample(),
    _ => const LinkDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Chip
// ---------------------------------------------------------------------------

Widget _chipPreview(String? variant) {
  return switch (variant) {
    'chain' => const ChipChainExample(),
    'selected' => const ChipSelectedExample(),
    'variant' => const ChipVariantExample(),
    'shape' => const ChipShapeExample(),
    'disabled' => const ChipDisabledExample(),
    'removable' => const ChipRemovableExample(),
    'cast-motion' => const ChipCastMotionExample(),
    'prefix' => const ChipPrefixExample(),
    _ => const ChipDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// ChipGroup
// ---------------------------------------------------------------------------

Widget _chipGroupPreview(String? variant) {
  return switch (variant) {
    'chain' => const ChipGroupChainExample(),
    'scroll' => const ChipGroupScrollExample(),
    _ => const ChipGroupDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// CodeDiff
// ---------------------------------------------------------------------------

Widget _codeDiffPreview(String? variant) {
  return switch (variant) {
    'chain' => const CodeDiffChainExample(),
    _ => const CodeDiffDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Diff
// ---------------------------------------------------------------------------

Widget _diffPreview(String? variant) {
  return switch (variant) {
    'chain' => const DiffChainExample(),
    'text' => const DiffTextExample(),
    _ => const DiffDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

Widget _loadingPreview(String? variant) {
  return switch (variant) {
    'chain' => const LoadingChainExample(),
    'dots' => const LoadingDotsExample(),
    'bar' => const LoadingBarExample(),
    'pulse' => const LoadingPulseExample(),
    _ => const LoadingDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------

Widget _scrollAreaPreview(String? variant) {
  return switch (variant) {
    'chain' => const ScrollAreaChainExample(),
    _ => const ScrollAreaDefaultExample(),
  };
}

Widget _scrollbarPreview(String? variant) {
  return switch (variant) {
    'chain' => const ScrollbarChainExample(),
    _ => const ScrollbarDefaultExample(),
  };
}

Widget _skeletonPreview(String? variant) {
  return switch (variant) {
    'chain' => const SkeletonChainExample(),
    'circle' => const SkeletonCircleExample(),
    'text' => const SkeletonTextExample(),
    _ => const SkeletonDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// LoadingRegion
// ---------------------------------------------------------------------------

Widget _loadingRegionPreview(String? variant) {
  return switch (variant) {
    _ => const LoadingRegionDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DotIndicator
// ---------------------------------------------------------------------------

Widget _dotIndicatorPreview(String? variant) {
  return switch (variant) {
    'vertical' => const DotIndicatorVerticalExample(),
    'passive' => const DotIndicatorPassiveExample(),
    'chain' => const DotIndicatorChainExample(),
    _ => const DotIndicatorDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

Widget _statusPreview(String? variant) {
  return switch (variant) {
    'chain' => const StatusChainExample(),
    'success' => const StatusSuccessExample(),
    'warning' => const StatusWarningExample(),
    'error' => const StatusErrorExample(),
    _ => const StatusDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Stat
// ---------------------------------------------------------------------------

Widget _statPreview(String? variant) {
  return switch (variant) {
    'outlined' => const StatOutlinedExample(),
    'empty' => const StatEmptyExample(),
    'chain' => const StatChainExample(),
    _ => const StatDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// EmptyState
// ---------------------------------------------------------------------------

Widget _emptyStatePreview(String? variant) {
  return switch (variant) {
    'chain' => const EmptyStateChainExample(),
    'normal' => const EmptyStateNormalExample(),
    'failure' => const EmptyStateFailureExample(),
    'large' => const EmptyStateLargeExample(),
    'success' => const EmptyStateSuccessExample(),
    _ => const EmptyStateDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// FadeScroll
// ---------------------------------------------------------------------------

Widget _fadeScrollPreview(String? variant) {
  return switch (variant) {
    'chain' => const FadeScrollChainExample(),
    'horizontal' => const FadeScrollHorizontalExample(),
    'with-scrollbar' => const FadeScrollWithScrollbarExample(),
    _ => const FadeScrollDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Banner (Banner — unified)
// ---------------------------------------------------------------------------

Widget _bannerPreview(String? variant) {
  return switch (variant) {
    'chain' => const BannerChainExample(),
    'info' => const BannerInfoExample(),
    'narrow' => const BannerNarrowExample(),
    'success' => const BannerSuccessExample(),
    'warning' => const BannerWarningExample(),
    'destructive' => const BannerDestructiveExample(),
    'solid' => const BannerSolidExample(),
    _ => const BannerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

Widget _countdownPreview(String? variant) {
  return switch (variant) {
    'chain' => const CountdownChainExample(),
    _ => const CountdownDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// NumberTicker
// ---------------------------------------------------------------------------

Widget _numberTickerPreview(String? variant) {
  return switch (variant) {
    'chain' => const NumberTickerChainExample(),
    _ => const NumberTickerDefaultExample(),
  };
}

Widget _overflowMarqueePreview(String? variant) {
  return switch (variant) {
    'chain' => const OverflowMarqueeChainExample(),
    _ => const OverflowMarqueeDefaultExample(),
  };
}

Widget _responsiveContainerPreview(String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveContainerChainExample(),
    _ => const ResponsiveContainerDefaultExample(),
  };
}

Widget _responsiveGridPreview(String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveGridChainExample(),
    'span' => const ResponsiveGridSpanExample(),
    _ => const ResponsiveGridDefaultExample(),
  };
}

Widget _responsiveRowColumnPreview(String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveRowColumnChainExample(),
    'desktop' => const ResponsiveRowColumnDesktopExample(),
    _ => const ResponsiveRowColumnDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

Widget _stepsPreview(String? variant) {
  return switch (variant) {
    'chain' => const StepsChainExample(),
    'horizontal' => const StepsHorizontalExample(),
    'list' => const StepsListExample(),
    _ => const StepsDefaultExample(),
  };
}

Widget _stepItemPreview(String? variant) {
  return switch (variant) {
    'chain' => const StepItemChainExample(),
    _ => const StepItemDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

Widget _timelinePreview(String? variant) {
  return switch (variant) {
    'chain' => const TimelineChainExample(),
    _ => const TimelineDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Collapsible
// ---------------------------------------------------------------------------

Widget _collapsiblePreview(String? variant) {
  return switch (variant) {
    'chain' => const CollapsibleChainExample(),
    _ => const CollapsibleDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Disclosure
// ---------------------------------------------------------------------------

Widget _disclosurePreview(String? variant) {
  return switch (variant) {
    'group' => const DisclosureGroupExample(),
    'chain' => const DisclosureChainExample(),
    _ => const DisclosureDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Join
// ---------------------------------------------------------------------------

Widget _joinPreview(String? variant) {
  return switch (variant) {
    'chain' => const JoinChainExample(),
    'input' => const JoinInputExample(),
    'vertical' => const JoinVerticalExample(),
    _ => const JoinDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Basic (slot layout)
// ---------------------------------------------------------------------------

Widget _basicPreview(String? variant) {
  return switch (variant) {
    'chain' => const BasicChainExample(),
    _ => const BasicDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Dock
// ---------------------------------------------------------------------------

Widget _dockPreview(String? variant) {
  return switch (variant) {
    'chain' => const DockChainExample(),
    _ => const DockDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

Widget _footerPreview(String? variant) {
  return switch (variant) {
    'chain' => const FooterChainExample(),
    'vertical' => const FooterVerticalExample(),
    'center' => const FooterCenterExample(),
    'legal' => const FooterLegalExample(),
    'divider' => const FooterDividerExample(),
    _ => const FooterDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Frame
// ---------------------------------------------------------------------------

Widget _framePreview(String? variant) {
  return switch (variant) {
    'chain' => const FrameChainExample(),
    'column' => const FrameColumnExample(),
    'dashed' => const FrameDashedExample(),
    'elevated' => const FrameElevatedExample(),
    _ => const FrameDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Group
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// HeroSection
// ---------------------------------------------------------------------------

Widget _heroSectionPreview(String? variant) {
  return switch (variant) {
    'split' => const HeroSectionSplitExample(),
    'appear' => const HeroSectionAppearExample(),
    'chain' => const HeroSectionChainExample(),
    _ => const HeroSectionDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Hidden
// ---------------------------------------------------------------------------

Widget _hiddenPreview(String? variant) {
  return const HiddenDefaultExample();
}

// ---------------------------------------------------------------------------
// Listing
// ---------------------------------------------------------------------------

Widget _listingPreview(String? variant) {
  return switch (variant) {
    'chain' => const ListingChainExample(),
    _ => const ListingDefaultExample(),
  };
}

Widget _swipeActionsPreview(String? variant) {
  return switch (variant) {
    'chain' => const SwipeActionsChainExample(),
    'scope' => const SwipeActionsScopeExample(),
    _ => const SwipeActionsDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// FAB
// ---------------------------------------------------------------------------

Widget _fabPreview(String? variant) {
  return switch (variant) {
    'chain' => const FabChainExample(),
    _ => const FabDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Swap
// ---------------------------------------------------------------------------

Widget _swapPreview(String? variant) {
  return switch (variant) {
    'chain' => const SwapChainExample(),
    'rotate' => const SwapRotateExample(),
    'flip' => const SwapFlipExample(),
    _ => const SwapDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tracker
// ---------------------------------------------------------------------------

Widget _trackerPreview(String? variant) {
  return switch (variant) {
    'chain' => const TrackerChainExample(),
    _ => const TrackerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// CategoryBreakdown
// ---------------------------------------------------------------------------

Widget _categoryBreakdownPreview(String? variant) {
  return switch (variant) {
    'donut' => const CategoryBreakdownDonutExample(),
    'chain' => const CategoryBreakdownChainExample(),
    _ => const CategoryBreakdownDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// TrendChart
// ---------------------------------------------------------------------------

Widget _trendChartPreview(String? variant) {
  return switch (variant) {
    'bar' => const TrendChartBarExample(),
    'chain' => const TrendChartChainExample(),
    _ => const TrendChartDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Table (existing)
// ---------------------------------------------------------------------------

Widget _tablePreview(String? variant) {
  return switch (variant) {
    'chain' => const TableChainExample(),
    'resizable' => const TableResizableExample(),
    'scrollable' => const TableScrollableExample(),
    _ => const TableDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Phase 2: Medium Components (22)
// ---------------------------------------------------------------------------

Widget _textAreaPreview(String? variant) {
  return switch (variant) {
    'chain' => const TextAreaChainExample(),
    'footer' => const TextAreaFooterExample(),
    _ => const TextAreaDefaultExample(),
  };
}

Widget _richEditorPreview(String? variant) {
  return switch (variant) {
    'image' => const RichEditorImageExample(),
    'max-length' => const RichEditorMaxLengthExample(),
    'no-toolbar' => const RichEditorNoToolbarExample(),
    _ => const RichEditorDefaultExample(),
  };
}

Widget _switchFieldPreview(String? variant) {
  return switch (variant) {
    'chain' => const SwitchFieldChainExample(),
    _ => const SwitchFieldDefaultExample(),
  };
}

Widget _starRatingPreview(String? variant) {
  return switch (variant) {
    'chain' => const StarRatingChainExample(),
    _ => const StarRatingDefaultExample(),
  };
}

Widget _rangePreview(String? variant) {
  return switch (variant) {
    'chain' => const RangeChainExample(),
    _ => const RangeDefaultExample(),
  };
}

Widget _itemPickerPreview(String? variant) {
  return switch (variant) {
    'chain' => const ItemPickerChainExample(),
    _ => const ItemPickerDefaultExample(),
  };
}

Widget _multiAnswerCardPreview(String? variant) {
  return switch (variant) {
    'chain' => const MultiAnswerCardChainExample(),
    _ => const MultiAnswerCardDefaultExample(),
  };
}

Widget _formattedInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const FormattedInputChainExample(),
    'credit-card' => const FormattedInputCreditCardExample(),
    'date' => const FormattedInputDateExample(),
    'korean-phone' => const FormattedInputKoreanPhoneExample(),
    'verify' => const FormattedInputVerifyExample(),
    _ => const FormattedInputDefaultExample(),
  };
}

Widget _numberInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const NumberInputChainExample(),
    'disabled' => const NumberInputDisabledExample(),
    'error' => const NumberInputErrorExample(),
    'filled' => const NumberInputFilledExample(),
    'sizes' => const NumberInputSizesExample(),
    _ => const NumberInputDefaultExample(),
  };
}

Widget _objectInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const ObjectInputChainExample(),
    _ => const ObjectInputDefaultExample(),
  };
}

Widget _chipInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const ChipInputChainExample(),
    _ => const ChipInputDefaultExample(),
  };
}

Widget _inputOtpPreview(String? variant) {
  return switch (variant) {
    'chain' => const InputOtpChainExample(),
    'editable' => const InputOtpEditableExample(),
    'lg' => const InputOtpLgExample(),
    _ => const InputOtpDefaultExample(),
  };
}

Widget _fieldsetPreview(String? variant) {
  return switch (variant) {
    'chain' => const FieldsetChainExample(),
    'outlined' => const FieldsetOutlinedExample(),
    'plain' => const FieldsetPlainExample(),
    _ => const FieldsetDefaultExample(),
  };
}

Widget _formPreview(String? variant) {
  return const FormDefaultExample();
}

Widget _autocompletePreview(String? variant) {
  return switch (variant) {
    'chain' => const AutocompleteChainExample(),
    _ => const AutocompleteDefaultExample(),
  };
}

Widget _phoneInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const PhoneInputChainExample(),
    _ => const PhoneInputDefaultExample(),
  };
}

Widget _fileInputPreview(String? variant) {
  return switch (variant) {
    'chain' => const FileInputChainExample(),
    _ => const FileInputDefaultExample(),
  };
}

Widget _filterPreview(String? variant) {
  return switch (variant) {
    'disabled' => const FilterDisabledExample(),
    'chain' => const FilterChainExample(),
    _ => const FilterDefaultExample(),
  };
}

Widget _toggleGroupPreview(String? variant) {
  return switch (variant) {
    'disabled' => const ToggleGroupDisabledExample(),
    'chain' => const ToggleGroupChainExample(),
    'vertical' => const ToggleGroupVerticalExample(),
    _ => const ToggleGroupDefaultExample(),
  };
}

Widget _stepperPreview(String? variant) {
  return switch (variant) {
    'chain' => const StepperChainExample(),
    'vertical' => const StepperVerticalExample(),
    'disabled' => const StepperDisabledExample(),
    _ => const StepperDefaultExample(),
  };
}

Widget _popoverPreview(String? variant) {
  return switch (variant) {
    'chain' => const PopoverChainExample(),
    _ => const PopoverDefaultExample(),
  };
}

Widget _popupPreview(String? variant) {
  return switch (variant) {
    'chain' => const PopupChainExample(),
    _ => const PopupDefaultExample(),
  };
}

Widget _drawerPreview(String? variant) {
  return switch (variant) {
    'chain' => const DrawerChainExample(),
    'sheet' => const DrawerSheetExample(),
    'rubber-band' => const DrawerRubberBandExample(),
    'footer' => const DrawerFooterExample(),
    _ => const DrawerDefaultExample(),
  };
}

Widget _hoverPreview(String? variant) {
  return switch (variant) {
    'chain' => const HoverChainExample(),
    'fade' => const HoverFadeExample(),
    'shadow' => const HoverShadowExample(),
    _ => const HoverDefaultExample(),
  };
}

Widget _hoverCardPreview(String? variant) {
  return switch (variant) {
    'chain' => const HoverCardChainExample(),
    _ => const HoverCardDefaultExample(),
  };
}

Widget _contextMenuPreview(String? variant) {
  return switch (variant) {
    'chain' => const ContextMenuChainExample(),
    'lift' => const ContextMenuLiftExample(),
    _ => const ContextMenuDefaultExample(),
  };
}

Widget _dropdownMenuPreview(String? variant) {
  return switch (variant) {
    'chain' => const DropdownMenuChainExample(),
    _ => const DropdownMenuDefaultExample(),
  };
}

Widget _menuPreview(String? variant) {
  return switch (variant) {
    'chain' => const MenuChainExample(),
    _ => const MenuDefaultExample(),
  };
}

Widget _menuItemPreview(String? variant) {
  return switch (variant) {
    'chain' => const MenuItemChainExample(),
    'critical' => const MenuItemCriticalExample(),
    'description' => const MenuItemDescriptionExample(),
    _ => const MenuItemDefaultExample(),
  };
}

Widget _menubarPreview(String? variant) {
  return switch (variant) {
    'chain' => const MenubarChainExample(),
    _ => const MenubarDefaultExample(),
  };
}

Widget _multipleChoicePreview(String? variant) {
  return switch (variant) {
    'chain' => const MultipleChoiceChainExample(),
    _ => const MultipleChoiceDefaultExample(),
  };
}

Widget _navigationBarPreview(String? variant) {
  return switch (variant) {
    'chain' => const NavigationBarChainExample(),
    'compact' => const NavigationBarCompactExample(),
    'rail' => const NavigationBarRailExample(),
    'text-tabs' => const NavigationBarTextTabsExample(),
    'sidebar' => const NavigationBarSidebarExample(),
    _ => const NavigationBarDefaultExample(),
  };
}

Widget _navigationBarItemPreview(String? variant) {
  return switch (variant) {
    'chain' => const NavigationBarItemChainExample(),
    'drawer' => const NavigationBarItemDrawerExample(),
    _ => const NavigationBarItemDefaultExample(),
  };
}

Widget _scaffoldPreview(String? variant) {
  return switch (variant) {
    'chain' => const ScaffoldChainExample(),
    _ => const ScaffoldDefaultExample(),
  };
}

Widget _appBarPreview(String? variant) {
  return switch (variant) {
    'foldable' => const AppBarFoldableExample(),
    'glass' => const AppBarFoldableExample(controlRail: false),
    'centered' => const AppBarCenteredExample(),
    'chain' => const AppBarChainExample(),
    'compact' => const AppBarCompactExample(),
    'dense' => const AppBarDenseExample(),
    'medium' => const AppBarMediumExample(),
    'prominent' => const AppBarProminentExample(),
    'text' => const AppBarTextExample(),
    _ => const AppBarDefaultExample(),
  };
}

Widget _themeControllerPreview(String? variant) {
  return switch (variant) {
    'chain' => const ThemeControllerChainExample(),
    _ => const ThemeControllerDefaultExample(),
  };
}

Widget _navigationMenuPreview(String? variant) {
  return switch (variant) {
    'chain' => const NavigationMenuChainExample(),
    _ => const NavigationMenuDefaultExample(),
  };
}

Widget _switcherPreview(String? variant) {
  return switch (variant) {
    'chain' => const SwitcherChainExample(),
    _ => const SwitcherDefaultExample(),
  };
}

Widget _indexedSwitcherPreview(String? variant) {
  return switch (variant) {
    'chain' => const IndexedSwitcherChainExample(),
    _ => const IndexedSwitcherDefaultExample(),
  };
}

Widget _dragPreview(String? variant) {
  return switch (variant) {
    'board' => const DragBoardExample(),
    'overlay' => const DragOverlayExample(),
    _ => const DragDefaultExample(),
  };
}

Widget _sortablePreview(String? variant) {
  return switch (variant) {
    'chain' => const SortableChainExample(),
    _ => const SortableDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Phase 3: Complex Components (15)
// ---------------------------------------------------------------------------

Widget _calendarPreview(String? variant) {
  return switch (variant) {
    'chain' => const CalendarChainExample(),
    'markers' => const CalendarMarkersExample(),
    'range' => const CalendarRangeExample(),
    'multi' => const CalendarMultiExample(),
    'none' => const CalendarNoneExample(),
    _ => const CalendarDefaultExample(),
  };
}

Widget _datePickerPreview(String? variant) {
  return switch (variant) {
    'chain' => const DatePickerChainExample(),
    'dialog' => const DatePickerDialogExample(),
    'range' => const DatePickerRangeExample(),
    'range_dialog' => const DatePickerRangeDialogExample(),
    _ => const DatePickerDefaultExample(),
  };
}

Widget _timePickerPreview(String? variant) {
  return switch (variant) {
    'chain' => const TimePickerChainExample(),
    'dialog' => const TimePickerDialogExample(),
    'seconds' => const TimePickerSecondsExample(),
    'error' => const TimePickerErrorExample(),
    _ => const TimePickerDefaultExample(),
  };
}

Widget _colorPickerPreview(String? variant) {
  return switch (variant) {
    'chain' => const ColorPickerChainExample(),
    'inline' => const ColorPickerInlineExample(),
    _ => const ColorPickerDefaultExample(),
  };
}

Widget _carouselPreview(String? variant) {
  return switch (variant) {
    'chain' => const CarouselChainExample(),
    'banner' => const CarouselBannerExample(),
    _ => const CarouselDefaultExample(),
  };
}

Widget _carouselBannerPreview(String? variant) {
  return switch (variant) {
    'chain' => const CarouselBannerChainExample(),
    'md' => const CarouselBannerMdExample(),
    _ => const CarouselBannerDefaultExample(),
  };
}

Widget _chatPreview(String? variant) {
  return switch (variant) {
    'chain' => const ChatChainExample(),
    'neutral' => const ChatNeutralExample(),
    'plain' => const ChatPlainExample(),
    'tail-corner' => const ChatTailCornerExample(),
    'tail-top' => const ChatTailTopExample(),
    'primary' => const ChatPrimaryExample(),
    'secondary' => const ChatSecondaryExample(),
    'accent' => const ChatAccentExample(),
    'info' => const ChatInfoExample(),
    'success' => const ChatSuccessExample(),
    'warning' => const ChatWarningExample(),
    'error' => const ChatErrorExample(),
    _ => const ChatDefaultExample(),
  };
}

Widget _codeSnippetPreview(String? variant) {
  return switch (variant) {
    'chain' => const CodeSnippetChainExample(),
    'line-tones' => const CodeSnippetLineTonesExample(),
    _ => const CodeSnippetDefaultExample(),
  };
}

Widget _resizablePreview(String? variant) {
  return switch (variant) {
    'chain' => const ResizableChainExample(),
    'drag-handle' => const ResizableDragHandleExample(),
    'vertical' => const ResizableVerticalExample(),
    _ => const ResizableDefaultExample(),
  };
}

Widget _mockupPreview(String? variant) {
  return switch (variant) {
    'chain' => const MockupChainExample(),
    'browser' => const MockupBrowserExample(),
    'code' => const MockupCodeExample(),
    'app' => const MockupAppExample(),
    'tablet' => const MockupDeviceTabletExample(),
    'landscape' => const MockupDeviceLandscapeExample(),
    _ => const MockupDeviceExample(),
  };
}

Widget _mockupBrowserPreview(String? variant) {
  return const MockupBrowserExample();
}

Widget _mockupCodePreview(String? variant) {
  return switch (variant) {
    'tones' => const MockupCodeTonesExample(),
    _ => const MockupCodeExample(),
  };
}

Widget _mockupFoldablePreview(String? variant) {
  return switch (variant) {
    'half-open' => const MockupFoldableHalfOpenExample(),
    'closed' => const MockupFoldableClosedExample(),
    'angle' => const MockupFoldableAngleExample(),
    'chain' => const MockupFoldableChainExample(),
    _ => const MockupFoldableDefaultExample(),
  };
}

Widget _mockupDevicePreview(String? variant) {
  return switch (variant) {
    'flat' => const MockupDeviceFlatExample(),
    'screen-brightness' => const MockupDeviceScreenBrightnessExample(),
    _ => const MockupDeviceExample(),
  };
}

Widget _maskPreview(String? variant) {
  return switch (variant) {
    'circle' => const MaskCircleExample(),
    'heart' => const MaskHeartExample(),
    'hexagon' => const MaskHexagonExample(),
    'star' => const MaskStarExample(),
    'triangle' => const MaskTriangleExample(),
    _ => const MaskDefaultExample(),
  };
}

Widget _mediaQueryPreview(String? variant) {
  return const MediaQueryDefaultExample();
}

Widget _hoverGalleryPreview(String? variant) {
  return switch (variant) {
    'chain' => const HoverGalleryChainExample(),
    _ => const HoverGalleryDefaultExample(),
  };
}

Widget _refreshTriggerPreview(String? variant) {
  return switch (variant) {
    'chain' => const RefreshTriggerChainExample(),
    _ => const RefreshTriggerDefaultExample(),
  };
}

Widget _swiperPreview(String? variant) {
  return switch (variant) {
    'chain' => const SwiperChainExample(),
    'sheet' => const SwiperSheetExample(),
    _ => const SwiperDefaultExample(),
  };
}

Widget _treePreview(String? variant) {
  return switch (variant) {
    'chain' => const TreeChainExample(),
    'selected' => const TreeSelectedExample(),
    'trailing' => const TreeTrailingExample(),
    _ => const TreeDefaultExample(),
  };
}

Widget _commandPreview(String? variant) {
  return switch (variant) {
    'chain' => const CommandChainExample(),
    'dialog' => const CommandDialogExample(),
    'scrollable' => const CommandScrollableExample(),
    'empty' => const CommandEmptyExample(),
    _ => const CommandDefaultExample(),
  };
}

Widget _commandSearchPreview(String? variant) {
  return switch (variant) {
    'chain' => const CommandSearchChainExample(),
    _ => const CommandSearchDefaultExample(),
  };
}

Widget _pageHeaderPreview(String? variant) {
  return switch (variant) {
    'chain' => const PageHeaderChainExample(),
    _ => const PageHeaderDefaultExample(),
  };
}

Widget _panelHeaderPreview(String? variant) {
  return switch (variant) {
    'chain' => const PanelHeaderChainExample(),
    _ => const PanelHeaderDefaultExample(),
  };
}

Widget _bottomActionBarPreview(String? variant) {
  return switch (variant) {
    'horizontal' => const BottomActionBarHorizontalExample(),
    'scaffold' => const BottomActionBarScaffoldExample(),
    'summary-compact' => const BottomActionBarSummaryCompactExample(),
    'chain' => const BottomActionBarChainExample(),
    _ => const BottomActionBarDefaultExample(),
  };
}

Widget _optionItemPreview(String? variant) {
  return switch (variant) {
    'multiple' => const OptionItemMultipleExample(),
    'disabled' => const OptionItemDisabledExample(),
    'chain' => const OptionItemChainExample(),
    _ => const OptionItemDefaultExample(),
  };
}

Widget _optionListPreview(String? variant) {
  return switch (variant) {
    'chain' => const OptionListChainExample(),
    _ => const OptionListDefaultExample(),
  };
}

Widget _bottomSheetPreview(String? variant) {
  return switch (variant) {
    'close' => const BottomSheetCloseExample(),
    'chain' => const BottomSheetChainExample(),
    _ => const BottomSheetDefaultExample(),
  };
}

Widget _textPreview(String? variant) {
  return switch (variant) {
    'typography-display' => const TextTypographyDisplayExample(),
    'typography-headline' => const TextTypographyHeadlineExample(),
    'typography-title' => const TextTypographyTitleExample(),
    'typography-body' => const TextTypographyBodyExample(),
    'typography-weight' => const TextTypographyWeightExample(),
    'typography-primitive' => const TextTypographyPrimitiveExample(),
    'colors-brand' => const TextColorsBrandExample(),
    'colors-status' => const TextColorsStatusExample(),
    'colors-surface' => const TextColorsSurfaceExample(),
    'modifiers' => const TextModifiersExample(),
    'wrap' => const TextWrapExample(),
    'textstyle' => const TextTextstyleExample(),
    'opacity' => const TextOpacityExample(),
    'rich' => const TextRichExample(),
    'keep-all' => const TextKeepAllExample(),
    _ => const TextDefaultExample(),
  };
}

Widget _selectableTextPreview(String? variant) {
  return switch (variant) {
    'chain' => const SelectableTextChainExample(),
    'styled' => const SelectableTextStyledExample(),
    _ => const SelectableTextDefaultExample(),
  };
}

Widget _iconPreview(String? variant) {
  return switch (variant) {
    'chain' => const IconChainExample(),
    'search' => const IconSearchExample(),
    'favorite' => const IconFavoriteExample(),
    _ => const IconDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Indicator
// ---------------------------------------------------------------------------

Widget _indicatorPreview(String? variant) {
  return switch (variant) {
    'chain' => const IndicatorChainExample(),
    'bottom-start' => const IndicatorBottomStartExample(),
    _ => const IndicatorDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DescriptionCard
// ---------------------------------------------------------------------------

Widget _descriptionCardPreview(String? variant) {
  return switch (variant) {
    'chain' => const DescriptionCardChainExample(),
    'filled' => const DescriptionCardFilledExample(),
    'ghost' => const DescriptionCardGhostExample(),
    'vertical' => const DescriptionCardVerticalExample(),
    'space-between' => const DescriptionCardSpaceBetweenExample(),
    'placeholder' => const DescriptionCardPlaceholderExample(),
    _ => const DescriptionCardDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// AspectRatioBox / TextBlock
// ---------------------------------------------------------------------------

Widget _aspectRatioBoxPreview(String? variant) => const AspectRatioBoxDefaultExample();

Widget _textBlockPreview(String? variant) {
  return switch (variant) {
    'chain' => const TextBlockChainExample(),
    _ => const TextBlockDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Form sub-widgets
// ---------------------------------------------------------------------------

Widget _formLabelPreview(String? variant) {
  return switch (variant) {
    'chain' => const FormLabelChainExample(),
    _ => const FormLabelDefaultExample(),
  };
}

Widget _validatedPreview(String? variant) {
  return switch (variant) {
    'chain' => const ValidatedChainExample(),
    _ => const ValidatedDefaultExample(),
  };
}

Widget _validatorHintPreview(String? variant) {
  return switch (variant) {
    'chain' => const ValidatorHintChainExample(),
    _ => const ValidatorHintDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Infra
// ---------------------------------------------------------------------------

Widget _clickablePreview(String? variant) {
  return switch (variant) {
    'chain' => const ClickableChainExample(),
    _ => const ClickableDefaultExample(),
  };
}

Widget _focusOutlinePreview(String? variant) {
  return switch (variant) {
    'chain' => const FocusOutlineChainExample(),
    _ => const FocusOutlineDefaultExample(),
  };
}

Widget _outlinedContainerPreview(String? variant) {
  return switch (variant) {
    'chain' => const OutlinedContainerChainExample(),
    _ => const OutlinedContainerDefaultExample(),
  };
}

Widget _subfocusPreview(String? variant) {
  return switch (variant) {
    'chain' => const SubfocusChainExample(),
    _ => const SubfocusScopeDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Formatter / ScrollView interceptor
// ---------------------------------------------------------------------------

Widget _formatterPreview(String? variant) => const FormatterDefaultExample();

Widget _scrollviewPreview(String? variant) {
  return switch (variant) {
    'chain' => const ScrollViewInterceptorChainExample(),
    _ => const ScrollViewInterceptorDefaultExample(),
  };
}

Widget _formFieldPreview(String? variant) {
  return switch (variant) {
    'chain' => const FormFieldChainExample(),
    _ => const FormFieldDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Breakpoint
// ---------------------------------------------------------------------------

Widget _breakpointPreview(String? variant) => const BreakpointDefaultExample();

Widget _toolbarGroupPreview(String? variant) => switch (variant) {
  'vertical' => const ToolbarGroupVerticalExample(),
  _ => const ToolbarGroupDefaultExample(),
};
