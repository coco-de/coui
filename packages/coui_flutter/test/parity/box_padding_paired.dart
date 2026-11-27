import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/outlined_container/outlined_container_default_example.dart';
import 'package:flutter/widgets.dart'
    show AnimatedContainer, Container, Element, KeyedSubtree, Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_bottom_action_bar_source.dart';
import 'box_padding_breakpoint_showcase_units.dart';
import 'box_padding_card_accordion_frame_source.dart';
import 'box_padding_chat_bubble_units.dart';
import 'box_padding_collection_layout_host_units.dart';
import 'box_padding_component_units.dart';
import 'box_padding_content_parameter_units.dart';
import 'box_padding_control_shell_units.dart';
import 'box_padding_data_overlay_layout_units.dart';
import 'box_padding_display_parameter_units.dart';
import 'box_padding_explicit_content_inset_units.dart';
import 'box_padding_extended_component_units.dart';
import 'box_padding_form_collection_units.dart';
import 'box_padding_framed_collection_units.dart';
import 'box_padding_inline_host_units.dart';
import 'box_padding_layout_host_units.dart';
import 'box_padding_loading_host_units.dart';
import 'box_padding_navigation_trigger_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_playground_units.dart';
import 'box_padding_preview_receipts.dart';
import 'box_padding_proxy_host_units.dart';
import 'box_padding_public_wrapper_units.dart';
import 'box_padding_responsive_layout_units.dart';
import 'box_padding_scene_units.dart';
import 'box_padding_scope_allocation_units.dart';
import 'box_padding_section_layout_units.dart';
import 'box_padding_sequence_layout_units.dart';
import 'box_padding_showcase_allocation_units.dart';
import 'box_padding_solid_layout_units.dart';
import 'box_padding_source_bindings.dart';
import 'box_padding_stage_callback_source.dart';
import 'box_padding_stepper_horizontal_source.dart';
import 'box_padding_structured_root_units.dart';
import 'box_padding_surface_component_units.dart';
import 'box_padding_text_showcase_units.dart';
import 'box_padding_validation_viewport_units.dart';
import 'box_padding_visual_value_units.dart';
import 'parity_matrix_entry.dart';

/// A shared declaration binds a layout unit and its current padding source.
/// The historical role/paint eligibility is recorded, never rewritten.
/// Source completeness does not establish that the historical root field
/// observed this same unit, nor authorize replacing that field's quantity.
Map<String, Object?> observePairedNativePadding({
  required String key,
  required Iterable<ParityProbeSpec> probes,
  required Element captureRoot,
  required Widget registryResult,
  required bool legacyRootOmitted,
  ValidatedPreviewReceipt? previewReceipt,
  BoxObservationError? previewReceiptError,
}) => {
  'key': key,
  'mode': 'additive-only',
  'legacyRootOmitted': legacyRootOmitted,
  'canonicalComparisonEligible': false,
  'byRole': {
    for (final probe in probes)
      probe.role: _observe(
        probe,
        captureRoot,
        registryResult,
        legacyRootOmitted,
        previewReceipt,
        previewReceiptError,
      ),
  },
};

