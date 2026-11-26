import 'package:coui_web/coui_web.dart';

import '../shared/preview_layout.dart';
import 'examples/web/component_examples.dart';
import '../internal/preview/scenes.dart';
import '../internal/preview/web_scene.dart';
import '../internal/preview/scene_unavailable.dart' if (dart.library.io) '../internal/preview/scene_file.dart';

/// Builder function that creates a web preview component.
typedef WebPreviewBuilder = Component Function(BuildContext context, String? variant);

/// Registry of web preview builders for all documented components.
///
/// Each entry maps a component name to a builder function that takes
/// an optional variant and returns a jaspr Component. A preview whose Flutter
/// twin fills the width it is given ([kDocsFillWidthPreviews]) comes out
/// wrapped in a `w-full` box: the stage centres its example in a flex column,
/// where a block root would otherwise be content-sized. The docs site and the
/// parity harness both read this map, so both get the same stage.
final Map<String, WebPreviewBuilder> kWebPreviewRegistry = {
  for (final entry in _kRawWebPreviewRegistry.entries)
    entry.key: _withDocumentationScenes(entry.key, _fillingTheStageWhereFlutterFills(entry.key, entry.value)),
};

WebPreviewBuilder _withDocumentationScenes(String component, WebPreviewBuilder build) => (context, variant) {
  if (variant != null && variant.startsWith(docsScenePrefix)) {
    return renderWebScene(resolveDocsScene(component, variant));
  }
  return build(context, variant);
};

/// [build], with the preview wrapped in a `w-full` box for the variants listed
/// in [kDocsFillWidthPreviews].
WebPreviewBuilder _fillingTheStageWhereFlutterFills(
  String component,
  WebPreviewBuilder build,
) {
  if (!kDocsFillWidthPreviews.any((key) => key.startsWith('$component/'))) {
    return build;
  }
  return (context, variant) {
    final preview = build(context, variant);
    if (!docsPreviewFillsWidth(component, variant)) return preview;
    // An Align over a capped body fills Flutter's stage, while the body's
    // own width stays fixed. Centre it without inheriting text alignment.
    final centredBody =
        component == 'mockup' ||
        component == 'mockup-device' ||
        component == 'mockup-foldable' ||
        component == 'responsive-container';
    return div(
      classes: centredBody ? 'w-full flex justify-center' : 'w-full',
      [preview],
    );
  };
}

