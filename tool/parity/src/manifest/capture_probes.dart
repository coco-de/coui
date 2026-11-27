import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/shared/preview_layout.dart';

import '../model/box_observation_source_spec.dart';
import '../model/probe_spec.dart';
import '../model/property_field.dart';

bool _requiresStage(String component, String variant) =>
    docsPreviewFillsWidth(component, variant) &&
    (component == 'mockup' ||
        component == 'mockup-device' ||
        component == 'responsive-container');

/// A stale root-only manifest would lose the full-stage check after cropping.
/// Reject it at capture time; historical reports remain readable.
void requireCaptureProbes({
  required String component,
  required String variant,
  required Iterable<String> roles,
  Iterable<BoxObservationSourceSpec?> boxObservationSources = const [],
}) {
  if (_requiresStage(component, variant) &&
      !roles.toSet().containsAll({'root', 'stage'})) {
    throw FormatException(
      '$component/$variant requires root and stage probes; regenerate manifest',
    );
  }
  for (final source in boxObservationSources) {
    if ((BoxObservationSourceSpec.displayComponentFrames.contains(source) ||
            BoxObservationSourceSpec.controlShellFrames.contains(source) ||
            BoxObservationSourceSpec.solidLayoutFrames.contains(source) ||
            BoxObservationSourceSpec.inlineHostFrames.contains(source) ||
            BoxObservationSourceSpec.proxyHostFrames.contains(source) ||
            BoxObservationSourceSpec.layoutHostFrames.contains(source) ||
            BoxObservationSourceSpec.contentParameterFrames.contains(source) ||
            BoxObservationSourceSpec.loadingHostFrames.contains(source) ||
            BoxObservationSourceSpec.displayParameterFrames.contains(source) ||
            BoxObservationSourceSpec.explicitContentInsetFrames.contains(
              source,
            ) ||
            BoxObservationSourceSpec.collectionLayoutHostFrames.contains(
              source,
            ) ||
            BoxObservationSourceSpec.layoutStructureFrames.contains(source) ||
            BoxObservationSourceSpec.formCollectionFrames.contains(source) ||
            BoxObservationSourceSpec.sectionLayoutFrames.contains(source) ||
            BoxObservationSourceSpec.structuredRootFrames.contains(source) ||
            BoxObservationSourceSpec.validationViewportFrames.contains(
              source,
            ) ||
            BoxObservationSourceSpec.dataOverlayLayoutFrames.contains(
              source,
            ) ||
            BoxObservationSourceSpec.navigationTriggerParameterFrames.contains(
              source,
            ) ||
            BoxObservationSourceSpec.visualValueFrames.contains(source) ||
            BoxObservationSourceSpec.framedCollectionFrames.contains(source) ||
            source?.logicalUnitId ==
                BoxObservationSourceSpec
                    .textShowcaseOuterPadding
                    .logicalUnitId ||
            source?.logicalUnitId ==
                BoxObservationSourceSpec.scopeAllocationHost.logicalUnitId ||
            source?.logicalUnitId ==
                BoxObservationSourceSpec.showcaseAllocationHost.logicalUnitId ||
            source?.logicalUnitId ==
                BoxObservationSourceSpec
                    .bottomActionBarContentInset
                    .logicalUnitId ||
            source?.logicalUnitId ==
                BoxObservationSourceSpec
                    .breakpointShowcaseContentInset
                    .logicalUnitId ||
            BoxObservationSourceSpec.documentationBubbleFrames.contains(
              source,
            )) &&
        source != _componentBoxSource(component, variant)) {
      throw FormatException(
        '$component/$variant does not construct the declared component frame',
      );
    }
  }
}

