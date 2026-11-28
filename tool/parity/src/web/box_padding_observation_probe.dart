import 'dart:convert';

import 'package:coui_web/src/util/web_constants.dart'
    show kWebLocalSurfaceMarker, kWebSurfaceMarker;

import '../model/box_observation_source_spec.dart';
import 'bottom_action_bar_ssr_source.dart';
import 'box_padding_chat_bubble_units_probe.dart';
import 'box_padding_collection_layout_host_units_probe.dart';
import 'box_padding_component_units_probe.dart';
import 'box_padding_content_parameter_units_probe.dart';
import 'box_padding_control_shell_units_probe.dart';
import 'box_padding_data_overlay_layout_units_probe.dart';
import 'box_padding_display_parameter_units_probe.dart';
import 'box_padding_explicit_content_inset_units_probe.dart';
import 'box_padding_extended_component_units_probe.dart';
import 'box_padding_form_collection_units_probe.dart';
import 'box_padding_framed_collection_units_probe.dart';
import 'box_padding_inline_host_units_probe.dart';
import 'box_padding_layout_host_units_probe.dart';
import 'box_padding_loading_host_units_probe.dart';
import 'box_padding_navigation_trigger_units_probe.dart';
import 'box_padding_playground_units_probe.dart';
import 'box_padding_proxy_host_units_probe.dart';
import 'box_padding_responsive_layout_units_probe.dart';
import 'box_padding_section_layout_units_probe.dart';
import 'box_padding_sequence_layout_units_probe.dart';
import 'box_padding_solid_layout_units_probe.dart';
import 'box_padding_structured_root_units_probe.dart';
import 'box_padding_surface_component_units_probe.dart';
import 'box_padding_text_field_units_probe.dart';
import 'box_padding_validation_viewport_units_probe.dart';
import 'box_padding_visual_value_units_probe.dart';
import 'breakpoint_showcase_ssr_source.dart';
import 'card_accordion_frame_binding.dart';
import 'client_box_source_protocol.dart';
import 'computed_style_probe.dart';
import 'docs_card_registry_binding.dart';
import 'docs_size_binding.dart';
import 'public_wrapper_ssr_source.dart';
import 'scope_allocation_binding.dart';
import 'showcase_allocation_ssr_source.dart';
import 'stage_callback_binding.dart';
import 'stepper_horizontal_binding.dart';
import 'text_showcase_ssr_source.dart';