final Map<String, WebPreviewBuilder> _kRawWebPreviewRegistry = {
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

Component _buttonPreview(BuildContext context, String? variant) {
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

Component _inputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TextFieldChainExample(),
    'error' => const TextFieldErrorExample(),
    _ => const TextFieldDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Checkbox
// ---------------------------------------------------------------------------

Component _checkboxPreview(BuildContext context, String? variant) {
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

Component _togglePreview(BuildContext context, String? variant) {
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

Component _sliderPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SliderChainExample(),
    'disabled' => const SliderDisabledExample(),
    _ => const SliderDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

Component _badgePreview(BuildContext context, String? variant) {
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

Component _sidebarPreview(BuildContext context, String? variant) {
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

Component _tagPreview(BuildContext context, String? variant) {
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

Component _avatarPreview(BuildContext context, String? variant) {
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

Component _cardPreview(BuildContext context, String? variant) {
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

Component _cardImagePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CardImageChainExample(),
    _ => const CardImageDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Alert
// ---------------------------------------------------------------------------

Component _alertPreview(BuildContext context, String? variant) {
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

Component _progressPreview(BuildContext context, String? variant) {
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

Component _toastPreview(BuildContext context, String? variant) {
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

Component _breadcrumbPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const BreadcrumbChainExample(),
    _ => const BreadcrumbDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

Component _tabsPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'badge' => const TabsBadgeExample(),
    'closable' => const TabsClosableExample(),
    'chain' => const TabsChainExample(),
    'line' => const TabsLineExample(),
    _ => const TabsDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// TabPane
// ---------------------------------------------------------------------------

Component _tabPanePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TabPaneChainExample(),
    'editor-strip' => const TabPaneEditorStripExample(),
    _ => const TabPaneExample(),
  };
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

Component _paginationPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PaginationChainExample(),
    _ => const PaginationDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

Component _dialogPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DialogChainExample(),
    'stretch' => const DialogStretchExample(),
    _ => const DialogDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DraggablePanel
// ---------------------------------------------------------------------------

Component _draggablePanelPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DraggablePanelChainExample(),
    'outside' => const DraggablePanelOutsideExample(),
    _ => const DraggablePanelDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Tooltip
// ---------------------------------------------------------------------------

Component _tooltipPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TooltipChainExample(),
    _ => const TooltipDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Accordion
// ---------------------------------------------------------------------------

Component _accordionPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const AccordionChainExample(),
    _ => const AccordionDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Select
// ---------------------------------------------------------------------------

Component _selectPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SelectChainExample(),
    'suffix' => const SelectSuffixExample(),
    _ => const SelectDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Radio
// ---------------------------------------------------------------------------

Component _radioPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const RadioGroupChainExample(),
    'card' => const RadioGroupCardExample(),
    _ => const RadioGroupDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Phase 1: Simple Components (24)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

Component _dividerPreview(BuildContext context, String? variant) {
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

Component _scrollableClientPreview(BuildContext context, String? variant) {
  return const ScrollableClientDefaultExample();
}

// ---------------------------------------------------------------------------
// StackLayout
// ---------------------------------------------------------------------------

Component _stackLayoutPreview(BuildContext context, String? variant) {
  return const StackLayoutDefaultExample();
}

// ---------------------------------------------------------------------------
// StageContainer
// ---------------------------------------------------------------------------

Component _stageContainerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const StageContainerChainExample(),
    _ => const StageContainerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Window (multi-window manager)
// ---------------------------------------------------------------------------

Component _windowPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const WindowChainExample(),
    _ => const WindowDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// WindowPanel
// ---------------------------------------------------------------------------

Component _windowPanelPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const WindowPanelChainExample(),
    _ => const WindowPanelDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Gap
// ---------------------------------------------------------------------------

Component _gapPreview(BuildContext context, String? variant) {
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

Component _validationBadgePreview(BuildContext context, String? variant) {
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

Component _definitionListPreview(BuildContext context, String? variant) {
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

Component _disclosureBadgePreview(BuildContext context, String? variant) {
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

Component _kbdPreview(BuildContext context, String? variant) {
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

Component _labelPreview(BuildContext context, String? variant) {
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

Component _linkPreview(BuildContext context, String? variant) {
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

Component _chipPreview(BuildContext context, String? variant) {
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

Component _chipGroupPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ChipGroupChainExample(),
    'scroll' => const ChipGroupScrollExample(),
    _ => const ChipGroupDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// CodeDiff
// ---------------------------------------------------------------------------

Component _codeDiffPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CodeDiffChainExample(),
    _ => const CodeDiffDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Diff
// ---------------------------------------------------------------------------

Component _diffPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DiffChainExample(),
    'text' => const DiffTextExample(),
    _ => const DiffDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

Component _loadingPreview(BuildContext context, String? variant) {
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

Component _scrollAreaPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ScrollAreaChainExample(),
    _ => const ScrollAreaDefaultExample(),
  };
}

Component _scrollbarPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ScrollbarChainExample(),
    _ => const ScrollbarDefaultExample(),
  };
}

Component _skeletonPreview(BuildContext context, String? variant) {
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

Component _loadingRegionPreview(BuildContext context, String? variant) {
  return switch (variant) {
    _ => const LoadingRegionDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DotIndicator
// ---------------------------------------------------------------------------

Component _dotIndicatorPreview(BuildContext context, String? variant) {
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

Component _statusPreview(BuildContext context, String? variant) {
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

Component _statPreview(BuildContext context, String? variant) {
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

Component _emptyStatePreview(BuildContext context, String? variant) {
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

Component _fadeScrollPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FadeScrollChainExample(),
    'horizontal' => const FadeScrollHorizontalExample(),
    'with-scrollbar' => const FadeScrollWithScrollbarExample(),
    _ => const FadeScrollDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

Component _bannerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const BannerChainExample(),
    'info' => const BannerInfoExample(),
    'narrow' => const BannerNarrowExample(),
    'success' => const BannerSuccessExample(),
    'warning' => const BannerWarningExample(),
    'error' || 'destructive' => const BannerDestructiveExample(),
    'solid' => const BannerSolidExample(),
    _ => const BannerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

Component _countdownPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CountdownChainExample(),
    _ => const CountdownDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// NumberTicker
// ---------------------------------------------------------------------------

Component _numberTickerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const NumberTickerChainExample(),
    _ => const NumberTickerDefaultExample(),
  };
}

Component _overflowMarqueePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const OverflowMarqueeChainExample(),
    _ => const OverflowMarqueeDefaultExample(),
  };
}

Component _responsiveContainerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveContainerChainExample(),
    _ => const ResponsiveContainerDefaultExample(),
  };
}

Component _responsiveGridPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveGridChainExample(),
    'span' => const ResponsiveGridSpanExample(),
    _ => const ResponsiveGridDefaultExample(),
  };
}

Component _responsiveRowColumnPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ResponsiveRowColumnChainExample(),
    'desktop' => const ResponsiveRowColumnDesktopExample(),
    _ => const ResponsiveRowColumnDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

Component _stepsPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const StepsChainExample(),
    'horizontal' => const StepsHorizontalExample(),
    'list' => const StepsListExample(),
    _ => const StepsDefaultExample(),
  };
}

Component _stepItemPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const StepItemChainExample(),
    _ => const StepItemDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

Component _timelinePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TimelineChainExample(),
    _ => const TimelineDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Collapsible
// ---------------------------------------------------------------------------

Component _collapsiblePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CollapsibleChainExample(),
    _ => const CollapsibleDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Disclosure
// ---------------------------------------------------------------------------

Component _disclosurePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'group' => const DisclosureGroupExample(),
    'chain' => const DisclosureChainExample(),
    _ => const DisclosureDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Join
// ---------------------------------------------------------------------------

Component _joinPreview(BuildContext context, String? variant) {
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

Component _basicPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const BasicChainExample(),
    _ => const BasicDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Dock
// ---------------------------------------------------------------------------

Component _dockPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DockChainExample(),
    _ => const DockDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

Component _footerPreview(BuildContext context, String? variant) {
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

Component _framePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FrameChainExample(),
    'column' => const FrameColumnExample(),
    'dashed' => const FrameDashedExample(),
    'elevated' => const FrameElevatedExample(),
    _ => const FrameDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// HeroSection
// ---------------------------------------------------------------------------

Component _heroSectionPreview(BuildContext context, String? variant) {
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

Component _hiddenPreview(BuildContext context, String? variant) {
  return const HiddenDefaultExample();
}

// ---------------------------------------------------------------------------
// Listing
// ---------------------------------------------------------------------------

Component _listingPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ListingChainExample(),
    _ => const ListingDefaultExample(),
  };
}

Component _swipeActionsPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SwipeActionsChainExample(),
    'scope' => const SwipeActionsScopeExample(),
    _ => const SwipeActionsDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// FAB
// ---------------------------------------------------------------------------

Component _fabPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FabChainExample(),
    _ => const FabDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Swap
// ---------------------------------------------------------------------------

Component _swapPreview(BuildContext context, String? variant) {
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

Component _trackerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TrackerChainExample(),
    _ => const TrackerDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// CategoryBreakdown
// ---------------------------------------------------------------------------

Component _categoryBreakdownPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'donut' => const CategoryBreakdownDonutExample(),
    'chain' => const CategoryBreakdownChainExample(),
    _ => const CategoryBreakdownDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// TrendChart
// ---------------------------------------------------------------------------

Component _trendChartPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'bar' => const TrendChartBarExample(),
    'chain' => const TrendChartChainExample(),
    _ => const TrendChartDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Table (existing)
// ---------------------------------------------------------------------------

Component _tablePreview(BuildContext context, String? variant) {
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

Component _textAreaPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TextAreaChainExample(),
    'footer' => const TextAreaFooterExample(),
    _ => const TextAreaDefaultExample(),
  };
}

Component _richEditorPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'image' => const RichEditorImageExample(),
    'max-length' => const RichEditorMaxLengthExample(),
    'no-toolbar' => const RichEditorNoToolbarExample(),
    _ => const RichEditorDefaultExample(),
  };
}

Component _switchFieldPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SwitchFieldChainExample(),
    _ => const SwitchFieldDefaultExample(),
  };
}

Component _starRatingPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const StarRatingChainExample(),
    _ => const StarRatingDefaultExample(),
  };
}

Component _rangePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const RangeChainExample(),
    _ => const RangeDefaultExample(),
  };
}

Component _itemPickerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ItemPickerChainExample(),
    _ => const ItemPickerDefaultExample(),
  };
}

Component _multiAnswerCardPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const MultiAnswerCardChainExample(),
    _ => const MultiAnswerCardDefaultExample(),
  };
}

Component _formattedInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FormattedInputChainExample(),
    'credit-card' => const FormattedInputCreditCardExample(),
    'date' => const FormattedInputDateExample(),
    'korean-phone' => const FormattedInputKoreanPhoneExample(),
    'verify' => const FormattedInputVerifyExample(),
    _ => const FormattedInputDefaultExample(),
  };
}

Component _numberInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const NumberInputChainExample(),
    'disabled' => const NumberInputDisabledExample(),
    'error' => const NumberInputErrorExample(),
    'filled' => const NumberInputFilledExample(),
    'sizes' => const NumberInputSizesExample(),
    _ => const NumberInputDefaultExample(),
  };
}