/// Root measures the same capped body on both engines. A second stage
/// probe preserves its alignment, hardware and shadows outside that box.
List<ProbeSpec> captureProbes({
  required String key,
  required String component,
  required String variant,
  required String flutterClassName,
  DocsScene? docsScene,
}) {
  if (docsScene != null && docsScene.reference != variant) {
    throw const FormatException(
      'The source scene does not match the requested manifest variant',
    );
  }
  // The default source constructor returns one primitive. Its chain demo
  // returns a collection and needs a different logical-unit declaration.
  final root = rootProbeSpec(
    key: key,
    flutterClassName: flutterClassName,
    boxObservationSource:
        component == 'outlined-container' && variant == 'default'
        ? BoxObservationSourceSpec.outlined
        : _componentBoxSource(component, variant),
  );
  if (variant.startsWith(docsScenePrefix)) {
    final frame = '[data-parity-key="$key"] [data-docs-scene="$variant"]';
    return [
      ProbeSpec(
        role: 'root',
        webSelector:
            '$frame > .content > .docs-stage, '
            '$frame > .content > .docs-cards > .docs-card, '
            '$frame > .content > .docs-anatomy > .docs-anatomy-stage, '
            '$frame > .content > .docs-size-spec, '
            '$frame > .content .docs-playground-stage',
        flutterFinder: 'byType:$flutterClassName',
        nativeBoxSource: flutterClassName == '_PlaygroundFrame'
            ? 'docs-playground-frame-padding-v1'
            : 'docs-model-frame-padding-v1',
        boxObservationSource: _documentationBoxSource(docsScene),
        fields: root.fields,
      ),
    ];
  }
  if (!_requiresStage(component, variant)) return [root];
  return [
    ProbeSpec(
      role: 'root',
      webSelector: '[data-parity-key="$key"] > * > *',
      flutterFinder: 'leadingAlignChild',
      nativeBoxSource: root.nativeBoxSource,
      boxObservationSource: root.boxObservationSource,
      fields: root.fields,
    ),
    ProbeSpec(
      role: 'stage',
      webSelector: root.webSelector,
      flutterFinder: 'previewRoot',
      fields: const {PropertyField.widthPx, PropertyField.heightPx},
    ),
  ];
}