Map<String, Object?> _observe(
  ParityProbeSpec probe,
  Element captureRoot,
  Widget registryResult,
  bool legacyRootOmitted,
  ValidatedPreviewReceipt? previewReceipt,
  BoxObservationError? previewReceiptError,
) {
  if (probe.fields.isEmpty) {
    return {'status': 'incomplete', 'error': 'MISSING_REQUESTED_FIELDS'};
  }
  if (!probe.fields.contains('paddingPx')) return {'status': 'not-requested'};
  if (probe.boxObservationSource == null) {
    return {'status': 'incomplete', 'error': 'MISSING_PAIRED_BOX_SOURCE'};
  }
  try {
    final source = BoxObservationSourceSpec.fromJson(
      probe.boxObservationSource!,
    );
    final error = source.validationError;
    if (error != null) throw BoxObservationError(error, 'Invalid source unit.');
    final rootWidget = captureRoot.widget;
    if (!identical(rootWidget, registryResult) &&
        !(rootWidget is KeyedSubtree &&
            identical(rootWidget.child, registryResult))) {
      throw const BoxObservationError(
        'MISMATCHED_CONSTRUCTION_RESULT',
        'The declared construction result is not '
            'the actual keyed capture child.',
      );
    }
    final resultElement = requireOneBoxOwner(
      boxElements(captureRoot).where(
        (element) => identical(element.widget, registryResult),
      ),
      'the actual registry construction result',
    );

    if (source == BoxObservationSourceSpec.stepperHorizontalHost) {
      final declared = probe.boxObservationSource!;
      final expected = source.toJson();
      if (declared.length != expected.length ||
          expected.entries.any((e) => declared[e.key] != e.value)) {
        throw const BoxObservationError(
          'STEPPER_HORIZONTAL_SOURCE_CHANGED',
          'The complete exact Stepper source tuple is required.',
        );
      }
      final binding = bindStepperHorizontalEntry(
        captureRoot: captureRoot,
        registryResult: registryResult,
        source: source,
      );
      final identity = binding.sourceIdentity;
      final observed = binding.readDeclaredAbsence();
      binding.validateCurrentBinding();
      return {
        ...observed.toJson(),
        'sourceIdentity': identity,
        'status': 'source-complete',
        'sourceUnitValidated': true,
        'source': source.toJson(),
        'layoutRootElement': identityHashCode(resultElement),
        'fieldUnitElement': identityHashCode(binding.frameSource),
        'sourceReaderId': binding.readerId,
        'sourceBindingAuthority': binding.authority,
        'legacyRoleEligible': !legacyRootOmitted,
        'paintRequired': false,
        'canonicalComparisonEligible': false,
      };
    }
    if (source == BoxObservationSourceSpec.stageCallbackContentInset) {
      final declared = probe.boxObservationSource!;
      final expected = source.toJson();
      if (declared.length != expected.length ||
          expected.entries.any((e) => declared[e.key] != e.value)) {
        throw const BoxObservationError(
          'STAGE_CALLBACK_CONTENT_SOURCE_CHANGED',
          'The complete exact Stage source tuple is required.',
        );
      }
      final binding = bindStageCallbackEntry(
        captureRoot: captureRoot,
        registryResult: registryResult,
        source: source,
      );
      final identity = binding.sourceIdentity;
      final observed = binding.readActualPadding();
      binding.validateCurrentBinding();
      return {
        ...observed.toJson(),
        'sourceIdentity': identity,
        'status': 'source-complete',
        'sourceUnitValidated': true,
        'source': source.toJson(),
        'layoutRootElement': identityHashCode(resultElement),
        'fieldUnitElement': identityHashCode(binding.stage),
        'sourceReaderId': binding.readerId,
        'sourceBindingAuthority': binding.authority,
        'legacyRoleEligible': !legacyRootOmitted,
        'paintRequired': false,
        'canonicalComparisonEligible': false,
      };
    }
    if (source == BoxObservationSourceSpec.bottomActionBarContentInset) {
      final declared = probe.boxObservationSource!;
      final expected = BoxObservationSourceSpec.bottomActionBarContentInset
          .toJson();
      if (declared.length != expected.length ||
          expected.entries.any((entry) => declared[entry.key] != entry.value)) {
        throw const BoxObservationError(
          'BOTTOM_ACTION_BAR_TUPLE_CHANGED',
          'The complete exact tuple is required.',
        );
      }
      final binding = bindBottomActionBarEntrySource(
        captureRoot: captureRoot,
        registryResult: registryResult,
        source: source,
      );
      final observed = binding.readActualPadding();
      return {
        ...observed.toJson(),
        'status': 'source-complete',
        'sourceUnitValidated': true,
        'source': source.toJson(),
        'layoutRootElement': identityHashCode(resultElement),
        'fieldUnitElement': identityHashCode(binding.producer),
        'sourceReaderId': 'bottom-action-bar-two-current-render-paddings-v1',
        'sourceBindingAuthority':
            'Exact original public Example -> BottomActionBar '
            '-> CoUISemantics/optional public SurfaceBlur.child -> Container '
            '-> '
            'SafeArea current Padding -> MediaQuery -> original explicit '
            'Padding; '
            'two current parameters inside frame, border and foreign content '
            'excluded',
        'legacyRoleEligible': !legacyRootOmitted,
        'paintRequired': false,
        'canonicalComparisonEligible': false,
      };
    }
    if (BoxObservationSourceSpec.cardAccordionSurfaceFrames.contains(source)) {
      final declared = probe.boxObservationSource!;
      final expected = source.toJson();
      if (declared.length != expected.length ||
          expected.entries.any((e) => declared[e.key] != e.value)) {
        throw const BoxObservationError(
          'SURFACE_FRAME_SOURCE_CHANGED',
          'The complete exact frame tuple is required.',
        );
      }
      final binding = bindCardAccordionEntryFrame(
        captureRoot: captureRoot,
        registryResult: registryResult,
        source: source,
      );
      final identity = binding.sourceIdentity;
      final observed = binding.readActualPadding();
      binding.validateCurrentBinding();
      return {
        ...observed.toJson(),
        'sourceIdentity': identity,
        'status': 'source-complete',
        'sourceUnitValidated': true,
        'source': source.toJson(),
        'layoutRootElement': identityHashCode(resultElement),
        'fieldUnitElement': identityHashCode(binding.producer),
        'sourceReaderId': 'card-accordion-current-outlined-frame-v1',
        'sourceBindingAuthority': [
          'original exact public surface -> actual outlined ',
          'frame -> immediate generated opaque content; ',
          'distributed slot and item insets excluded',
        ].join(),
        'legacyRoleEligible': !legacyRootOmitted,
        'paintRequired': false,
        'canonicalComparisonEligible': false,
      };
    }
    final BoxPaddingObservation observation;
    var sourceBindingProvenance = <String, Object?>{};
    switch (source.nativeAdapterId) {
      case 'media-query-generated-visibility-layout-host-v1':
      case 'swipe-actions-generated-outer-layout-host-v1':
        final declared = probe.boxObservationSource!;
        if (declared.length != 5) {
          throw const BoxObservationError(
            'PUBLIC_WRAPPER_SOURCE_CHANGED',
            'Exact five-field tuple required.',
          );
        }
        final binding = bindPublicWrapperBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        )!;
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.fieldUnitElement,
          ),
          'declaredFrameSourceElement': identityHashCode(
            binding.fieldUnitElement,
          ),
          'sourceReaderId': binding.readerId,
        };

      case 'classic-scope-showcase-allocation-host-v1':
        final expected = BoxObservationSourceSpec.scopeAllocationHost.toJson();
        final declared = probe.boxObservationSource!;
        if (declared.length != expected.length ||
            expected.entries.any(
              (entry) => declared[entry.key] != entry.value,
            )) {
          throw const BoxObservationError(
            'SCOPE_ALLOCATION_SOURCE_CHANGED',
            'Require the exact declared public scope tuple.',
          );
        }
        final binding = bindScopeAllocationBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.readerId !=
                'scope-allocation-current-public-forwarding-v1') {
          throw const BoxObservationError(
            'SCOPE_ALLOCATION_SOURCE_CHANGED',
            'Require the current original public scope forwarding prefix.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (!BoxProducerScope.contains(
          binding.fieldUnitElement,
          binding.paddingSource,
        )) {
          throw const BoxObservationError(
            'SCOPE_ALLOCATION_SOURCE_CHANGED',
            'The public scope must contain the actual original layout.',
          );
        }
        observation = binding.readDeclaredAbsence();
        // This distinct typed route keeps the forwarding scope separate from
        // the actual Row/Column allocation; all old same-owner cases stay exact.
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.owner, binding.paddingSource) ||
            !identical(observation.frameOwner, binding.frameSource) ||
            observation.paddingElement != null ||
            observation.quantity != PaddingQuantityKind.declaredNoOwnPadding) {
          throw const BoxObservationError(
            'SCOPE_ALLOCATION_SOURCE_CHANGED',
            'Retain the actual owned layout, structural operation and prefix.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'classic-compound-showcase-allocation-host-v1':
        final declared = probe.boxObservationSource!;
        final expected = BoxObservationSourceSpec.showcaseAllocationHost
            .toJson();
        if (declared.length != expected.length ||
            expected.entries.any(
              (entry) => declared[entry.key] != entry.value,
            )) {
          throw const BoxObservationError(
            'SHOWCASE_ALLOCATION_SOURCE_CHANGED',
            'The complete declared allocation tuple must match exactly.',
          );
        }
        final binding = bindShowcaseAllocationBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.readerId !=
                'showcase-allocation-current-framework-host-v1') {
          throw const BoxObservationError(
            'SHOWCASE_ALLOCATION_SOURCE_CHANGED',
            'The original current showcase allocation is required.',
          );
        }
        observation = binding.readDeclaredAbsence();
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.owner, binding.fieldUnitElement) ||
            !identical(observation.frameOwner, binding.frameSource) ||
            observation.paddingElement != null ||
            observation.quantity != PaddingQuantityKind.declaredNoOwnPadding) {
          throw const BoxObservationError(
            'SHOWCASE_ALLOCATION_SOURCE_CHANGED',
            'Keep the actual allocation owner and structural quantity.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'classic-breakpoint-showcase-content-inset-v1':
        final declared = probe.boxObservationSource!;
        final expected = kBreakpointShowcaseContentInsetSource.toJson();
        if (declared.length != expected.length ||
            expected.entries.any(
              (entry) => declared[entry.key] != entry.value,
            )) {
          throw const BoxObservationError(
            'BREAKPOINT_SHOWCASE_SOURCE_CHANGED',
            'The complete declared Breakpoint showcase tuple must match '
                'exactly.',
          );
        }
        final binding = bindBreakpointShowcaseBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty ||
            binding.readerId !=
                'breakpoint-showcase-actual-container-padding-v1') {
          throw const BoxObservationError(
            'MISMATCHED_BREAKPOINT_SHOWCASE_SOURCE',
            'The current closed showcase must own its declared allocation.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readActualPadding();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.owner, binding.paddingSource) ||
            !identical(
              observation.paddingElement,
              binding.actualPaddingElement,
            ) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_BREAKPOINT_SHOWCASE_OBSERVATION',
            'Keep the actual producer, padding source and frame identities.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'classic-text-showcase-outer-padding-v1':
        final declared = probe.boxObservationSource!;
        final expected = kTextShowcaseOuterPaddingSource.toJson();
        if (declared.length != expected.length ||
            expected.entries.any(
              (entry) => declared[entry.key] != entry.value,
            )) {
          throw const BoxObservationError(
            'TEXT_SHOWCASE_SOURCE_CHANGED',
            'The complete declared Text showcase tuple must match exactly.',
          );
        }
        final binding = bindTextShowcaseBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty ||
            binding.readerId != 'text-showcase-actual-framework-padding-v1') {
          throw const BoxObservationError(
            'MISMATCHED_TEXT_SHOWCASE_SOURCE',
            'The current closed showcase must own its declared allocation.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readActualPadding();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.owner, binding.paddingSource) ||
            !identical(observation.paddingElement, binding.paddingSource) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_TEXT_SHOWCASE_OBSERVATION',
            'Keep the actual producer, padding source and frame identities.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'docs-playground-stage-frame-v1':
        if (previewReceiptError != null) throw previewReceiptError;
        if (previewReceipt == null) {
          throw const BoxObservationError(
            'MISSING_MOUNTED_PREVIEW_RECEIPT',
            'No source-authorized existing builder operation is bound.',
          );
        }
        final playground = bindPlaygroundBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
          validatedReceipt: previewReceipt,
        );
        observation = observePlaygroundDeclaredNoPadding(
          owner: playground.paddingSource,
          scope: playground.scope,
        );
        sourceBindingProvenance = {
          'sourceBindingAuthority': playground.authority,
          'fieldUnitElement': identityHashCode(playground.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            playground.paddingSource,
          ),
          'sourceReaderId': playground.readerId,
          'sceneValueAuthority': previewReceipt.sceneValueAuthority.toJson(),
          'privateSceneObjectIdentityClaim': false,
        };
      case 'typed-outlined-root-content-v1':
        final Element primitive;
        if (registryResult is coui.OutlinedContainer) {
          primitive = resultElement;
        } else if (registryResult is OutlinedContainerDefaultExample) {
          requireConcreteBoxSourceType(
            registryResult,
            OutlinedContainerDefaultExample,
          );
          // This source constructor returns the primitive directly.
          // No unknown wrapper, descendant search or supplied child is crossed.
          primitive = _singleChild(resultElement);
        } else {
          throw const BoxObservationError(
            'UNREGISTERED_CONSTRUCTION_SOURCE',
            'The unit is not an audited single-primitive constructor.',
          );
        }
        final declaration = DeclaredBoxProducer.bind(
          producer: primitive,
          sourceContract: 'renderer-frame-padding-v1',
        );
        observation = observeOutlinedContainerContentPadding(
          primitive: primitive,
          declaringScope: declaration.scope,
        );
      case 'menu-item-generated-row-content-inset-v1':
      case 'carousel-banner-generated-strip-content-inset-v1':
      case 'panel-header-generated-content-inset-v1':
        final binding = bindExplicitContentInsetBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed explicit content inset witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (binding.readerId != 'current-render-padding-v1') {
          throw const BoxObservationError(
            'UNSUPPORTED_EXPLICIT_CONTENT_INSET_READER',
            'No existing observer reads this declared content inset.',
          );
        }
        binding.validateCurrentConstruction();
        observation = observeSourceOwnedRenderPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        );
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'responsive-row-column-generated-flex-layout-host-v1':
      case 'responsive-container-generated-content-inset-v1':
      case 'responsive-grid-generated-grid-layout-host-v1':
        final binding = bindResponsiveLayoutBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed responsive layout witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (source.nativeAdapterId ==
            BoxObservationSourceSpec
                .responsiveContainerContentInset
                .nativeAdapterId) {
          if (binding.readerId != 'current-render-padding-v1') {
            throw const BoxObservationError(
              'UNSUPPORTED_RESPONSIVE_CONTENT_INSET_READER',
              'No existing observer reads this responsive content inset.',
            );
          }
          binding.validateExistingCurrentBinding();
          observation = observeSourceOwnedRenderPadding(
            owner: binding.paddingSource,
            scope: binding.scope,
          );
        } else {
          observation = binding.readDeclaredAbsence();
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'stack-layout-generated-overlap-layout-host-v1':
      case 'indexed-switcher-generated-indexed-layout-host-v1':
      case 'swap-generated-overlap-layout-host-v1':
      case 'divider-generated-labelled-sequence-layout-host-v1':
        final binding = bindSequenceLayoutBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed sequence layout witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'toggle-group-generated-track-content-inset-v1':
      case 'form-field-generated-layout-host-v1':
      case 'form-label-generated-label-row-layout-host-v1':
      case 'listing-generated-rows-layout-host-v1':
      case 'option-list-generated-layout-host-v1':
        final binding = bindFormCollectionBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed form collection witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (source.nativeAdapterId ==
            BoxObservationSourceSpec
                .toggleGroupTrackContentInset
                .nativeAdapterId) {
          if (binding.readerId != 'outlined-content-v1') {
            throw const BoxObservationError(
              'UNSUPPORTED_PADDING_READER',
              'No existing observer reads this declared source inset.',
            );
          }
          binding.validateExistingCurrentBinding();
          observation = observeOutlinedContainerContentPadding(
            primitive: binding.paddingSource,
            declaringScope: binding.scope,
          );
        } else {
          observation = binding.readDeclaredAbsence();
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'disclosure-generated-header-content-inset-v1':
      case 'disclosure-group-generated-layout-host-v1':
      case 'collapsible-generated-section-layout-host-v1':
      case 'resizable-generated-pane-layout-host-v1':
      case 'breadcrumb-generated-trail-layout-host-v1':
        final binding = bindSectionLayoutBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed section layout witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (source.nativeAdapterId ==
            BoxObservationSourceSpec
                .disclosureHeaderContentInset
                .nativeAdapterId) {
          if (binding.readerId != 'current-render-padding-v1') {
            throw const BoxObservationError(
              'UNSUPPORTED_PADDING_READER',
              'No existing observer reads this declared source inset.',
            );
          }
          binding.validateExistingCurrentBinding();
          observation = observeSourceOwnedRenderPadding(
            owner: binding.paddingSource,
            scope: binding.scope,
          );
        } else {
          observation = binding.readDeclaredAbsence();
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'icon-generated-visual-frame-content-inset-v1':
      case 'number-ticker-generated-text-layout-host-v1':
      case 'skeleton-text-generated-lines-layout-host-v1':
      case 'countdown-generated-value-layout-host-v1':
        final binding = bindVisualValueBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No current visual value source describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (binding.readerId != 'visual-value-declared-absence-v1') {
          throw const BoxObservationError(
            'UNSUPPORTED_VISUAL_VALUE_READER',
            'No declared layout absence reader matches this source.',
          );
        }
        binding.validateExistingCurrentBinding();
        observation = binding.readDeclaredAbsence();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.owner, binding.paddingSource) ||
            !identical(observation.producer, resultElement) ||
            !identical(observation.frameOwner, binding.frameSource) ||
            observation.quantity != PaddingQuantityKind.declaredNoOwnPadding) {
          throw const BoxObservationError(
            'MISMATCHED_VISUAL_VALUE_OBSERVATION',
            'The current reader must retain its producer, owner and frame.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'command-search-generated-trigger-content-inset-v1':
      case 'navigation-bar-generated-items-content-inset-v1':
      case 'dock-generated-bar-content-inset-v1':
        final binding = bindNavigationTriggerBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No current navigation source describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        binding.validateExistingCurrentBinding();
        observation = binding.readActualPadding();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.owner, binding.paddingSource) ||
            !identical(observation.producer, resultElement) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_NAVIGATION_OBSERVATION',
            'The current reader must retain its producer and frame.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'theme-controller-generated-option-grid-layout-host-v1':
      case 'tracker-generated-segment-row-layout-host-v1':
      case 'bottom-sheet-generated-outer-layout-host-v1':
      case 'swiper-generated-trigger-layout-host-v1':
      case 'diff-generated-viewer-layout-host-v1':
        final binding = bindDataOverlayLayoutBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No current data/overlay source describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (binding.readerId != 'data-overlay-layout-declared-absence-v1') {
          throw const BoxObservationError(
            'UNSUPPORTED_DATA_OVERLAY_READER',
            'No declared layout absence reader matches this source.',
          );
        }
        binding.validateExistingCurrentBinding();
        observation = binding.readDeclaredAbsence();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_DATA_OVERLAY_OBSERVATION',
            'The actual observer must retain the current producer/frame.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'basic-generated-content-inset-v1':
      case 'disclosure-badge-solid-content-inset-v1':
      case 'multiple-choice-generated-options-layout-host-v1':
      case 'page-header-generated-layout-host-v1':
      case 'sidebar-generated-outer-layout-host-v1':
      case 'tab-pane-generated-bar-content-inset-v1':
      case 'tree-generated-outer-layout-host-v1':
      case 'timeline-generated-sequence-layout-host-v1':
      case 'category-breakdown-generated-layout-host-v1':
      case 'trend-chart-generated-outer-layout-host-v1':
      case 'window-panel-generated-frame-content-inset-v1':
        final binding = bindStructuredRootBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed structured root witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        final reader = switch (source.nativeAdapterId) {
          'basic-generated-content-inset-v1' ||
          'tab-pane-generated-bar-content-inset-v1' =>
            'current-render-padding-v1',
          'disclosure-badge-solid-content-inset-v1' =>
            'structured-solid-border-content-v1',
          'window-panel-generated-frame-content-inset-v1' =>
            'current-outlined-container-content-v1',
          'multiple-choice-generated-options-layout-host-v1' ||
          'page-header-generated-layout-host-v1' ||
          'sidebar-generated-outer-layout-host-v1' ||
          'tree-generated-outer-layout-host-v1' ||
          'timeline-generated-sequence-layout-host-v1' ||
          'category-breakdown-generated-layout-host-v1' ||
          'trend-chart-generated-outer-layout-host-v1' =>
            'structured-root-declared-absence-v1',
          _ => throw const BoxObservationError(
            'UNSUPPORTED_STRUCTURED_ROOT_READER',
            'No reader is declared for this structured source unit.',
          ),
        };
        if (binding.readerId != reader) {
          throw const BoxObservationError(
            'UNSUPPORTED_STRUCTURED_ROOT_READER',
            'The current binding reader differs from its closed unit.',
          );
        }
        binding.validateExistingCurrentBinding();
        observation = reader == 'structured-root-declared-absence-v1'
            ? binding.readDeclaredAbsence()
            : binding.readActualPadding();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_STRUCTURED_ROOT_OBSERVATION',
            'The actual observer must retain its original producer/frame.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'text-field-generated-content-inset-v1':
      case 'validated-generated-layout-host-v1':
      case 'validator-hint-generated-message-layout-host-v1':
      case 'scroll-area-generated-viewport-layout-host-v1':
      case 'fade-scroll-generated-viewport-layout-host-v1':
      case 'overflow-marquee-generated-viewport-layout-host-v1':
      case 'kbd-generated-key-sequence-layout-host-v1':
        final binding = bindValidationViewportBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed validation/viewport witness describes this input.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        final reader = source == BoxObservationSourceSpec.textFieldContentInset
            ? 'current-render-padding-v1'
            : 'validation-viewport-declared-absence-v1';
        if (binding.readerId != reader) {
          throw const BoxObservationError(
            'UNSUPPORTED_VALIDATION_VIEWPORT_READER',
            'The reader differs from its closed validation/viewport unit.',
          );
        }
        binding.validateExistingCurrentBinding();
        observation = reader == 'current-render-padding-v1'
            ? binding.readActualPadding()
            : binding.readDeclaredAbsence();
        binding.scope.requireOwned(observation.owner);
        if (!identical(observation.producer, resultElement) ||
            !identical(observation.owner, binding.paddingSource) ||
            !identical(observation.frameOwner, binding.frameSource)) {
          throw const BoxObservationError(
            'MISMATCHED_VALIDATION_VIEWPORT_OBSERVATION',
            'The actual observer must retain its declared owner/frame.',
          );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
          if (reader == 'validation-viewport-declared-absence-v1')
            'declaredAbsenceKind': binding.absenceKind,
        };
      case 'calendar-generated-layout-host-v1':
      case 'definition-list-generated-layout-host-v1':
        final binding = bindCollectionLayoutHostBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed collection layout host describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'loading-generated-size-host-v1':
        final binding = bindLoadingHostBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed loading host witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'status-generated-dot-content-inset-v1':
      case 'tag-generated-label-content-inset-v1':
      case 'skeleton-circular-block-content-inset-v1':
        final binding = bindDisplayParameterBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed display parameter witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        if (binding.readerId != 'current-container-v1') {
          throw const BoxObservationError(
            'UNSUPPORTED_DISPLAY_PARAMETER_READER',
            'No existing observer reads this declared display parameter.',
          );
        }
        binding.validateCurrentConstruction();
        observation = observeCurrentContainerPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        );
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'steps-generated-sequence-host-v1':
      case 'stepper-vertical-sequence-host-v1':
      case 'aspect-ratio-generated-layout-host-v1':
      case 'clickable-generated-interaction-host-v1':
      case 'focus-outline-generated-pass-through-host-v1':
      case 'switch-field-generated-control-row-v1':
        final binding = bindLayoutHostBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed layout host witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'kbd-single-keycap-content-inset-v1':
      case 'app-bar-medium-toolbar-content-inset-v1':
      case 'documentation-refresh-viewport-content-inset-v1':
        final binding = bindContentParameterBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed content parameter witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        switch (binding.readerId) {
          case 'current-render-padding-v1':
            binding.validateCurrentConstruction();
            observation = observeSourceOwnedRenderPadding(
              owner: binding.paddingSource,
              scope: binding.scope,
            );
          case 'outlined-content-v1':
            binding.validateCurrentConstruction();
            observation = observeOutlinedContainerContentPadding(
              primitive: binding.paddingSource,
              declaringScope: binding.scope,
            );
          default:
            throw const BoxObservationError(
              'UNSUPPORTED_CONTENT_PARAMETER_READER',
              'No existing observer reads this declared content parameter.',
            );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'mask-generated-clip-host-v1':
      case 'hover-generated-effect-host-v1':
      case 'indicator-generated-overlay-host-v1':
        if (source == BoxObservationSourceSpec.hoverEffectHost) {
          // A recognized shadow failure propagates to the outer incomplete
          // result. Only an unsupported old effect can continue below.
          final shadow = bindValidationViewportBoxSource(
            captureRoot: captureRoot,
            registryResult: registryResult,
            source: source,
          );
          if (shadow != null) {
            if (!identical(shadow.registryResultElement, resultElement) ||
                !identical(shadow.scope.producer, resultElement) ||
                shadow.authority.isEmpty) {
              throw const BoxObservationError(
                'MISMATCHED_COMPONENT_SOURCE',
                'No current complete shadow projection describes this input.',
              );
            }
            shadow.scope
              ..requireOwned(shadow.fieldUnitElement)
              ..requireOwned(shadow.paddingSource)
              ..requireOwned(shadow.frameSource);
            if (shadow.readerId != 'validation-viewport-declared-absence-v1') {
              throw const BoxObservationError(
                'UNSUPPORTED_VALIDATION_VIEWPORT_READER',
                'The shadow observer requires its declared absence reader.',
              );
            }
            shadow.validateExistingCurrentBinding();
            observation = shadow.readDeclaredAbsence();
            shadow.scope.requireOwned(observation.owner);
            if (!identical(observation.producer, resultElement) ||
                !identical(observation.owner, shadow.paddingSource) ||
                !identical(observation.frameOwner, shadow.frameSource)) {
              throw const BoxObservationError(
                'MISMATCHED_VALIDATION_VIEWPORT_OBSERVATION',
                'The shadow observer must retain its declared owner/frame.',
              );
            }
            sourceBindingProvenance = {
              'sourceBindingAuthority': shadow.authority,
              'fieldUnitElement': identityHashCode(shadow.fieldUnitElement),
              'declaredPaddingSourceElement': identityHashCode(
                shadow.paddingSource,
              ),
              'declaredFrameSourceElement': identityHashCode(
                shadow.frameSource,
              ),
              'sourceReaderId': shadow.readerId,
              'declaredAbsenceKind': shadow.absenceKind,
            };
            break;
          }
        }
        final binding = bindProxyHostBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed proxy host witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
          'declaredAbsenceKind': binding.absenceKind,
        };
      case 'docs-chat-single-bubble-frame-v1':
        final binding = bindChatBubbleBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No example-owned bubble witness describes this construction.',
          );
        }
        binding.validateCurrentConstruction();
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = observeSourceOwnedRenderPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        );
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'label-generated-inline-host-v1':
      case 'link-generated-inline-host-v1':
        final binding = bindInlineHostBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null ||
            !identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw const BoxObservationError(
            'MISMATCHED_COMPONENT_SOURCE',
            'No closed inline source witness describes this construction.',
          );
        }
        binding.scope
          ..requireOwned(binding.fieldUnitElement)
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        observation = binding.readDeclaredAbsence();
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
          'declaredAbsenceKind': binding.absenceKind,
        };
      case 'mockup-device-generated-body-frame-content-inset-v1':
      case 'join-generated-strip-layout-host-v1':
      case 'table-generated-grid-content-inset-v1':
        final binding = bindFramedCollectionBoxSource(
          captureRoot: captureRoot,
          registryResult: registryResult,
          source: source,
        );
        if (binding == null) {
          throw const BoxObservationError(
            'MISSING_FRAMED_COLLECTION_SOURCE',
            'No current framed collection construction describes this unit.',
          );
        }
        final current = _readFramedCollectionBinding(
          binding,
          resultElement,
          source,
        );
        observation = current.observation;
        sourceBindingProvenance = current.provenance;
      case 'docs-stage-current-container-v1':
      case 'whole-doc-card-frame-v1':
      case 'docs-size-preview-frame-v1':
      case 'code-diff-generated-frame-v1':
      case 'command-panel-generated-frame-v1':
      case 'fieldset-generated-frame-v1':
      case 'item-picker-generated-frame-v1':
      case 'mockup-browser-generated-frame-v1':
      case 'object-input-generated-frame-v1':
      case 'banner-generated-frame-v1':
      case 'description-card-generated-frame-v1':
      case 'formatted-input-generated-frame-v1':
      case 'frame-generated-content-inset-v1':
      case 'avatar-generated-frame-v1':
      case 'code-snippet-generated-frame-v1':
      case 'stat-generated-frame-v1':
      case 'validation-badge-generated-frame-v1':
      case 'number-input-generated-field-frame-v1':
      case 'chip-generated-frame-v1':
      case 'app-bar-solid-content-inset-v1':
      case 'empty-state-generated-content-inset-v1':
        if (source.nativeAdapterId == 'mockup-browser-generated-frame-v1') {
          final framed = bindFramedCollectionBoxSource(
            captureRoot: captureRoot,
            registryResult: registryResult,
            source: source,
          );
          if (framed != null) {
            final current = _readFramedCollectionBinding(
              framed,
              resultElement,
              source,
            );
            observation = current.observation;
            sourceBindingProvenance = current.provenance;
            break;
          }
        }
        final componentSource = BoxObservationSourceSpec.componentFrames
            .contains(
              source,
            );
        final extendedSource = BoxObservationSourceSpec.extendedComponentFrames
            .contains(source);
        final displaySource = BoxObservationSourceSpec.displayComponentFrames
            .contains(source);
        final controlSource = BoxObservationSourceSpec.controlShellFrames
            .contains(source);
        final solidSource = BoxObservationSourceSpec.solidLayoutFrames.contains(
          source,
        );
        final isComponent =
            componentSource ||
            extendedSource ||
            displaySource ||
            controlSource ||
            solidSource;
        final binding = solidSource
            ? bindSolidLayoutBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              )
            : controlSource
            ? bindControlShellBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              )
            : displaySource
            ? bindDisplayBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              )
            : extendedSource
            ? bindExtendedComponentBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              )
            : componentSource
            ? bindComponentBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              )
            : bindDocumentationBoxSource(
                captureRoot: captureRoot,
                registryResult: registryResult,
                source: source,
              );
        if (binding == null) {
          throw BoxObservationError(
            isComponent
                ? 'UNREGISTERED_COMPONENT_CONSTRUCTION'
                : 'UNREGISTERED_DOCUMENTATION_SOURCE',
            'The semantic unit has no closed source-construction route.',
          );
        }
        if (!identical(binding.registryResultElement, resultElement) ||
            !identical(binding.scope.producer, resultElement) ||
            binding.authority.isEmpty) {
          throw BoxObservationError(
            isComponent
                ? 'MISMATCHED_COMPONENT_SOURCE'
                : 'MISMATCHED_DOCUMENTATION_SOURCE',
            'The binding does not describe this actual construction result.',
          );
        }
        binding.scope.requireOwned(binding.fieldUnitElement);
        binding.scope.requireOwned(binding.paddingSource);
        if (binding.frameSource case final frame?) {
          binding.scope.requireOwned(frame);
        }
        switch (binding.readerId) {
          case 'current-container-v1':
            observation = observeCurrentContainerPadding(
              owner: binding.paddingSource,
              scope: binding.scope,
            );
          case 'outlined-content-v1':
            observation = observeOutlinedContainerContentPadding(
              primitive: binding.paddingSource,
              declaringScope: binding.scope,
            );
          case 'current-render-padding-v1':
            observation = observeSourceOwnedRenderPadding(
              owner: binding.paddingSource,
              scope: binding.scope,
            );
          default:
            throw const BoxObservationError(
              'UNSUPPORTED_DOCUMENTATION_PADDING_READER',
              'No shared observer reads this declared source route.',
            );
        }
        sourceBindingProvenance = {
          'sourceBindingAuthority': binding.authority,
          'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
          'declaredPaddingSourceElement': identityHashCode(
            binding.paddingSource,
          ),
          'declaredFrameSourceElement': binding.frameSource == null
              ? null
              : identityHashCode(binding.frameSource),
          'sourceReaderId': binding.readerId,
        };
      case 'direct-framework-container-v1':
        if (registryResult is! Container &&
            registryResult is! AnimatedContainer) {
          throw const BoxObservationError(
            'SOURCE_CONTRACT_PRODUCER_MISMATCH',
            'The declared layout unit must itself be a Container.',
          );
        }
        observation = observeCurrentContainerPadding(
          owner: registryResult is AnimatedContainer
              ? evaluatedAnimatedContainer(resultElement)
              : resultElement,
          scope: registryResult is AnimatedContainer
              ? BoxProducerScope(
                  producer: resultElement,
                  suppliedSlots: [?registryResult.child],
                )
              : DeclaredBoxProducer.bind(
                  producer: resultElement,
                  sourceContract: 'renderer-frame-padding-v1',
                ).scope,
        );
      default:
        throw const BoxObservationError(
          'UNSUPPORTED_NATIVE_BOX_ADAPTER',
          'No native source adapter implements this declaration.',
        );
    }
    return {
      ...observation.toJson(),
      ...sourceBindingProvenance,
      'status': 'source-complete',
      'sourceUnitValidated': true,
      'source': source.toJson(),
      'layoutRootElement': identityHashCode(resultElement),
      'legacyRoleEligible': !legacyRootOmitted,
      'paintRequired': false,
      'canonicalComparisonEligible': false,
    };
  } on BoxObservationError catch (error) {
    return {
      'status': 'incomplete',
      'error': error.code,
      'reason': error.reason,
    };
  } on FormatException catch (error) {
    return {
      'status': 'incomplete',
      'error': 'MALFORMED_BOX_SOURCE',
      'reason': '$error',
    };
  }
}