Component _objectInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ObjectInputChainExample(),
    _ => const ObjectInputDefaultExample(),
  };
}

Component _chipInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ChipInputChainExample(),
    _ => const ChipInputDefaultExample(),
  };
}

Component _inputOtpPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const InputOtpChainExample(),
    'editable' => const InputOtpEditableExample(),
    'lg' => const InputOtpLgExample(),
    _ => const InputOtpDefaultExample(),
  };
}

Component _fieldsetPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FieldsetChainExample(),
    'outlined' => const FieldsetOutlinedExample(),
    'plain' => const FieldsetPlainExample(),
    _ => const FieldsetDefaultExample(),
  };
}

Component _formPreview(BuildContext context, String? variant) {
  return const FormDefaultExample();
}

Component _autocompletePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const AutocompleteChainExample(),
    _ => const AutocompleteDefaultExample(),
  };
}

Component _phoneInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PhoneInputChainExample(),
    _ => const PhoneInputDefaultExample(),
  };
}

Component _fileInputPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FileInputChainExample(),
    _ => const FileInputDefaultExample(),
  };
}

Component _filterPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'disabled' => const FilterDisabledExample(),
    'chain' => const FilterChainExample(),
    _ => const FilterDefaultExample(),
  };
}

Component _toggleGroupPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'disabled' => const ToggleGroupDisabledExample(),
    'chain' => const ToggleGroupChainExample(),
    'vertical' => const ToggleGroupVerticalExample(),
    _ => const ToggleGroupDefaultExample(),
  };
}