/// Current CSS padding of a declared box, independent of painted chrome.
/// This is separate from the historical computed-style payload.
String get boxPaddingObservationScript =>
    '''
(request) => {
  const incomplete = error => ({status:'incomplete', error});
  if (!request.requested) return JSON.stringify({status:'not-requested'});
  const source = request.source;
  if (!source) return JSON.stringify(incomplete('MISSING_PAIRED_BOX_SOURCE'));
  if (source.schemaVersion !== 1) return JSON.stringify(incomplete('UNSUPPORTED_BOX_SOURCE_VERSION'));
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return JSON.stringify(incomplete('UNSUPPORTED_BOX_QUANTITY'));
  const relations = ${jsonEncode([
      BoxObservationSourceSpec.outlined.toJson(),
      BoxObservationSourceSpec.docsStage.toJson(),
      BoxObservationSourceSpec.declaredLayout.toJson(),
      BoxObservationSourceSpec.wholeDocCard.toJson(),
      BoxObservationSourceSpec.docsSizePreview.toJson(),
      BoxObservationSourceSpec.docsPlayground.toJson(),
      BoxObservationSourceSpec.textShowcaseOuterPadding.toJson(),
      BoxObservationSourceSpec.bottomActionBarContentInset.toJson(),
      ...BoxObservationSourceSpec.cardAccordionSurfaceFrames.map((s) => s.toJson()),
      BoxObservationSourceSpec.showcaseAllocationHost.toJson(),
      BoxObservationSourceSpec.scopeAllocationHost.toJson(),
      BoxObservationSourceSpec.stageCallbackContentInset.toJson(),
      BoxObservationSourceSpec.stepperHorizontalHost.toJson(),
      BoxObservationSourceSpec.breakpointShowcaseContentInset.toJson(),
      ...BoxObservationSourceSpec.componentFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.extendedComponentFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.displayComponentFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.controlShellFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.solidLayoutFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.inlineHostFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.proxyHostFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.documentationBubbleFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.layoutHostFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.contentParameterFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.loadingHostFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.displayParameterFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.explicitContentInsetFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.collectionLayoutHostFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.layoutStructureFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.formCollectionFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.sectionLayoutFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.structuredRootFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.publicWrapperFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.validationViewportFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.navigationTriggerParameterFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.dataOverlayLayoutFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.visualValueFrames.map((source) => source.toJson()),
      ...BoxObservationSourceSpec.framedCollectionFrames.map((source) => source.toJson()),
    ])};
  if (!relations.some(known => known.logicalUnitId === source.logicalUnitId && known.nativeAdapterId === source.nativeAdapterId && known.webAdapterId === source.webAdapterId)) return JSON.stringify(incomplete('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'));
  if (typeof request.layoutSelector !== 'string' || !request.layoutSelector) return JSON.stringify(incomplete('MISSING_LAYOUT_SOURCE_SELECTOR'));
  let matches, layoutMatches;
  try {
    layoutMatches = Array.from(document.querySelectorAll(request.layoutSelector));
    matches = Array.from(document.querySelectorAll(request.selector));
  }
  catch(error) {return JSON.stringify(incomplete('INVALID_SOURCE_SELECTOR'));}
  if (layoutMatches.length !== 1) return JSON.stringify(incomplete(layoutMatches.length ? 'DUPLICATE_LAYOUT_OWNER' : 'MISSING_LAYOUT_OWNER'));
  if (matches.length !== 1) return JSON.stringify(incomplete(matches.length ? 'DUPLICATE_LAYOUT_OWNER' : 'MISSING_LAYOUT_OWNER'));
  const layoutRoot = layoutMatches[0];
  if (matches[0] !== layoutRoot) return JSON.stringify(incomplete('UNDECLARED_FIELD_OWNER'));
  let owner;
  let sourceBindingAuthority = null;
  let currentAnatomyEvidence = null;
  let registryIsLayoutRoot = null;
  let currentClientWitness = null;
  let currentClientEvidence = null;
  let validateCurrentBoxBinding = null;
  let currentBoxBindingFailure = 'TEXT_SHOWCASE_BINDING_CHANGED_DURING_CSS_READ';
  const currentSsrRaw = (kind, registryRoot = layoutRoot) => {
    const receipt = request.currentSsrSource;
    if (!receipt || receipt.error || receipt.kind !== kind) return {error:'MISSING_ACTUAL_SSR_BOX_SOURCE'};
    const capture = registryRoot && registryRoot.parentElement;
    if (!capture || receipt.entryKey !== capture.getAttribute('data-parity-key') || typeof location === 'undefined' || location.href !== receipt.harnessURL) return {error:'SSR_BOX_INPUT_CHANGED'};
    const tuple = receipt.source;
    if (!tuple || Object.keys(tuple).length !== Object.keys(source).length || Object.keys(source).some(key => tuple[key] !== source[key])) return {error:'SSR_BOX_SOURCE_CHANGED'};
    return {raw:receipt.currentRaw};
  };
  switch(source.webAdapterId) {
    case 'stepper-normal-horizontal-generated-host-v1': {
      const binding = ($stepperHorizontalRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('STEPPER_ORIGINAL_GENERATED_ROOT_CHANGED'));
      owner = layoutRoot; sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      currentBoxBindingFailure = 'STEPPER_HORIZONTAL_BINDING_CHANGED_DURING_CSS_READ';
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'stage-current-callback-content-inset-v1': {
      const binding = ($stageCallbackRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.frameSource !== layoutRoot ||
          binding.paddingSource === layoutRoot || binding.paddingSource?.parentElement !== layoutRoot ||
          layoutRoot.children.length !== 1 || layoutRoot.children[0] !== binding.paddingSource ||
          binding.registryIsLayoutRoot !== true || typeof binding.validateCurrentBinding !== 'function' ||
          !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('STAGE_FRAME_PADDING_RELATION_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      currentClientWitness = binding.currentClientSource;
      currentClientEvidence = binding.clientEvidence;
      currentBoxBindingFailure = 'STAGE_CALLBACK_BINDING_CHANGED_DURING_CSS_READ';
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'tree-generated-outer-layout-host-v1':
    case 'media-query-generated-visibility-layout-host-v1':
    case 'swipe-actions-generated-outer-layout-host-v1': {
      const binding = ($publicWrapperRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('PUBLIC_WRAPPER_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      currentBoxBindingFailure = 'PUBLIC_WRAPPER_BINDING_CHANGED_DURING_CSS_READ';
      break;
    }

    case 'card-current-outlined-frame-content-v1':
    case 'accordion-current-outlined-frame-content-v1': {
      const binding = ($cardAccordionFrameRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('SURFACE_FRAME_FIELD_UNIT_CHANGED'));
      currentBoxBindingFailure = 'SURFACE_FRAME_BINDING_CHANGED_DURING_CSS_READ';
      owner = layoutRoot; sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true; validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'bottom-action-bar-owned-content-inset-v1': {
      const binding = ($bottomActionBarRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('BOTTOM_ACTION_BAR_FIELD_UNIT_CHANGED'));
      currentBoxBindingFailure = 'BOTTOM_ACTION_BAR_BINDING_CHANGED_DURING_CSS_READ';
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'classic-scope-showcase-allocation-host-v1': {
      const binding = ($scopeAllocationRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('SCOPE_ALLOCATION_FIELD_UNIT_CHANGED'));
      currentBoxBindingFailure = 'SCOPE_ALLOCATION_BINDING_CHANGED_DURING_CSS_READ';
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'classic-compound-showcase-allocation-host-v1': {
      const binding = ($showcaseAllocationRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('SHOWCASE_ALLOCATION_FIELD_UNIT_CHANGED'));
      currentBoxBindingFailure = 'SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_CSS_READ';
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'classic-breakpoint-showcase-content-inset-v1': {
      const binding = ($breakpointShowcaseRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('BREAKPOINT_SHOWCASE_FIELD_UNIT_CHANGED'));
      currentBoxBindingFailure = 'BREAKPOINT_SHOWCASE_BINDING_CHANGED_DURING_CSS_READ';
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'classic-text-showcase-outer-padding-v1': {
      const binding = ($textShowcaseRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied || binding.registryResultElement !== layoutRoot ||
          binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot ||
          binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('TEXT_SHOWCASE_FIELD_UNIT_CHANGED'));
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      break;
    }
    case 'matched-outlined-root-v1':
      if (!${jsonEncode([kWebSurfaceMarker, kWebLocalSurfaceMarker])}.some(name => layoutRoot.classList.contains(name))) return JSON.stringify(incomplete('OUTLINED_ROOT_SOURCE_CHANGED'));
      owner = layoutRoot;
      break;
    case 'docs-size-preview-frame-v1': {
      const binding = ($docsSizeRequestBindingScript)(request);
      if(binding.error)return JSON.stringify(incomplete(binding.error));
      if(!binding.applied||binding.registryResultElement!==layoutRoot||
        binding.fieldUnitElement!==layoutRoot.children[0]||
        binding.paddingSource!==binding.fieldUnitElement||binding.frameSource!==binding.fieldUnitElement||
        !binding.validateCurrentBinding())return JSON.stringify(incomplete('DOCS_SIZE_CURRENT_FRAME_REQUIRED'));
      owner=binding.paddingSource;sourceBindingAuthority=binding.authority;registryIsLayoutRoot=true;
      validateCurrentBoxBinding=binding.validateCurrentBinding;
      currentBoxBindingFailure='DOCS_SIZE_BINDING_CHANGED_DURING_BOX_READ';
      break;
    }
    case 'matched-docs-stage-v1':
    case 'whole-doc-card-frame-v1': {
      const binding = ($docsCardRegistryRequestBindingScript)(request);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (!binding.applied && request.documentationSceneTag === 'Anatomy')
        return JSON.stringify(incomplete('DOCS_ANATOMY_CURRENT_RUNTIME_WITNESS_UNPROVED'));
      const card = source.webAdapterId === 'whole-doc-card-frame-v1';
      if (!binding.applied || binding.fieldUnitElement !== layoutRoot ||
          binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot ||
          binding.registryResultElement !== (card ? layoutRoot.parentElement : layoutRoot) ||
          binding.registryIsLayoutRoot !== !card ||
          typeof binding.validateCurrentBinding !== 'function' || !binding.validateCurrentBinding())
        return JSON.stringify(incomplete('DOCS_FRAME_ACTUAL_NORMAL_SOURCE_REQUIRED'));
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = binding.registryIsLayoutRoot;
      validateCurrentBoxBinding = binding.validateCurrentBinding;
      currentBoxBindingFailure = 'DOCS_FRAME_BINDING_CHANGED_DURING_BOX_READ';
      if (request.documentationSceneTag === 'Anatomy') {
        if (!binding.currentAnatomyEvidence)
          return JSON.stringify(incomplete('DOCS_ANATOMY_CURRENT_ROSTER_REQUIRED'));
        currentAnatomyEvidence = binding.currentAnatomyEvidence;
      }
      break;
    }
    case 'declared-layout-root-v1':
      owner = layoutRoot;
      break;
    case 'mockup-device-generated-body-frame-content-inset-v1':
    case 'join-generated-strip-layout-host-v1':
    case 'table-generated-grid-content-inset-v1': {
      if (request.requiredCurrentSsrKind !== 'canonical-ssr-framed-collection-v1')
        return JSON.stringify(incomplete('MISSING_FRAMED_COLLECTION_REQUIREMENT'));
      const device = source.webAdapterId === 'mockup-device-generated-body-frame-content-inset-v1';
      const registry = device ? layoutRoot.parentElement : layoutRoot;
      const current = currentSsrRaw('canonical-ssr-framed-collection-v1',registry);
      if (current.error) return JSON.stringify(incomplete(current.error));
      const receipt = request.currentSsrSource;
      const header = ['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'];
      if (Array.isArray(receipt) || Object.keys(receipt).length !== header.length ||
          header.some(key => !Object.hasOwn(receipt,key)) || receipt.rawOrderFromPublicProducerLists !== true ||
          !Number.isInteger(receipt.completeRawSlotCount) || receipt.completeRawSlotCount < 0 ||
          receipt.completeRawSlotCount !== current.raw?.rawSlotCount)
        return JSON.stringify(incomplete('FRAMED_COLLECTION_CURRENT_HEADER_CHANGED'));
      // Existing stage-mode root selector already chooses the Device body.
      // Its exact parent is the source-declared registry width wrapper.
      const binding = ($framedCollectionBoxSourceResolverScript)(layoutRoot,source,current.raw);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (typeof binding.authority !== 'string' || !binding.authority ||
          binding.registryResultElement !== registry || binding.fieldUnitElement !== layoutRoot ||
          binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot ||
          binding.registryIsLayoutRoot !== !device ||
          !(registry === layoutRoot || registry.contains(layoutRoot)))
        return JSON.stringify(incomplete('FRAMED_COLLECTION_FIELD_UNIT_CHANGED'));
      owner = layoutRoot;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = !device;
      break;
    }
    case 'icon-generated-visual-frame-content-inset-v1':
    case 'number-ticker-generated-text-layout-host-v1':
    case 'skeleton-text-generated-lines-layout-host-v1':
    case 'countdown-generated-value-layout-host-v1': {
      if (source.webAdapterId === 'number-ticker-generated-text-layout-host-v1' &&
          Object.hasOwn(request,'currentClientBoxSource')) {
        const current = ($clientBoxSourceRequestScript)(layoutRoot,source,request.currentClientBoxSource);
        if (current.error) return JSON.stringify(incomplete(current.error));
        const binding = current.binding;
        if (binding.registryResultElement !== layoutRoot || binding.fieldUnitElement !== layoutRoot ||
            binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot ||
            binding.registryIsLayoutRoot !== true) return JSON.stringify(incomplete('CLIENT_BOX_FIELD_UNIT_CHANGED'));
        currentClientWitness = current.receipt;
        currentClientEvidence = current.clientEvidence;
        owner = binding.paddingSource;
        sourceBindingAuthority = binding.authority;
        registryIsLayoutRoot = true;
        break;
      }
      const current = currentSsrRaw('canonical-ssr-visual-value-v1');
      if (current.error) return JSON.stringify(incomplete(current.error));
      const receipt = request.currentSsrSource;
      const header = ['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'];
      if (Array.isArray(receipt) || Object.keys(receipt).length !== header.length || header.some(key => !Object.hasOwn(receipt,key)) || receipt.rawOrderFromPublicProducerLists !== true || !Number.isInteger(receipt.completeRawSlotCount) || receipt.completeRawSlotCount < 0) return JSON.stringify(incomplete('VISUAL_VALUE_CURRENT_HEADER_CHANGED'));
      const binding = ($visualValueBoxSourceResolverScript)(layoutRoot,source,current.raw);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (receipt.completeRawSlotCount !== current.raw.rawSlotCount) return JSON.stringify(incomplete('VISUAL_VALUE_CURRENT_HEADER_CHANGED'));
      if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot || binding.registryIsLayoutRoot !== true) return JSON.stringify(incomplete('VISUAL_VALUE_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      break;
    }
    case 'theme-controller-generated-option-grid-layout-host-v1':
    case 'tracker-generated-segment-row-layout-host-v1':
    case 'bottom-sheet-generated-outer-layout-host-v1':
    case 'swiper-generated-trigger-layout-host-v1':
    case 'diff-generated-viewer-layout-host-v1': {
      const current = currentSsrRaw('canonical-ssr-data-overlay-v1');
      if (current.error) return JSON.stringify(incomplete(current.error));
      const binding = ($dataOverlayLayoutBoxSourceResolverScript)(layoutRoot,source,current.raw);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      const within = (outer,inner) => outer === inner || outer.contains(inner);
      if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || !binding.fieldUnitElement || !binding.paddingSource || binding.paddingSource !== binding.frameSource || !within(layoutRoot,binding.fieldUnitElement) || !within(binding.fieldUnitElement,binding.paddingSource)) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      break;
    }
    case 'command-search-generated-trigger-content-inset-v1':
    case 'navigation-bar-generated-items-content-inset-v1':
    case 'dock-generated-bar-content-inset-v1': {
      const current = currentSsrRaw('canonical-ssr-navigation-trigger-v1');
      if (current.error) return JSON.stringify(incomplete(current.error));
      const binding = ($navigationTriggerBoxSourceResolverScript)(layoutRoot,source,current.raw);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      const within = (outer,inner) => outer === inner || outer.contains(inner);
      if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || !binding.fieldUnitElement || !binding.paddingSource || binding.paddingSource !== binding.frameSource || !within(layoutRoot,binding.fieldUnitElement) || !within(binding.fieldUnitElement,binding.paddingSource)) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      break;
    }
    case 'docs-playground-stage-frame-v1': {
      const receipt = request.runtimeOperationReceipt;
      if (!receipt || receipt.error || receipt.kind !== 'canonical-runtime-navigation-v1') return JSON.stringify(incomplete('MISSING_ACTUAL_RUNTIME_OPERATION'));
      let actualPayload;
      try {
        if (location.href !== receipt.navigationURL) return JSON.stringify(incomplete('RUNTIME_NAVIGATION_INPUT_CHANGED'));
        actualPayload = JSON.parse(decodeURIComponent(location.hash.slice(1)));
      } catch(error) {return JSON.stringify(incomplete('UNOBSERVED_RUNTIME_INPUT'));}
      const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object' ? Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])])) : value;
      if (JSON.stringify(canonical(actualPayload)) !== JSON.stringify(canonical(receipt.preparedPayload))) return JSON.stringify(incomplete('RUNTIME_NAVIGATION_INPUT_CHANGED'));
      const one = nodes => nodes.length === 1 ? nodes[0] : null;
      const entryRoot = one(Array.from(document.querySelectorAll('[data-parity-key]')).filter(node=>node.getAttribute('data-parity-key') === actualPayload.key && node.getAttribute('data-parity-client-key') === actualPayload.key));
      const sceneHost = entryRoot && one(Array.from(entryRoot.querySelectorAll('[data-docs-scene]')).filter(node=>node.getAttribute('data-docs-scene') === actualPayload.variant));
      const content = sceneHost && one(Array.from(sceneHost.children).filter(node=>node.classList.contains('content')));
      const registryRoot = content && one(Array.from(content.children).filter(node=>node.classList.contains('docs-playground')));
      const operation = {entryKey:actualPayload.key,component:actualPayload.component,variant:actualPayload.variant,authority:receipt.authority,payloadAuthority:receipt.payloadAuthority,payload:actualPayload,entryRoot,sceneHost,registryRoot};
      const binding = ($documentationPlaygroundBoxSourceResolverScript)(layoutRoot,source,operation);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      if (binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot) return JSON.stringify(incomplete('PLAYGROUND_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = binding.registryResultElement === layoutRoot;
      break;
    }
    case 'code-diff-generated-frame-v1':
    case 'command-panel-generated-frame-v1':
    case 'fieldset-generated-frame-v1':
    case 'item-picker-generated-frame-v1':
    case 'mockup-browser-generated-frame-v1':
    case 'object-input-generated-frame-v1': {
      let browserRaw = null;
      if (source.webAdapterId === 'mockup-browser-generated-frame-v1' &&
          (request.requiredCurrentSsrKind != null || request.currentSsrSource != null)) {
        if (request.requiredCurrentSsrKind !== 'canonical-ssr-framed-collection-v1')
          return JSON.stringify(incomplete('MISSING_FRAMED_COLLECTION_REQUIREMENT'));
        const current = currentSsrRaw('canonical-ssr-framed-collection-v1');
        if (current.error) return JSON.stringify(incomplete(current.error));
        const receipt = request.currentSsrSource;
        const header = ['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'];
        if (Array.isArray(receipt) || Object.keys(receipt).length !== header.length ||
            header.some(key => !Object.hasOwn(receipt,key)) || receipt.rawOrderFromPublicProducerLists !== true ||
            receipt.completeRawSlotCount !== 1 || current.raw?.rawSlotCount !== 1)
          return JSON.stringify(incomplete('FRAMED_COLLECTION_CURRENT_HEADER_CHANGED'));
        browserRaw = current.raw;
      }
      const binding = ($componentBoxSourceResolverScript)(layoutRoot, source, browserRaw);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      const within = (outer, inner) => outer === inner || outer.contains(inner);
      if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || !binding.fieldUnitElement || !binding.paddingSource || binding.paddingSource !== binding.frameSource || !within(layoutRoot,binding.fieldUnitElement) || !within(binding.fieldUnitElement,binding.paddingSource)) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      break;
    }
    case 'banner-generated-frame-v1':
    case 'description-card-generated-frame-v1':
    case 'formatted-input-generated-frame-v1':
    case 'frame-generated-content-inset-v1': {
      const binding = ($extendedComponentBoxSourceResolverScript)(layoutRoot,source);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      const within = (outer,inner) => outer === inner || outer.contains(inner);
      if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || !binding.fieldUnitElement || !binding.paddingSource || binding.paddingSource !== binding.frameSource || !within(layoutRoot,binding.fieldUnitElement) || !within(binding.fieldUnitElement,binding.paddingSource)) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = true;
      break;
    }
    case 'avatar-generated-frame-v1':
    case 'code-snippet-generated-frame-v1':
    case 'stat-generated-frame-v1':
    case 'validation-badge-generated-frame-v1':
    case 'number-input-generated-field-frame-v1':
    case 'chip-generated-frame-v1':
    case 'app-bar-solid-content-inset-v1':
    case 'empty-state-generated-content-inset-v1':
    case 'label-generated-inline-host-v1':
    case 'link-generated-inline-host-v1':
    case 'mask-generated-clip-host-v1':
    case 'hover-generated-effect-host-v1':
    case 'indicator-generated-overlay-host-v1':
    case 'docs-chat-single-bubble-frame-v1':
    case 'steps-generated-sequence-host-v1':
    case 'stepper-vertical-sequence-host-v1':
    case 'aspect-ratio-generated-layout-host-v1':
    case 'clickable-generated-interaction-host-v1':
    case 'focus-outline-generated-pass-through-host-v1':
    case 'switch-field-generated-control-row-v1':
    case 'kbd-single-keycap-content-inset-v1':
    case 'app-bar-medium-toolbar-content-inset-v1':
    case 'documentation-refresh-viewport-content-inset-v1':
    case 'loading-generated-size-host-v1':
    case 'status-generated-dot-content-inset-v1':
    case 'tag-generated-label-content-inset-v1':
    case 'skeleton-circular-block-content-inset-v1':
    case 'menu-item-generated-row-content-inset-v1':
    case 'carousel-banner-generated-strip-content-inset-v1':
    case 'panel-header-generated-content-inset-v1':
    case 'calendar-generated-layout-host-v1':
    case 'definition-list-generated-layout-host-v1':
    case 'responsive-row-column-generated-flex-layout-host-v1':
    case 'responsive-container-generated-content-inset-v1':
    case 'responsive-grid-generated-grid-layout-host-v1':
    case 'stack-layout-generated-overlap-layout-host-v1':
    case 'indexed-switcher-generated-indexed-layout-host-v1':
    case 'swap-generated-overlap-layout-host-v1':
    case 'divider-generated-labelled-sequence-layout-host-v1':
    case 'toggle-group-generated-track-content-inset-v1':
    case 'form-field-generated-layout-host-v1':
    case 'form-label-generated-label-row-layout-host-v1':
    case 'listing-generated-rows-layout-host-v1':
    case 'option-list-generated-layout-host-v1':
    case 'disclosure-generated-header-content-inset-v1':
    case 'disclosure-group-generated-layout-host-v1':
    case 'collapsible-generated-section-layout-host-v1':
    case 'resizable-generated-pane-layout-host-v1':
    case 'breadcrumb-generated-trail-layout-host-v1':
    case 'basic-generated-content-inset-v1':
    case 'disclosure-badge-solid-content-inset-v1':
    case 'multiple-choice-generated-options-layout-host-v1':
    case 'page-header-generated-layout-host-v1':
    case 'sidebar-generated-outer-layout-host-v1':
    case 'tab-pane-generated-bar-content-inset-v1':
    case 'timeline-generated-sequence-layout-host-v1':
    case 'category-breakdown-generated-layout-host-v1':
    case 'trend-chart-generated-outer-layout-host-v1':
    case 'window-panel-generated-frame-content-inset-v1':
    case 'text-field-generated-content-inset-v1':
    case 'validated-generated-layout-host-v1':
    case 'validator-hint-generated-message-layout-host-v1':
    case 'scroll-area-generated-viewport-layout-host-v1':
    case 'fade-scroll-generated-viewport-layout-host-v1':
    case 'overflow-marquee-generated-viewport-layout-host-v1':
    case 'kbd-generated-key-sequence-layout-host-v1': {
      const display = ${jsonEncode(BoxObservationSourceSpec.displayComponentFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const control = ${jsonEncode(BoxObservationSourceSpec.controlShellFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const solid = ${jsonEncode(BoxObservationSourceSpec.solidLayoutFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const inline = ${jsonEncode(BoxObservationSourceSpec.inlineHostFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const proxy = ${jsonEncode(BoxObservationSourceSpec.proxyHostFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const layout = ${jsonEncode(BoxObservationSourceSpec.layoutHostFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const parameter = ${jsonEncode(BoxObservationSourceSpec.contentParameterFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const loading = ${jsonEncode(BoxObservationSourceSpec.loadingHostFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const displayParameter = ${jsonEncode(BoxObservationSourceSpec.displayParameterFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const explicitInset = ${jsonEncode(BoxObservationSourceSpec.explicitContentInsetFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const collection = ${jsonEncode(BoxObservationSourceSpec.collectionLayoutHostFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const responsive = ${jsonEncode([
      BoxObservationSourceSpec.responsiveFlexLayoutHost,
      BoxObservationSourceSpec.responsiveContainerContentInset,
      BoxObservationSourceSpec.responsiveGridLayoutHost,
    ].map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const sequence = ${jsonEncode([
      BoxObservationSourceSpec.stackLayoutOverlapHost,
      BoxObservationSourceSpec.indexedSwitcherLayoutHost,
      BoxObservationSourceSpec.swapOverlapLayoutHost,
      BoxObservationSourceSpec.dividerLabelledSequenceHost,
    ].map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const formCollection = ${jsonEncode(BoxObservationSourceSpec.formCollectionFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const sectionLayout = ${jsonEncode(BoxObservationSourceSpec.sectionLayoutFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const structured = ${jsonEncode(BoxObservationSourceSpec.structuredRootFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const validation = ${jsonEncode(BoxObservationSourceSpec.validationViewportFrames.map((source) => source.webAdapterId).toList())}.includes(source.webAdapterId);
      const binding = display
        ? ($displayBoxSourceResolverScript)(layoutRoot,source)
        : control ? ($controlShellBoxSourceResolverScript)(layoutRoot,source)
        : solid ? ($solidLayoutBoxSourceResolverScript)(layoutRoot,source)
        : inline ? ($inlineHostBoxSourceResolverScript)(layoutRoot,source)
        : proxy ? ($proxyHostBoxSourceResolverScript)(layoutRoot,source)
        : layout ? ($layoutHostBoxSourceResolverScript)(layoutRoot,source)
        : parameter ? ($contentParameterBoxSourceResolverScript)(layoutRoot,source)
        : loading ? ($loadingHostBoxSourceResolverScript)(layoutRoot,source)
        : displayParameter ? ($displayParameterBoxSourceResolverScript)(layoutRoot,source)
        : explicitInset ? ($explicitContentInsetBoxSourceResolverScript)(layoutRoot,source)
        : collection ? ($collectionLayoutHostBoxSourceResolverScript)(layoutRoot,source)
        : responsive ? ($responsiveLayoutBoxSourceResolverScript)(layoutRoot,source)
        : sequence ? ($sequenceLayoutBoxSourceResolverScript)(layoutRoot,source)
        : formCollection ? ($formCollectionBoxSourceResolverScript)(layoutRoot,source)
        : sectionLayout ? ($sectionLayoutBoxSourceResolverScript)(layoutRoot,source)
        : structured ? ($structuredRootBoxSourceResolverScript)(layoutRoot,source)
        : validation ? ($validationViewportBoxSourceResolverScript)(layoutRoot,source)
        : ($chatBubbleBoxSourceResolverScript)(layoutRoot,source);
      if (binding.error) return JSON.stringify(incomplete(binding.error));
      const within = (outer,inner) => outer === inner || outer.contains(inner);
      const responsiveContainer = source.webAdapterId === ${jsonEncode(BoxObservationSourceSpec.responsiveContainerContentInset.webAdapterId)};
      if (responsiveContainer) {
        // The existing selector targets ResponsiveContainer below the docs
        // width-filling stage. The stage never owns the container's inset.
        const registry = binding.registryResultElement;
        const capture = registry?.parentElement;
        if (typeof binding.authority !== 'string' || !binding.authority || !capture || capture.children.length !== 1 || capture.children[0] !== registry || registry !== layoutRoot.parentElement || registry.children.length !== 1 || registry.children[0] !== layoutRoot || binding.fieldUnitElement !== layoutRoot || binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      } else if (typeof binding.authority !== 'string' || !binding.authority || binding.registryResultElement !== layoutRoot || !binding.fieldUnitElement || !binding.paddingSource || binding.paddingSource !== binding.frameSource || !within(layoutRoot,binding.fieldUnitElement) || !within(binding.fieldUnitElement,binding.paddingSource)) return JSON.stringify(incomplete('COMPONENT_FIELD_UNIT_CHANGED'));
      owner = binding.paddingSource;
      sourceBindingAuthority = binding.authority;
      registryIsLayoutRoot = !responsiveContainer;
      if (source.webAdapterId === 'text-field-generated-content-inset-v1') {
        const parts = binding.complementaryPaddingSources;
        if (!parts || parts.kind !== 'text-field-wrapper-input-v1' || parts.wrapper !== owner || !parts.input) return JSON.stringify(incomplete('MISSING_TEXT_FIELD_PADDING_PARTS'));
        const pathFromRegistry = node => {
          const path = [];
          let current = node;
          while (current !== layoutRoot) {
            const parent = current?.parentElement;
            if (!parent || !within(layoutRoot,parent)) return null;
            const index = Array.from(parent.children).indexOf(current);
            if (index < 0) return null;
            path.unshift(index);
            current = parent;
          }
          return path;
        };
        const wrapperPath = pathFromRegistry(parts.wrapper);
        const inputPath = pathFromRegistry(parts.input);
        if (!wrapperPath || !inputPath) return JSON.stringify(incomplete('TEXT_FIELD_PADDING_PART_OWNER_CHANGED'));
        const observed = ($textFieldComplementaryPaddingScript)(binding);
        if (observed.error) return JSON.stringify(incomplete(observed.error));
        return JSON.stringify({status:'source-complete', sourceUnitValidated:true,
          source, ...observed,
          paddingParameterSources:[
            {slot:'framed-wrapper',path:wrapperPath,ownerTag:parts.wrapper.tagName,ownerClasses:Array.from(parts.wrapper.classList)},
            {slot:'direct-input',path:inputPath,ownerTag:parts.input.tagName,ownerClasses:Array.from(parts.input.classList)}
          ],
          ownerIsLayoutRoot:owner === layoutRoot,ownerTag:owner.tagName,
          ownerClasses:Array.from(owner.classList),paintRequired:false,
          sourceBindingAuthority,registryIsLayoutRoot,
          canonicalComparisonEligible:false});
      }
      break;
    }
    default: return JSON.stringify(incomplete('UNSUPPORTED_WEB_BOX_ADAPTER'));
  }
  const style = getComputedStyle(owner);
  if (style.display === 'contents' || style.display === 'none' || !owner.isConnected) return JSON.stringify(incomplete('NO_DECLARED_LAYOUT_BOX'));
  const raw = [style.paddingTop, style.paddingRight, style.paddingBottom, style.paddingLeft];
  if (raw.some(text => !/^[+-]?(?:[0-9]+(?:[.][0-9]*)?|[.][0-9]+)(?:[eE][+-]?[0-9]+)?px\$/.test(text))) return JSON.stringify(incomplete('UNRESOLVED_CSS_PADDING_UNIT'));
  const value = raw.map(text => Number.parseFloat(text));
  if (value.some(number => !Number.isFinite(number))) return JSON.stringify(incomplete('UNRESOLVED_CSS_PADDING'));
  const ownerTag = owner.tagName, ownerClasses = Array.from(owner.classList);
  if (validateCurrentBoxBinding && !validateCurrentBoxBinding())
    return JSON.stringify(incomplete(currentBoxBindingFailure));
  return JSON.stringify({status:'source-complete', sourceUnitValidated:true, source, value, rawCss:raw,
    ownerIsLayoutRoot:owner === layoutRoot, ownerTag,
    ownerClasses, paintRequired:false,
    sourceBindingAuthority, registryIsLayoutRoot,
    ...(currentClientWitness ? {currentClientSource:currentClientWitness,
      clientEvidence:currentClientEvidence,
      clientDomIdentityValidated:true,clientDomWholeTreeValidated:source.webAdapterId!=='stage-current-callback-content-inset-v1',
      ...(source.webAdapterId==='stage-current-callback-content-inset-v1' ? {clientOwnedPrefixValidated:true,foreignInteriorUsedForAuthority:false} : {}),
      clientObservationPhase:currentClientWitness.renderPhase} : {}),
    ...(currentAnatomyEvidence ? {currentAnatomyEvidence} : {}),
    canonicalComparisonEligible:false});
}
''';

/// Both observations run in one JS task. Opted-in Device paint is validated
/// against its separate current source before any credited paint CSS is read.
String get computedStyleAndBoxObservationScript =>
    sourceValidatedComputedStyleAndBoxScript(boxPaddingObservationScript);