// These are closed registry-construction recipes, not whole-family grants.
// Runtime adapters still require the exact example, actual generated child,
// producer-owned frame and public supplied-content boundaries on each backend.
BoxObservationSourceSpec? _componentBoxSource(
  String component,
  String variant,
) => switch ((component, variant)) {
  ('breakpoint', 'default') =>
    BoxObservationSourceSpec.breakpointShowcaseContentInset,
  (
    'text',
    'typography-display' ||
        'typography-headline' ||
        'typography-title' ||
        'typography-body' ||
        'typography-weight' ||
        'typography-primitive' ||
        'colors-brand' ||
        'colors-status' ||
        'colors-surface' ||
        'modifiers' ||
        'wrap' ||
        'keep-all' ||
        'textstyle' ||
        'opacity' ||
        'rich',
  ) =>
    BoxObservationSourceSpec.textShowcaseOuterPadding,
  ('icon', 'default' || 'search' || 'favorite') =>
    BoxObservationSourceSpec.iconVisualFrame,
  ('drag', 'default' || 'board' || 'overlay') ||
  ('subfocus', 'default') => BoxObservationSourceSpec.scopeAllocationHost,
  ('number-ticker', 'default') =>
    BoxObservationSourceSpec.numberTickerTextLayoutHost,
  ('card-image', 'default') ||
  ('hidden', 'default') ||
  ('window', 'default') ||
  ('draggable-panel', 'default' || 'outside') ||
  ('scrollable-client', 'default') ||
  ('table', 'scrollable') => BoxObservationSourceSpec.showcaseAllocationHost,
  ('bottom-action-bar', 'default') ||
  ('bottom-action-bar', 'horizontal') ||
  (
    'bottom-action-bar',
    'summary-compact',
  ) => BoxObservationSourceSpec.bottomActionBarContentInset,
  ('mockup-foldable', 'angle' || 'default') ||
  ('scaffold', 'default') ||
  ('bottom-action-bar', 'scaffold') ||
  ('scrollview', 'default') ||
  ('app-bar', 'glass' || 'foldable') ||
  ('swipe-actions', 'scope') => BoxObservationSourceSpec.showcaseAllocationHost,
  ('chat', 'default' || 'plain' || 'tail-corner' || 'tail-top') =>
    BoxObservationSourceSpec.showcaseAllocationHost,
  ('chip', 'selected' || 'variant' || 'shape' || 'cast-motion' || 'prefix') =>
    BoxObservationSourceSpec.showcaseAllocationHost,
  ('skeleton', 'default') => BoxObservationSourceSpec.showcaseAllocationHost,
  ('step-item', 'default') => BoxObservationSourceSpec.showcaseAllocationHost,
  ('progress', 'tone') => BoxObservationSourceSpec.showcaseAllocationHost,
  ('skeleton', 'text') => BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
  ('countdown', 'default') => BoxObservationSourceSpec.countdownValueLayoutHost,
  ('mockup', 'phone' || 'tablet' || 'landscape') ||
  (
    'mockup-device',
    'default' || 'flat',
  ) => BoxObservationSourceSpec.mockupDeviceBodyFrame,
  ('mockup', 'browser' || 'app') => BoxObservationSourceSpec.mockupBrowserFrame,
  ('join', 'default' || 'input' || 'vertical') =>
    BoxObservationSourceSpec.joinStripLayoutHost,
  ('table', 'default' || 'resizable') =>
    BoxObservationSourceSpec.tableGridContentInset,
  ('theme-controller', 'default') =>
    BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
  ('tracker', 'default') =>
    BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
  ('bottom-sheet', 'default' || 'close') =>
    BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
  ('swiper', 'default' || 'sheet') =>
    BoxObservationSourceSpec.swiperTriggerLayoutHost,
  ('diff', 'default' || 'text') =>
    BoxObservationSourceSpec.diffViewerLayoutHost,
  ('command-search', 'default') =>
    BoxObservationSourceSpec.commandSearchTriggerContentInset,
  ('navigation-bar', 'default' || 'rail' || 'sidebar') =>
    BoxObservationSourceSpec.navigationBarItemsContentInset,
  ('dock', 'default') => BoxObservationSourceSpec.dockBarContentInset,
  ('code-diff', 'default') => BoxObservationSourceSpec.codeDiffFrame,
  ('command', 'default' || 'scrollable' || 'empty') =>
    BoxObservationSourceSpec.commandPanelFrame,
  ('fieldset', 'default' || 'outlined' || 'plain') =>
    BoxObservationSourceSpec.fieldsetFrame,
  ('item-picker', 'default') => BoxObservationSourceSpec.itemPickerFrame,
  ('mockup-browser', 'default') => BoxObservationSourceSpec.mockupBrowserFrame,
  ('object-input', 'default') => BoxObservationSourceSpec.objectInputFrame,
  (
    'banner',
    'default' ||
        'info' ||
        'warning' ||
        'destructive' ||
        'success' ||
        'solid' ||
        'narrow',
  ) =>
    BoxObservationSourceSpec.bannerFrame,
  (
    'description-card',
    'default' ||
        'filled' ||
        'ghost' ||
        'vertical' ||
        'space-between' ||
        'placeholder',
  ) =>
    BoxObservationSourceSpec.descriptionCardFrame,
  (
    'formatted-input',
    'default' || 'korean-phone' || 'credit-card' || 'date' || 'verify',
  ) =>
    BoxObservationSourceSpec.formattedInputFrame,
  ('frame', 'default' || 'column' || 'dashed' || 'elevated') =>
    BoxObservationSourceSpec.frameContentInset,
  ('avatar', 'default' || 'rounded') => BoxObservationSourceSpec.avatarFrame,
  ('code-snippet', 'default') => BoxObservationSourceSpec.codeSnippetFrame,
  ('stat', 'default' || 'outlined' || 'empty') =>
    BoxObservationSourceSpec.statFrame,
  ('validation-badge', 'default' || 'pending' || 'invalid' || 'medium') =>
    BoxObservationSourceSpec.validationBadgeFrame,
  ('number-input', 'default' || 'filled' || 'error' || 'disabled') =>
    BoxObservationSourceSpec.numberInputFrame,
  ('chip', 'removable' || 'disabled') => BoxObservationSourceSpec.chipFrame,
  (
    'app-bar',
    'default' || 'compact' || 'dense' || 'prominent' || 'centered' || 'text',
  ) =>
    BoxObservationSourceSpec.appBarSolidContentInset,
  ('empty-state', 'default' || 'large' || 'failure' || 'success') =>
    BoxObservationSourceSpec.emptyStateContentInset,
  ('label', 'default' || 'required' || 'with-icon' || 'disabled') =>
    BoxObservationSourceSpec.labelInlineHost,
  ('link', 'default' || 'muted' || 'underline' || 'external' || 'icons') =>
    BoxObservationSourceSpec.linkInlineHost,
  (
    'mask',
    'default' || 'circle' || 'heart' || 'hexagon' || 'star' || 'triangle',
  ) =>
    BoxObservationSourceSpec.maskClipHost,
  ('hover', 'default' || 'fade' || 'shadow') =>
    BoxObservationSourceSpec.hoverEffectHost,
  ('indicator', 'default' || 'bottom-start') =>
    BoxObservationSourceSpec.indicatorOverlayHost,
  (
    'chat',
    'accent' ||
        'error' ||
        'info' ||
        'neutral' ||
        'primary' ||
        'secondary' ||
        'success' ||
        'warning',
  ) =>
    BoxObservationSourceSpec.docsChatSingleBubble,
  ('steps', 'default' || 'horizontal' || 'list') =>
    BoxObservationSourceSpec.stepsSequenceHost,
  ('stepper', 'vertical') =>
    BoxObservationSourceSpec.stepperVerticalSequenceHost,
  ('aspect-ratio-box', 'default') =>
    BoxObservationSourceSpec.aspectRatioLayoutHost,
  ('clickable', 'default') => BoxObservationSourceSpec.clickableInteractionHost,
  ('focus-outline', 'default') =>
    BoxObservationSourceSpec.focusOutlinePassThroughHost,
  ('switch-field', 'default') => BoxObservationSourceSpec.switchFieldControlRow,
  ('kbd', 'single') => BoxObservationSourceSpec.kbdSingleKeycapContentInset,
  ('app-bar', 'medium') =>
    BoxObservationSourceSpec.appBarMediumToolbarContentInset,
  ('refresh-trigger', 'default') =>
    BoxObservationSourceSpec.docsRefreshViewportContentInset,
  ('loading', 'default' || 'dots' || 'bar' || 'pulse') =>
    BoxObservationSourceSpec.loadingSizeHost,
  ('status', 'default' || 'success' || 'warning' || 'error') =>
    BoxObservationSourceSpec.statusDotContentInset,
  ('tag', 'default') => BoxObservationSourceSpec.tagLabelContentInset,
  ('skeleton', 'circle') =>
    BoxObservationSourceSpec.skeletonCircularContentInset,
  ('menu-item', 'default' || 'critical' || 'description') =>
    BoxObservationSourceSpec.menuItemRowContentInset,
  ('carousel-banner', 'default' || 'md') =>
    BoxObservationSourceSpec.carouselBannerStripContentInset,
  ('panel-header', 'default') =>
    BoxObservationSourceSpec.panelHeaderContentInset,
  ('calendar', 'single' || 'range' || 'multi' || 'none' || 'markers') =>
    BoxObservationSourceSpec.calendarLayoutHost,
  ('definition-list', 'default' || 'columns' || 'inline') =>
    BoxObservationSourceSpec.definitionListLayoutHost,
  ('responsive-row-column', 'default' || 'desktop') =>
    BoxObservationSourceSpec.responsiveFlexLayoutHost,
  ('responsive-container', 'default') =>
    BoxObservationSourceSpec.responsiveContainerContentInset,
  ('responsive-grid', 'default' || 'span') =>
    BoxObservationSourceSpec.responsiveGridLayoutHost,
  ('stack-layout', 'default') =>
    BoxObservationSourceSpec.stackLayoutOverlapHost,
  ('indexed-switcher', 'default') =>
    BoxObservationSourceSpec.indexedSwitcherLayoutHost,
  ('swap', 'default' || 'rotate') =>
    BoxObservationSourceSpec.swapOverlapLayoutHost,
  ('divider', 'with-child') =>
    BoxObservationSourceSpec.dividerLabelledSequenceHost,
  ('toggle-group', 'default' || 'vertical') =>
    BoxObservationSourceSpec.toggleGroupTrackContentInset,
  ('form-field', 'default') => BoxObservationSourceSpec.formFieldLayoutHost,
  ('form-label', 'default') => BoxObservationSourceSpec.formLabelRowLayoutHost,
  ('listing', 'default') => BoxObservationSourceSpec.listingRowsLayoutHost,
  ('option-list', 'default') => BoxObservationSourceSpec.optionListLayoutHost,
  ('disclosure', 'default' || 'chain') =>
    BoxObservationSourceSpec.disclosureHeaderContentInset,
  ('disclosure', 'group') => BoxObservationSourceSpec.disclosureGroupLayoutHost,
  ('collapsible', 'default') =>
    BoxObservationSourceSpec.collapsibleSectionLayoutHost,
  ('resizable', 'default') => BoxObservationSourceSpec.resizablePaneLayoutHost,
  ('breadcrumb', 'default') =>
    BoxObservationSourceSpec.breadcrumbTrailLayoutHost,
  ('basic', 'default') => BoxObservationSourceSpec.basicContentInset,
  ('disclosure-badge', 'default' || 'commitment') =>
    BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  ('multiple-choice', 'default') =>
    BoxObservationSourceSpec.multipleChoiceLayoutHost,
  ('page-header', 'default') => BoxObservationSourceSpec.pageHeaderLayoutHost,
  ('sidebar', 'default' || 'two-pane' || 'collapsed') =>
    BoxObservationSourceSpec.sidebarOuterLayoutHost,
  ('tab-pane', 'default' || 'editor-strip') =>
    BoxObservationSourceSpec.tabPaneBarContentInset,
  ('tree', 'default' || 'selected') =>
    BoxObservationSourceSpec.treeOuterLayoutHost,
  ('timeline', 'default') =>
    BoxObservationSourceSpec.timelineSequenceLayoutHost,
  ('category-breakdown', 'default' || 'donut') =>
    BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  ('trend-chart', 'default' || 'bar') =>
    BoxObservationSourceSpec.trendChartOuterLayoutHost,
  ('window-panel', 'default') =>
    BoxObservationSourceSpec.windowPanelFrameContentInset,
  ('formatter', 'default') => BoxObservationSourceSpec.textFieldContentInset,
  ('validated', 'default') => BoxObservationSourceSpec.validatedLayoutHost,
  ('validator-hint', 'default') =>
    BoxObservationSourceSpec.validatorHintMessageLayoutHost,
  ('scroll-area', 'default') =>
    BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
  ('fade-scroll', 'default' || 'horizontal' || 'with-scrollbar') =>
    BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  ('overflow-marquee', 'default') =>
    BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
  ('kbd', 'default' || 'combo' || 'four') =>
    BoxObservationSourceSpec.kbdKeySequenceLayoutHost,
  _ => null,
};

BoxObservationSourceSpec? _documentationBoxSource(DocsScene? scene) {
  if (scene == null) return null;
  if (scene.tag == 'Playground') {
    return BoxObservationSourceSpec.docsPlayground;
  }
  if (scene.tag == 'SizeSpec' &&
      scene.flutterOwnerType == 'FlutterDocsSizeSpec') {
    return BoxObservationSourceSpec.docsSizePreview;
  }
  if (scene.tag == 'Card') {
    final serialized = scene.toJson();
    if (scene.cardIndex == 0 &&
        serialized['captureUnit'] == 'whole-card' &&
        scene.nativeCardAttributes != null &&
        scene.nativeCardBody != null) {
      // renderFlutterScene's Card branch constructs the original standalone
      // view with exactly one generated card. The backend adapter must still
      // verify actual cardinality, identity and public content boundaries.
      return BoxObservationSourceSpec.wholeDocCard;
    }
    return null;
  }
  if (const {'Preview', 'VariantRow', 'Anatomy'}.contains(scene.tag) &&
      scene.flutterOwnerType == 'DocsStage') {
    return BoxObservationSourceSpec.docsStage;
  }
  return null;
}