Component _stepperPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const StepperChainExample(),
    'vertical' => const StepperVerticalExample(),
    'disabled' => const StepperDisabledExample(),
    _ => const StepperDefaultExample(),
  };
}

Component _popoverPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PopoverChainExample(),
    _ => const PopoverDefaultExample(),
  };
}

Component _popupPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PopupChainExample(),
    _ => const PopupDefaultExample(),
  };
}

Component _drawerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DrawerChainExample(),
    'sheet' => const DrawerSheetExample(),
    'rubber-band' => const DrawerRubberBandExample(),
    'footer' => const DrawerFooterExample(),
    _ => const DrawerDefaultExample(),
  };
}

Component _hoverPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const HoverChainExample(),
    'fade' => const HoverFadeExample(),
    'shadow' => const HoverShadowExample(),
    _ => const HoverDefaultExample(),
  };
}

Component _hoverCardPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const HoverCardChainExample(),
    _ => const HoverCardDefaultExample(),
  };
}

Component _contextMenuPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ContextMenuChainExample(),
    'lift' => const ContextMenuLiftExample(),
    _ => const ContextMenuDefaultExample(),
  };
}

Component _dropdownMenuPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DropdownMenuChainExample(),
    _ => const DropdownMenuDefaultExample(),
  };
}

Component _menuPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const MenuChainExample(),
    _ => const MenuDefaultExample(),
  };
}

Component _menuItemPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const MenuItemChainExample(),
    'critical' => const MenuItemCriticalExample(),
    'description' => const MenuItemDescriptionExample(),
    _ => const MenuItemDefaultExample(),
  };
}

Component _menubarPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const MenubarChainExample(),
    _ => const MenubarDefaultExample(),
  };
}

Component _multipleChoicePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const MultipleChoiceChainExample(),
    _ => const MultipleChoiceDefaultExample(),
  };
}

Component _navigationBarPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const NavigationBarChainExample(),
    'compact' => const NavigationBarCompactExample(),
    'rail' => const NavigationBarRailExample(),
    'text-tabs' => const NavigationBarTextTabsExample(),
    'sidebar' => const NavigationBarSidebarExample(),
    _ => const NavigationBarDefaultExample(),
  };
}

Component _navigationBarItemPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const NavigationBarItemChainExample(),
    'drawer' => const NavigationBarItemDrawerExample(),
    _ => const NavigationBarItemDefaultExample(),
  };
}