({BoxPaddingObservation observation, Map<String, Object?> provenance})
_readFramedCollectionBinding(
  FramedCollectionBoxSourceBinding binding,
  Element resultElement,
  BoxObservationSourceSpec source,
) {
  if (!identical(binding.registryResultElement, resultElement) ||
      !identical(binding.scope.producer, resultElement) ||
      binding.authority.isEmpty) {
    throw const BoxObservationError(
      'MISMATCHED_FRAMED_COLLECTION_SOURCE',
      'The current binding must retain its exact registry and producer.',
    );
  }
  binding.scope
    ..requireOwned(binding.fieldUnitElement)
    ..requireOwned(binding.paddingSource)
    ..requireOwned(binding.frameSource);
  if (!BoxProducerScope.contains(
        binding.fieldUnitElement,
        binding.frameSource,
      ) ||
      !BoxProducerScope.contains(
        binding.frameSource,
        binding.paddingSource,
      )) {
    throw const BoxObservationError(
      'MISMATCHED_FRAMED_COLLECTION_BOUNDARIES',
      'The actual field must own the frame and its padding source.',
    );
  }
  final expected = switch (source.nativeAdapterId) {
    'mockup-device-generated-body-frame-content-inset-v1' ||
    'join-generated-strip-layout-host-v1' => (
      'framed-collection-declared-absence-v1',
      PaddingQuantityKind.declaredNoOwnPadding,
    ),
    'table-generated-grid-content-inset-v1' => (
      'framed-table-border-content-v1',
      PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder,
    ),
    'mockup-browser-generated-frame-v1' => (
      'outlined-content-v1',
      PaddingQuantityKind.frameworkOwnParameter,
    ),
    _ => throw const BoxObservationError(
      'UNSUPPORTED_FRAMED_COLLECTION_READER',
      'No current framed collection reader matches this closed source.',
    ),
  };
  if (binding.readerId != expected.$1) {
    throw const BoxObservationError(
      'UNSUPPORTED_FRAMED_COLLECTION_READER',
      'The binding reader must match the declared source operation.',
    );
  }
  binding.validateExistingCurrentBinding();
  final observed = expected.$1 == 'framed-collection-declared-absence-v1'
      ? binding.readDeclaredAbsence()
      : binding.readActualPadding();
  binding.scope.requireOwned(observed.owner);
  if (!identical(observed.owner, binding.paddingSource) ||
      !identical(observed.producer, resultElement) ||
      !identical(observed.frameOwner, binding.frameSource) ||
      observed.quantity != expected.$2) {
    throw const BoxObservationError(
      'MISMATCHED_FRAMED_COLLECTION_OBSERVATION',
      'The current observation must retain its actual owner, frame and kind.',
    );
  }
  return (
    observation: observed,
    provenance: {
      'sourceBindingAuthority': binding.authority,
      'fieldUnitElement': identityHashCode(binding.fieldUnitElement),
      'declaredPaddingSourceElement': identityHashCode(binding.paddingSource),
      'declaredFrameSourceElement': identityHashCode(binding.frameSource),
      'sourceReaderId': binding.readerId,
    },
  );
}

Element _singleChild(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the declared generated child');
}
