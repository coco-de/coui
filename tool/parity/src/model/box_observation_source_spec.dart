import 'package:meta/meta.dart';

/// Internal source identities for an additive padding observation.
/// No expected style values or capture keys participate in this declaration.
@immutable
class BoxObservationSourceSpec {
  const BoxObservationSourceSpec({
    required this.schemaVersion,
    required this.logicalUnitId,
    required this.quantityId,
    required this.nativeAdapterId,
    required this.webAdapterId,
  });

  factory BoxObservationSourceSpec.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] is! int ||
        [
          'logicalUnitId',
          'quantityId',
          'nativeAdapterId',
          'webAdapterId',
        ].any((key) => json[key] is! String)) {
      throw const FormatException(
        'Box source requires a version and semantic IDs',
      );
    }
    return BoxObservationSourceSpec(
      schemaVersion: json['schemaVersion']! as int,
      logicalUnitId: json['logicalUnitId']! as String,
      quantityId: json['quantityId']! as String,
      nativeAdapterId: json['nativeAdapterId']! as String,
      webAdapterId: json['webAdapterId']! as String,
    );
  }

  final int schemaVersion;
  final String logicalUnitId;
  final String quantityId;
  final String nativeAdapterId;
  final String webAdapterId;

  static const quantity = 'inside-frame-own-content-inset-v1';
  static const bottomActionBarContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'bottom-action-bar-owned-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'bottom-action-bar-owned-content-inset-v1',
    webAdapterId: 'bottom-action-bar-owned-content-inset-v1',
  );

  /// Public visibility/interaction wrapper operations, separate from child
  /// content, per-action platter insets and layout constraints.
  static const mediaQueryVisibilityHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'media-query-generated-visibility-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'media-query-generated-visibility-layout-host-v1',
    webAdapterId: 'media-query-generated-visibility-layout-host-v1',
  );
  static const swipeActionsOuterHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'swipe-actions-generated-outer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'swipe-actions-generated-outer-layout-host-v1',
    webAdapterId: 'swipe-actions-generated-outer-layout-host-v1',
  );
  static const List<BoxObservationSourceSpec> publicWrapperFrames = [
    mediaQueryVisibilityHost,
    swipeActionsOuterHost,
  ];

  static const outlined = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'own-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'typed-outlined-root-content-v1',
    webAdapterId: 'matched-outlined-root-v1',
  );
  static const docsStage = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'registry-scene-frame',
    quantityId: quantity,
    nativeAdapterId: 'docs-stage-current-container-v1',
    webAdapterId: 'matched-docs-stage-v1',
  );
  static const declaredLayout = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'declared-layout-box',
    quantityId: quantity,
    nativeAdapterId: 'direct-framework-container-v1',
    webAdapterId: 'declared-layout-root-v1',
  );
  static const wholeDocCard = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'whole-documentation-card',
    quantityId: quantity,
    nativeAdapterId: 'whole-doc-card-frame-v1',
    webAdapterId: 'whole-doc-card-frame-v1',
  );
  static const docsSizePreview = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'documentation-size-preview-frame',
    quantityId: quantity,
    nativeAdapterId: 'docs-size-preview-frame-v1',
    webAdapterId: 'docs-size-preview-frame-v1',
  );
  static const docsPlayground = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'documentation-playground-stage',
    quantityId: quantity,
    nativeAdapterId: 'docs-playground-stage-frame-v1',
    webAdapterId: 'docs-playground-stage-frame-v1',
  );
  static const codeDiffFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'code-diff-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'code-diff-generated-frame-v1',
    webAdapterId: 'code-diff-generated-frame-v1',
  );
  static const commandPanelFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'command-panel-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'command-panel-generated-frame-v1',
    webAdapterId: 'command-panel-generated-frame-v1',
  );
  static const fieldsetFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'fieldset-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'fieldset-generated-frame-v1',
    webAdapterId: 'fieldset-generated-frame-v1',
  );
  static const itemPickerFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'item-picker-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'item-picker-generated-frame-v1',
    webAdapterId: 'item-picker-generated-frame-v1',
  );
  static const mockupBrowserFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'mockup-browser-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'mockup-browser-generated-frame-v1',
    webAdapterId: 'mockup-browser-generated-frame-v1',
  );
  static const objectInputFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'object-input-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'object-input-generated-frame-v1',
    webAdapterId: 'object-input-generated-frame-v1',
  );

  static const List<BoxObservationSourceSpec> componentFrames = [
    codeDiffFrame,
    commandPanelFrame,
    fieldsetFrame,
    itemPickerFrame,
    mockupBrowserFrame,
    objectInputFrame,
  ];

  static const bannerFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'banner-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'banner-generated-frame-v1',
    webAdapterId: 'banner-generated-frame-v1',
  );
  static const descriptionCardFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'description-card-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'description-card-generated-frame-v1',
    webAdapterId: 'description-card-generated-frame-v1',
  );
  static const formattedInputFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'formatted-input-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'formatted-input-generated-frame-v1',
    webAdapterId: 'formatted-input-generated-frame-v1',
  );
  static const frameContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'frame-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'frame-generated-content-inset-v1',
    webAdapterId: 'frame-generated-content-inset-v1',
  );
  static const List<BoxObservationSourceSpec> extendedComponentFrames = [
    bannerFrame,
    descriptionCardFrame,
    formattedInputFrame,
    frameContentInset,
  ];

  static const avatarFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'avatar-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'avatar-generated-frame-v1',
    webAdapterId: 'avatar-generated-frame-v1',
  );
  static const codeSnippetFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'code-snippet-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'code-snippet-generated-frame-v1',
    webAdapterId: 'code-snippet-generated-frame-v1',
  );
  static const statFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'stat-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'stat-generated-frame-v1',
    webAdapterId: 'stat-generated-frame-v1',
  );
  static const validationBadgeFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'validation-badge-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'validation-badge-generated-frame-v1',
    webAdapterId: 'validation-badge-generated-frame-v1',
  );

  // MockupCode's Web body and Native frame need a separate quantity decision.
  // A closed constructor alone does not establish equal source units.
  static const List<BoxObservationSourceSpec> displayComponentFrames = [
    avatarFrame,
    codeSnippetFrame,
    statFrame,
    validationBadgeFrame,
  ];

  static const numberInputFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'number-input-generated-field-frame',
    quantityId: quantity,
    nativeAdapterId: 'number-input-generated-field-frame-v1',
    webAdapterId: 'number-input-generated-field-frame-v1',
  );
  static const chipFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'chip-generated-frame',
    quantityId: quantity,
    nativeAdapterId: 'chip-generated-frame-v1',
    webAdapterId: 'chip-generated-frame-v1',
  );

  static const List<BoxObservationSourceSpec> controlShellFrames = [
    numberInputFrame,
    chipFrame,
  ];

  // These units observe the generated content Padding parameter. They do not
  // reinterpret decoration/divider paint as an additional physical inset.
  static const appBarSolidContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'app-bar-solid-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'app-bar-solid-content-inset-v1',
    webAdapterId: 'app-bar-solid-content-inset-v1',
  );
  static const emptyStateContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'empty-state-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'empty-state-generated-content-inset-v1',
    webAdapterId: 'empty-state-generated-content-inset-v1',
  );
  static const List<BoxObservationSourceSpec> solidLayoutFrames = [
    appBarSolidContentInset,
    emptyStateContentInset,
  ];

  static const labelInlineHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'label-generated-inline-host',
    quantityId: quantity,
    nativeAdapterId: 'label-generated-inline-host-v1',
    webAdapterId: 'label-generated-inline-host-v1',
  );
  static const linkInlineHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'link-generated-inline-host',
    quantityId: quantity,
    nativeAdapterId: 'link-generated-inline-host-v1',
    webAdapterId: 'link-generated-inline-host-v1',
  );
  static const List<BoxObservationSourceSpec> inlineHostFrames = [
    labelInlineHost,
    linkInlineHost,
  ];

  static const maskClipHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'mask-generated-clip-host',
    quantityId: quantity,
    nativeAdapterId: 'mask-generated-clip-host-v1',
    webAdapterId: 'mask-generated-clip-host-v1',
  );
  static const hoverEffectHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'hover-generated-effect-host',
    quantityId: quantity,
    nativeAdapterId: 'hover-generated-effect-host-v1',
    webAdapterId: 'hover-generated-effect-host-v1',
  );
  static const indicatorOverlayHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'indicator-generated-overlay-host',
    quantityId: quantity,
    nativeAdapterId: 'indicator-generated-overlay-host-v1',
    webAdapterId: 'indicator-generated-overlay-host-v1',
  );
  static const List<BoxObservationSourceSpec> proxyHostFrames = [
    maskClipHost,
    hoverEffectHost,
    indicatorOverlayHost,
  ];

  // The parameterless documentation example creates this descendant bubble.
  // This does not make an arbitrary Chat's supplied bubble its own padding.
  static const docsChatSingleBubble = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'documentation-chat-single-bubble-frame',
    quantityId: quantity,
    nativeAdapterId: 'docs-chat-single-bubble-frame-v1',
    webAdapterId: 'docs-chat-single-bubble-frame-v1',
  );
  static const List<BoxObservationSourceSpec> documentationBubbleFrames = [
    docsChatSingleBubble,
  ];

  static const stepsSequenceHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'steps-generated-sequence-host',
    quantityId: quantity,
    nativeAdapterId: 'steps-generated-sequence-host-v1',
    webAdapterId: 'steps-generated-sequence-host-v1',
  );
  static const stepperVerticalSequenceHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'stepper-vertical-sequence-host',
    quantityId: quantity,
    nativeAdapterId: 'stepper-vertical-sequence-host-v1',
    webAdapterId: 'stepper-vertical-sequence-host-v1',
  );
  static const aspectRatioLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'aspect-ratio-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'aspect-ratio-generated-layout-host-v1',
    webAdapterId: 'aspect-ratio-generated-layout-host-v1',
  );
  static const clickableInteractionHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'clickable-generated-interaction-host',
    quantityId: quantity,
    nativeAdapterId: 'clickable-generated-interaction-host-v1',
    webAdapterId: 'clickable-generated-interaction-host-v1',
  );
  static const focusOutlinePassThroughHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'focus-outline-generated-pass-through-host',
    quantityId: quantity,
    nativeAdapterId: 'focus-outline-generated-pass-through-host-v1',
    webAdapterId: 'focus-outline-generated-pass-through-host-v1',
  );
  static const switchFieldControlRow = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'switch-field-generated-control-row',
    quantityId: quantity,
    nativeAdapterId: 'switch-field-generated-control-row-v1',
    webAdapterId: 'switch-field-generated-control-row-v1',
  );
  static const List<BoxObservationSourceSpec> layoutHostFrames = [
    stepsSequenceHost,
    stepperVerticalSequenceHost,
    aspectRatioLayoutHost,
    clickableInteractionHost,
    focusOutlinePassThroughHost,
    switchFieldControlRow,
  ];

  static const kbdSingleKeycapContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'kbd-single-keycap-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'kbd-single-keycap-content-inset-v1',
    webAdapterId: 'kbd-single-keycap-content-inset-v1',
  );
  static const appBarMediumToolbarContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'app-bar-medium-toolbar-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'app-bar-medium-toolbar-content-inset-v1',
    webAdapterId: 'app-bar-medium-toolbar-content-inset-v1',
  );
  // The documentation viewport is the Example's actual OutlinedContainer.
  // It is a separate unit from the supplied RefreshTrigger/pull/scroll host.
  // Declaring it does not resolve the legacy RefreshTrigger root quantity.
  static const docsRefreshViewportContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'documentation-refresh-viewport-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'documentation-refresh-viewport-content-inset-v1',
    webAdapterId: 'documentation-refresh-viewport-content-inset-v1',
  );
  static const List<BoxObservationSourceSpec> contentParameterFrames = [
    kbdSingleKeycapContentInset,
    appBarMediumToolbarContentInset,
    docsRefreshViewportContentInset,
  ];

  static const loadingSizeHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'loading-generated-size-host',
    quantityId: quantity,
    nativeAdapterId: 'loading-generated-size-host-v1',
    webAdapterId: 'loading-generated-size-host-v1',
  );
  static const List<BoxObservationSourceSpec> loadingHostFrames = [
    loadingSizeHost,
  ];

  static const statusDotContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'status-generated-dot-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'status-generated-dot-content-inset-v1',
    webAdapterId: 'status-generated-dot-content-inset-v1',
  );
  static const tagLabelContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'tag-generated-label-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'tag-generated-label-content-inset-v1',
    webAdapterId: 'tag-generated-label-content-inset-v1',
  );
  static const skeletonCircularContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'skeleton-circular-block-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'skeleton-circular-block-content-inset-v1',
    webAdapterId: 'skeleton-circular-block-content-inset-v1',
  );
  static const List<BoxObservationSourceSpec> displayParameterFrames = [
    statusDotContentInset,
    tagLabelContentInset,
    skeletonCircularContentInset,
  ];

  static const menuItemRowContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'menu-item-generated-row-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'menu-item-generated-row-content-inset-v1',
    webAdapterId: 'menu-item-generated-row-content-inset-v1',
  );
  static const carouselBannerStripContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'carousel-banner-generated-strip-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'carousel-banner-generated-strip-content-inset-v1',
    webAdapterId: 'carousel-banner-generated-strip-content-inset-v1',
  );
  static const panelHeaderContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'panel-header-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'panel-header-generated-content-inset-v1',
    webAdapterId: 'panel-header-generated-content-inset-v1',
  );
  static const List<BoxObservationSourceSpec> explicitContentInsetFrames = [
    menuItemRowContentInset,
    carouselBannerStripContentInset,
    panelHeaderContentInset,
  ];

  static const calendarLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'calendar-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'calendar-generated-layout-host-v1',
    webAdapterId: 'calendar-generated-layout-host-v1',
  );
  static const definitionListLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'definition-list-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'definition-list-generated-layout-host-v1',
    webAdapterId: 'definition-list-generated-layout-host-v1',
  );
  static const List<BoxObservationSourceSpec> collectionLayoutHostFrames = [
    calendarLayoutHost,
    definitionListLayoutHost,
  ];

  // These units declare actual component-owned layout/content seats.
  // Generated descendants remain separate from the unchanged capture root.
  static const responsiveFlexLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'responsive-row-column-generated-flex-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'responsive-row-column-generated-flex-layout-host-v1',
    webAdapterId: 'responsive-row-column-generated-flex-layout-host-v1',
  );
  static const responsiveContainerContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'responsive-container-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'responsive-container-generated-content-inset-v1',
    webAdapterId: 'responsive-container-generated-content-inset-v1',
  );
  static const responsiveGridLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'responsive-grid-generated-grid-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'responsive-grid-generated-grid-layout-host-v1',
    webAdapterId: 'responsive-grid-generated-grid-layout-host-v1',
  );
  static const stackLayoutOverlapHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'stack-layout-generated-overlap-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'stack-layout-generated-overlap-layout-host-v1',
    webAdapterId: 'stack-layout-generated-overlap-layout-host-v1',
  );
  static const indexedSwitcherLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'indexed-switcher-generated-indexed-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'indexed-switcher-generated-indexed-layout-host-v1',
    webAdapterId: 'indexed-switcher-generated-indexed-layout-host-v1',
  );
  static const swapOverlapLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'swap-generated-overlap-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'swap-generated-overlap-layout-host-v1',
    webAdapterId: 'swap-generated-overlap-layout-host-v1',
  );
  static const dividerLabelledSequenceHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'divider-generated-labelled-sequence-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'divider-generated-labelled-sequence-layout-host-v1',
    webAdapterId: 'divider-generated-labelled-sequence-layout-host-v1',
  );
  static const List<BoxObservationSourceSpec> layoutStructureFrames = [
    responsiveFlexLayoutHost,
    responsiveContainerContentInset,
    responsiveGridLayoutHost,
    stackLayoutOverlapHost,
    indexedSwitcherLayoutHost,
    swapOverlapLayoutHost,
    dividerLabelledSequenceHost,
  ];

  // Closed source-unit identities only. A registered tuple does not prove
  // any current frame, padding allocation, absence, or observation eligibility.
  // Current track own inset; actual allocation premise required before reading.
  static const toggleGroupTrackContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'toggle-group-generated-track-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'toggle-group-generated-track-content-inset-v1',
    webAdapterId: 'toggle-group-generated-track-content-inset-v1',
  );
  // Whole field arrangement; control, label/footer insets and gaps excluded.
  static const formFieldLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'form-field-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'form-field-generated-layout-host-v1',
    webAdapterId: 'form-field-generated-layout-host-v1',
  );
  // Label row arrangement; glyph metrics and required-marker gap excluded.
  static const formLabelRowLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'form-label-generated-label-row-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'form-label-generated-label-row-layout-host-v1',
    webAdapterId: 'form-label-generated-label-row-layout-host-v1',
  );
  // Whole rows arrangement; public rows and their own padding are foreign.
  static const listingRowsLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'listing-generated-rows-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'listing-generated-rows-layout-host-v1',
    webAdapterId: 'listing-generated-rows-layout-host-v1',
  );
  // List arrangement; complete supplied OptionItem content is foreign.
  static const optionListLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'option-list-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'option-list-generated-layout-host-v1',
    webAdapterId: 'option-list-generated-layout-host-v1',
  );
  // Current source header inset; body top-only inset is a separate quantity.
  static const disclosureHeaderContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'disclosure-generated-header-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'disclosure-generated-header-content-inset-v1',
    webAdapterId: 'disclosure-generated-header-content-inset-v1',
  );
  // Section group arrangement; complete supplied items are foreign.
  static const disclosureGroupLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'disclosure-group-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'disclosure-group-generated-layout-host-v1',
    webAdapterId: 'disclosure-group-generated-layout-host-v1',
  );
  // Section arrangement; trigger and content wrapper insets excluded.
  static const collapsibleSectionLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'collapsible-generated-section-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'collapsible-generated-section-layout-host-v1',
    webAdapterId: 'collapsible-generated-section-layout-host-v1',
  );
  // Pane-flow arrangement; overlays and whole supplied pane content excluded.
  static const resizablePaneLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'resizable-generated-pane-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'resizable-generated-pane-layout-host-v1',
    webAdapterId: 'resizable-generated-pane-layout-host-v1',
  );
  // Trail arrangement; generated per-item padding and glyphs excluded.
  static const breadcrumbTrailLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'breadcrumb-generated-trail-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'breadcrumb-generated-trail-layout-host-v1',
    webAdapterId: 'breadcrumb-generated-trail-layout-host-v1',
  );
  static const List<BoxObservationSourceSpec> formCollectionFrames = [
    toggleGroupTrackContentInset,
    formFieldLayoutHost,
    formLabelRowLayoutHost,
    listingRowsLayoutHost,
    optionListLayoutHost,
  ];
  static const List<BoxObservationSourceSpec> sectionLayoutFrames = [
    disclosureHeaderContentInset,
    disclosureGroupLayoutHost,
    collapsibleSectionLayoutHost,
    resizablePaneLayoutHost,
    breadcrumbTrailLayoutHost,
  ];

  // These identities name separately audited content units. Registration alone
  // supplies no current owner, inset, absence proof or recipe eligibility.
  static const basicContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'basic-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'basic-generated-content-inset-v1',
    webAdapterId: 'basic-generated-content-inset-v1',
  );
  static const disclosureBadgeSolidContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'disclosure-badge-solid-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'disclosure-badge-solid-content-inset-v1',
    webAdapterId: 'disclosure-badge-solid-content-inset-v1',
  );
  static const multipleChoiceLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'multiple-choice-generated-options-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'multiple-choice-generated-options-layout-host-v1',
    webAdapterId: 'multiple-choice-generated-options-layout-host-v1',
  );
  static const pageHeaderLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'page-header-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'page-header-generated-layout-host-v1',
    webAdapterId: 'page-header-generated-layout-host-v1',
  );
  static const sidebarOuterLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'sidebar-generated-outer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'sidebar-generated-outer-layout-host-v1',
    webAdapterId: 'sidebar-generated-outer-layout-host-v1',
  );
  static const tabPaneBarContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'tab-pane-generated-bar-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'tab-pane-generated-bar-content-inset-v1',
    webAdapterId: 'tab-pane-generated-bar-content-inset-v1',
  );
  static const treeOuterLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'tree-generated-outer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'tree-generated-outer-layout-host-v1',
    webAdapterId: 'tree-generated-outer-layout-host-v1',
  );
  static const timelineSequenceLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'timeline-generated-sequence-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'timeline-generated-sequence-layout-host-v1',
    webAdapterId: 'timeline-generated-sequence-layout-host-v1',
  );
  static const categoryBreakdownLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'category-breakdown-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'category-breakdown-generated-layout-host-v1',
    webAdapterId: 'category-breakdown-generated-layout-host-v1',
  );
  static const trendChartOuterLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'trend-chart-generated-outer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'trend-chart-generated-outer-layout-host-v1',
    webAdapterId: 'trend-chart-generated-outer-layout-host-v1',
  );
  static const windowPanelFrameContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'window-panel-generated-frame-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'window-panel-generated-frame-content-inset-v1',
    webAdapterId: 'window-panel-generated-frame-content-inset-v1',
  );
  static const textFieldContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'text-field-generated-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'text-field-generated-content-inset-v1',
    webAdapterId: 'text-field-generated-content-inset-v1',
  );
  static const validatedLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'validated-generated-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'validated-generated-layout-host-v1',
    webAdapterId: 'validated-generated-layout-host-v1',
  );
  static const validatorHintMessageLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'validator-hint-generated-message-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'validator-hint-generated-message-layout-host-v1',
    webAdapterId: 'validator-hint-generated-message-layout-host-v1',
  );
  static const scrollAreaViewportLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'scroll-area-generated-viewport-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'scroll-area-generated-viewport-layout-host-v1',
    webAdapterId: 'scroll-area-generated-viewport-layout-host-v1',
  );
  static const fadeScrollViewportLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'fade-scroll-generated-viewport-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'fade-scroll-generated-viewport-layout-host-v1',
    webAdapterId: 'fade-scroll-generated-viewport-layout-host-v1',
  );
  static const overflowMarqueeViewportLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'overflow-marquee-generated-viewport-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'overflow-marquee-generated-viewport-layout-host-v1',
    webAdapterId: 'overflow-marquee-generated-viewport-layout-host-v1',
  );
  static const kbdKeySequenceLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'kbd-generated-key-sequence-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'kbd-generated-key-sequence-layout-host-v1',
    webAdapterId: 'kbd-generated-key-sequence-layout-host-v1',
  );
  static const List<BoxObservationSourceSpec> structuredRootFrames = [
    basicContentInset,
    disclosureBadgeSolidContentInset,
    multipleChoiceLayoutHost,
    pageHeaderLayoutHost,
    sidebarOuterLayoutHost,
    tabPaneBarContentInset,
    treeOuterLayoutHost,
    timelineSequenceLayoutHost,
    categoryBreakdownLayoutHost,
    trendChartOuterLayoutHost,
    windowPanelFrameContentInset,
  ];

  static const List<BoxObservationSourceSpec> validationViewportFrames = [
    textFieldContentInset,
    validatedLayoutHost,
    validatorHintMessageLayoutHost,
    scrollAreaViewportLayoutHost,
    fadeScrollViewportLayoutHost,
    overflowMarqueeViewportLayoutHost,
    kbdKeySequenceLayoutHost,
  ];

  static const themeControllerOptionGridLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'theme-controller-generated-option-grid-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'theme-controller-generated-option-grid-layout-host-v1',
    webAdapterId: 'theme-controller-generated-option-grid-layout-host-v1',
  );

  static const trackerSegmentRowLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'tracker-generated-segment-row-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'tracker-generated-segment-row-layout-host-v1',
    webAdapterId: 'tracker-generated-segment-row-layout-host-v1',
  );

  static const bottomSheetOuterLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'bottom-sheet-generated-outer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'bottom-sheet-generated-outer-layout-host-v1',
    webAdapterId: 'bottom-sheet-generated-outer-layout-host-v1',
  );

  static const swiperTriggerLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'swiper-generated-trigger-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'swiper-generated-trigger-layout-host-v1',
    webAdapterId: 'swiper-generated-trigger-layout-host-v1',
  );

  static const diffViewerLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'diff-generated-viewer-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'diff-generated-viewer-layout-host-v1',
    webAdapterId: 'diff-generated-viewer-layout-host-v1',
  );

  static const commandSearchTriggerContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'command-search-generated-trigger-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'command-search-generated-trigger-content-inset-v1',
    webAdapterId: 'command-search-generated-trigger-content-inset-v1',
  );

  static const navigationBarItemsContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'navigation-bar-generated-items-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'navigation-bar-generated-items-content-inset-v1',
    webAdapterId: 'navigation-bar-generated-items-content-inset-v1',
  );

  static const dockBarContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'dock-generated-bar-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'dock-generated-bar-content-inset-v1',
    webAdapterId: 'dock-generated-bar-content-inset-v1',
  );

  static const List<BoxObservationSourceSpec> dataOverlayLayoutFrames = [
    themeControllerOptionGridLayoutHost,
    trackerSegmentRowLayoutHost,
    bottomSheetOuterLayoutHost,
    swiperTriggerLayoutHost,
    diffViewerLayoutHost,
  ];

  static const List<BoxObservationSourceSpec> navigationTriggerParameterFrames =
      [
        commandSearchTriggerContentInset,
        navigationBarItemsContentInset,
        dockBarContentInset,
      ];

  static const iconVisualFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'icon-generated-visual-frame-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'icon-generated-visual-frame-content-inset-v1',
    webAdapterId: 'icon-generated-visual-frame-content-inset-v1',
  );

  static const numberTickerTextLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'number-ticker-generated-text-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'number-ticker-generated-text-layout-host-v1',
    webAdapterId: 'number-ticker-generated-text-layout-host-v1',
  );

  static const skeletonTextLinesLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'skeleton-text-generated-lines-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'skeleton-text-generated-lines-layout-host-v1',
    webAdapterId: 'skeleton-text-generated-lines-layout-host-v1',
  );

  static const countdownValueLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'countdown-generated-value-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'countdown-generated-value-layout-host-v1',
    webAdapterId: 'countdown-generated-value-layout-host-v1',
  );

  static const List<BoxObservationSourceSpec> visualValueFrames = [
    iconVisualFrame,
    numberTickerTextLayoutHost,
    skeletonTextLinesLayoutHost,
    countdownValueLayoutHost,
  ];

  static const mockupDeviceBodyFrame = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'mockup-device-generated-body-frame-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'mockup-device-generated-body-frame-content-inset-v1',
    webAdapterId: 'mockup-device-generated-body-frame-content-inset-v1',
  );

  static const joinStripLayoutHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'join-generated-strip-layout-host',
    quantityId: quantity,
    nativeAdapterId: 'join-generated-strip-layout-host-v1',
    webAdapterId: 'join-generated-strip-layout-host-v1',
  );

  static const tableGridContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'table-generated-grid-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'table-generated-grid-content-inset-v1',
    webAdapterId: 'table-generated-grid-content-inset-v1',
  );

  // Browser keeps its existing mockupBrowserFrame tuple and reader.
  // These declarations alone do not register recipes or grant source authority.
  static const List<BoxObservationSourceSpec> framedCollectionFrames = [
    mockupDeviceBodyFrame,
    joinStripLayoutHost,
    tableGridContentInset,
  ];

  /// The classic showcase's outer allocation, not Text glyphs or line boxes.
  static const textShowcaseOuterPadding = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'classic-text-showcase-generated-padding-host',
    quantityId: quantity,
    nativeAdapterId: 'classic-text-showcase-outer-padding-v1',
    webAdapterId: 'classic-text-showcase-outer-padding-v1',
  );

  /// The classic compound showcase allocation, not any contained product.
  static const showcaseAllocationHost = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'classic-compound-showcase-allocation-host',
    quantityId: quantity,
    nativeAdapterId: 'classic-compound-showcase-allocation-host-v1',
    webAdapterId: 'classic-compound-showcase-allocation-host-v1',
  );

  /// Exact classic Breakpoint showcase Container/DIV content allocation.
  /// The viewport readout remains an opaque child, not a source authority.
  static const breakpointShowcaseContentInset = BoxObservationSourceSpec(
    schemaVersion: 1,
    logicalUnitId: 'classic-breakpoint-showcase-content-inset',
    quantityId: quantity,
    nativeAdapterId: 'classic-breakpoint-showcase-content-inset-v1',
    webAdapterId: 'classic-breakpoint-showcase-content-inset-v1',
  );

  String? get validationError {
    if (schemaVersion != 1) return 'UNSUPPORTED_BOX_SOURCE_VERSION';
    if (quantityId != quantity) return 'UNSUPPORTED_BOX_QUANTITY';
    for (final supported in [
      outlined,
      docsStage,
      declaredLayout,
      wholeDocCard,
      docsSizePreview,
      docsPlayground,
      ...componentFrames,
      ...extendedComponentFrames,
      ...displayComponentFrames,
      ...controlShellFrames,
      ...solidLayoutFrames,
      ...inlineHostFrames,
      ...proxyHostFrames,
      ...documentationBubbleFrames,
      ...layoutHostFrames,
      ...contentParameterFrames,
      ...loadingHostFrames,
      ...displayParameterFrames,
      ...explicitContentInsetFrames,
      ...collectionLayoutHostFrames,
      ...layoutStructureFrames,
      ...formCollectionFrames,
      ...sectionLayoutFrames,
      ...structuredRootFrames,
      ...publicWrapperFrames,
      ...validationViewportFrames,
      ...dataOverlayLayoutFrames,
      ...navigationTriggerParameterFrames,
      ...visualValueFrames,
      ...framedCollectionFrames,
      textShowcaseOuterPadding,
      showcaseAllocationHost,
      bottomActionBarContentInset,
      breakpointShowcaseContentInset,
    ]) {
      if (logicalUnitId == supported.logicalUnitId &&
          nativeAdapterId == supported.nativeAdapterId &&
          webAdapterId == supported.webAdapterId) {
        return null;
      }
    }
    return 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH';
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'logicalUnitId': logicalUnitId,
    'quantityId': quantityId,
    'nativeAdapterId': nativeAdapterId,
    'webAdapterId': webAdapterId,
  };

  @override
  bool operator ==(Object other) =>
      other is BoxObservationSourceSpec &&
      schemaVersion == other.schemaVersion &&
      logicalUnitId == other.logicalUnitId &&
      quantityId == other.quantityId &&
      nativeAdapterId == other.nativeAdapterId &&
      webAdapterId == other.webAdapterId;

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    logicalUnitId,
    quantityId,
    nativeAdapterId,
    webAdapterId,
  );
}