Component _scaffoldPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ScaffoldChainExample(),
    _ => const ScaffoldDefaultExample(),
  };
}

Component _appBarPreview(BuildContext context, String? variant) {
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

Component _themeControllerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ThemeControllerChainExample(),
    _ => const ThemeControllerDefaultExample(),
  };
}

Component _navigationMenuPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const NavigationMenuChainExample(),
    _ => const NavigationMenuDefaultExample(),
  };
}

Component _switcherPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SwitcherChainExample(),
    _ => const SwitcherDefaultExample(),
  };
}

Component _indexedSwitcherPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const IndexedSwitcherChainExample(),
    _ => const IndexedSwitcherDefaultExample(),
  };
}

Component _dragPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'board' => const DragBoardExample(),
    'overlay' => const DragOverlayExample(),
    _ => const DragDefaultExample(),
  };
}

Component _sortablePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SortableChainExample(),
    _ => const SortableDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Phase 3: Complex Components (15)
// ---------------------------------------------------------------------------

Component _calendarPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CalendarChainExample(),
    'markers' => const CalendarMarkersExample(),
    'range' => const CalendarRangeExample(),
    'multi' => const CalendarMultiExample(),
    'none' => const CalendarNoneExample(),
    _ => const CalendarDefaultExample(),
  };
}

Component _datePickerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const DatePickerChainExample(),
    'dialog' => const DatePickerDialogExample(),
    'range' => const DatePickerRangeExample(),
    'range_dialog' => const DatePickerRangeDialogExample(),
    _ => const DatePickerDefaultExample(),
  };
}

Component _timePickerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TimePickerChainExample(),
    'dialog' => const TimePickerDialogExample(),
    'seconds' => const TimePickerSecondsExample(),
    'error' => const TimePickerErrorExample(),
    _ => const TimePickerDefaultExample(),
  };
}

Component _colorPickerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ColorPickerChainExample(),
    'inline' => const ColorPickerInlineExample(),
    _ => const ColorPickerDefaultExample(),
  };
}

Component _carouselPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CarouselChainExample(),
    'banner' => const CarouselBannerExample(),
    _ => const CarouselDefaultExample(),
  };
}

Component _carouselBannerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CarouselBannerChainExample(),
    'md' => const CarouselBannerMdExample(),
    _ => const CarouselBannerDefaultExample(),
  };
}

Component _chatPreview(BuildContext context, String? variant) {
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

Component _codeSnippetPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CodeSnippetChainExample(),
    'line-tones' => const CodeSnippetLineTonesExample(),
    _ => const CodeSnippetDefaultExample(),
  };
}

Component _resizablePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ResizableChainExample(),
    'drag-handle' => const ResizableDragHandleExample(),
    'vertical' => const ResizableVerticalExample(),
    _ => const ResizableDefaultExample(),
  };
}

Component _mockupPreview(BuildContext context, String? variant) {
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

Component _mockupBrowserPreview(BuildContext context, String? variant) {
  return const MockupBrowserExample();
}

Component _mockupCodePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'tones' => const MockupCodeTonesExample(),
    _ => const MockupCodeExample(),
  };
}

Component _mockupFoldablePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'half-open' => const MockupFoldableHalfOpenExample(),
    'closed' => const MockupFoldableClosedExample(),
    'angle' => const MockupFoldableAngleExample(),
    'chain' => const MockupFoldableChainExample(),
    _ => const MockupFoldableDefaultExample(),
  };
}

Component _mockupDevicePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'flat' => const MockupDeviceFlatExample(),
    'screen-brightness' => const MockupDeviceScreenBrightnessExample(),
    _ => const MockupDeviceExample(),
  };
}

Component _maskPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'circle' => const MaskCircleExample(),
    'heart' => const MaskHeartExample(),
    'hexagon' => const MaskHexagonExample(),
    'star' => const MaskStarExample(),
    'triangle' => const MaskTriangleExample(),
    _ => const MaskDefaultExample(),
  };
}

Component _mediaQueryPreview(BuildContext context, String? variant) {
  return const MediaQueryDefaultExample();
}

Component _hoverGalleryPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const HoverGalleryChainExample(),
    _ => const HoverGalleryDefaultExample(),
  };
}

Component _refreshTriggerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const RefreshTriggerChainExample(),
    _ => const RefreshTriggerDefaultExample(),
  };
}

Component _swiperPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SwiperChainExample(),
    'sheet' => const SwiperSheetExample(),
    _ => const SwiperDefaultExample(),
  };
}

Component _treePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TreeChainExample(),
    'selected' => const TreeSelectedExample(),
    'trailing' => const TreeTrailingExample(),
    _ => const TreeDefaultExample(),
  };
}

Component _commandPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CommandChainExample(),
    'dialog' => const CommandDialogExample(),
    'scrollable' => const CommandScrollableExample(),
    'empty' => const CommandEmptyExample(),
    _ => const CommandDefaultExample(),
  };
}

Component _commandSearchPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const CommandSearchChainExample(),
    _ => const CommandSearchDefaultExample(),
  };
}

Component _pageHeaderPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PageHeaderChainExample(),
    _ => const PageHeaderDefaultExample(),
  };
}

Component _panelHeaderPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const PanelHeaderChainExample(),
    _ => const PanelHeaderDefaultExample(),
  };
}

Component _bottomActionBarPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'horizontal' => const BottomActionBarHorizontalExample(),
    'scaffold' => const BottomActionBarScaffoldExample(),
    'summary-compact' => const BottomActionBarSummaryCompactExample(),
    'chain' => const BottomActionBarChainExample(),
    _ => const BottomActionBarDefaultExample(),
  };
}

Component _optionItemPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'multiple' => const OptionItemMultipleExample(),
    'disabled' => const OptionItemDisabledExample(),
    'chain' => const OptionItemChainExample(),
    _ => const OptionItemDefaultExample(),
  };
}

Component _optionListPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const OptionListChainExample(),
    _ => const OptionListDefaultExample(),
  };
}

Component _bottomSheetPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'close' => const BottomSheetCloseExample(),
    'chain' => const BottomSheetChainExample(),
    _ => const BottomSheetDefaultExample(),
  };
}

Component _textPreview(BuildContext context, String? variant) {
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

Component _selectableTextPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SelectableTextChainExample(),
    'styled' => const SelectableTextStyledExample(),
    _ => const SelectableTextDefaultExample(),
  };
}

Component _iconPreview(BuildContext context, String? variant) {
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

Component _indicatorPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const IndicatorChainExample(),
    'bottom-start' => const IndicatorBottomStartExample(),
    _ => const IndicatorDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// DescriptionCard
// ---------------------------------------------------------------------------

Component _descriptionCardPreview(BuildContext context, String? variant) {
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

Component _aspectRatioBoxPreview(BuildContext context, String? variant) => const AspectRatioBoxDefaultExample();

Component _textBlockPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const TextBlockChainExample(),
    _ => const TextBlockDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Form sub-widgets
// ---------------------------------------------------------------------------

Component _formLabelPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FormLabelChainExample(),
    _ => const FormLabelDefaultExample(),
  };
}

Component _validatedPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ValidatedChainExample(),
    _ => const ValidatedDefaultExample(),
  };
}

Component _validatorHintPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ValidatorHintChainExample(),
    _ => const ValidatorHintDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Infra
// ---------------------------------------------------------------------------

Component _clickablePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ClickableChainExample(),
    _ => const ClickableDefaultExample(),
  };
}

Component _focusOutlinePreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FocusOutlineChainExample(),
    _ => const FocusOutlineDefaultExample(),
  };
}

Component _outlinedContainerPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const OutlinedContainerChainExample(),
    _ => const OutlinedContainerDefaultExample(),
  };
}

Component _subfocusPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const SubfocusChainExample(),
    _ => const SubfocusScopeDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Formatter / ScrollView interceptor
// ---------------------------------------------------------------------------

Component _formatterPreview(BuildContext context, String? variant) => const FormatterDefaultExample();

Component _scrollviewPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const ScrollViewInterceptorChainExample(),
    _ => const ScrollViewInterceptorDefaultExample(),
  };
}

Component _formFieldPreview(BuildContext context, String? variant) {
  return switch (variant) {
    'chain' => const FormFieldChainExample(),
    _ => const FormFieldDefaultExample(),
  };
}

// ---------------------------------------------------------------------------
// Breakpoint
// ---------------------------------------------------------------------------

Component _breakpointPreview(BuildContext context, String? variant) => const BreakpointDefaultExample();

Component _toolbarGroupPreview(BuildContext context, String? variant) => switch (variant) {
  'vertical' => const ToolbarGroupVerticalExample(),
  _ => const ToolbarGroupDefaultExample(),
};
