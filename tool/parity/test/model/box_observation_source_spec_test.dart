import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_pair.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/probe_spec.dart';

void main() {
  _additionalShowcaseAllocationTests();
  _showcaseAllocationTests();
  const breakpointSource =
      BoxObservationSourceSpec.breakpointShowcaseContentInset;
  test('only classic Breakpoint/default maps its separate content inset', () {
    expect(breakpointSource.toJson(), const {
      'schemaVersion': 1,
      'logicalUnitId': 'classic-breakpoint-showcase-content-inset',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'classic-breakpoint-showcase-content-inset-v1',
      'webAdapterId': 'classic-breakpoint-showcase-content-inset-v1',
    });
    expect(breakpointSource.validationError, isNull);
    for (final theme in ['light', 'dark']) {
      final key = 'breakpoint-default-$theme-defaultStyle';
      final actual = captureProbes(
        key: key,
        component: 'breakpoint',
        variant: 'default',
        flutterClassName: 'Breakpoint',
      );
      expect(actual, hasLength(1));
      expect(actual.single.boxObservationSource, breakpointSource);
      expect(
        actual.single.toJson()..remove('boxObservationSource'),
        rootProbeSpec(key: key, flutterClassName: 'Breakpoint').toJson(),
      );
    }
  });
  test('Breakpoint source does not grant other recipes or forged adapters', () {
    for (final pair in [
      ('breakpoint', 'chain'),
      ('breakpoint', 'docs-v2-unreviewed'),
      ('text', 'default'),
      ('button', 'default'),
    ]) {
      expect(
        () => requireCaptureProbes(
          component: pair.$1,
          variant: pair.$2,
          roles: const ['root'],
          boxObservationSources: const [breakpointSource],
        ),
        throwsFormatException,
      );
    }
    final wrong = BoxObservationSourceSpec.fromJson({
      ...breakpointSource.toJson(),
      'webAdapterId': 'foreign',
    });
    expect(wrong.validationError, isNotNull);
    expect(
      () => requireCaptureProbes(
        component: 'breakpoint',
        variant: 'default',
        roles: const ['root'],
        boxObservationSources: [wrong],
      ),
      throwsFormatException,
    );
  });

  // The pre-change literal wire tuple is preserved in the frozen RED input.
  // Use its identical registered constant after production registration.
  const textShowcase = BoxObservationSourceSpec.textShowcaseOuterPadding;
  const textVariants = [
    'typography-display',
    'typography-headline',
    'typography-title',
    'typography-body',
    'typography-weight',
    'typography-primitive',
    'colors-brand',
    'colors-status',
    'colors-surface',
    'modifiers',
    'wrap',
    'keep-all',
    'textstyle',
    'opacity',
    'rich',
  ];
  test('classic Text showcase tuple is registered exactly', () {
    expect(textShowcase.toJson(), const {
      'schemaVersion': 1,
      'logicalUnitId': 'classic-text-showcase-generated-padding-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'classic-text-showcase-outer-padding-v1',
      'webAdapterId': 'classic-text-showcase-outer-padding-v1',
    });
    expect(textShowcase.validationError, isNull);
    expect(
      BoxObservationSourceSpec.fromJson(textShowcase.toJson()),
      textShowcase,
    );
  });
  for (final variant in textVariants) {
    for (final theme in ['light', 'dark']) {
      test('classic text/$variant/$theme retains its legacy probe', () {
        final key = 'text-$variant-$theme-defaultStyle';
        final probes = captureProbes(
          key: key,
          component: 'text',
          variant: variant,
          flutterClassName: 'Text',
        );
        expect(probes, hasLength(1));
        final root = probes.single;
        expect(root.boxObservationSource, textShowcase);
        expect(
          root.toJson()..remove('boxObservationSource'),
          rootProbeSpec(key: key, flutterClassName: 'Text').toJson(),
        );
        expect(
          () => requireCaptureProbes(
            component: 'text',
            variant: variant,
            roles: [root.role],
            boxObservationSources: [textShowcase],
          ),
          returnsNormally,
        );
      });
    }
  }
  test('Text showcase source has no key or finder routing', () {
    for (final key in [
      'caller-owned-key',
      'button-default-dark-defaultStyle',
    ]) {
      expect(
        captureProbes(
          key: key,
          component: 'text',
          variant: 'rich',
          flutterClassName: 'UnrelatedFinderName',
        ).single.boxObservationSource,
        textShowcase,
      );
    }
  });
  test('Text showcase source cannot be borrowed by other recipes', () {
    for (final (component, variant) in const [
      ('text', 'default'),
      ('text', 'typography-body-unreviewed'),
      ('text', 'docs-v2-unreviewed'),
      ('text', 'TextRichExample'),
      ('button', 'typography-display'),
      ('skeleton', 'text'),
      ('diff', 'text'),
      ('mockup-device', 'default'),
    ]) {
      final probes = captureProbes(
        key: 'cross-recipe-key',
        component: component,
        variant: variant,
        flutterClassName: 'Text',
      );
      expect(
        probes.map((probe) => probe.boxObservationSource),
        isNot(contains(textShowcase)),
      );
      expect(
        () => requireCaptureProbes(
          component: component,
          variant: variant,
          roles: probes.map((probe) => probe.role),
          boxObservationSources: [textShowcase],
        ),
        throwsFormatException,
      );
    }
  });
  test('claimed Text unit rejects a malformed schema or adapter tuple', () {
    for (final change in <Map<String, Object?>>[
      {'schemaVersion': 99},
      {'quantityId': 'unreviewed-quantity'},
      {'nativeAdapterId': BoxObservationSourceSpec.outlined.nativeAdapterId},
      {'webAdapterId': BoxObservationSourceSpec.outlined.webAdapterId},
    ]) {
      final malformed = BoxObservationSourceSpec.fromJson({
        ...textShowcase.toJson(),
        ...change,
      });
      expect(malformed.validationError, isNotNull);
      expect(
        () => requireCaptureProbes(
          component: 'text',
          variant: 'rich',
          roles: const ['root'],
          boxObservationSources: [malformed],
        ),
        throwsFormatException,
      );
    }
  });

  const nextParameterRecipes =
      <
        ({
          String component,
          String variant,
          BoxObservationSourceSpec source,
        })
      >[
        (
          component: 'toggle-group',
          variant: 'default',
          source: BoxObservationSourceSpec.toggleGroupTrackContentInset,
        ),
        (
          component: 'toggle-group',
          variant: 'vertical',
          source: BoxObservationSourceSpec.toggleGroupTrackContentInset,
        ),
        (
          component: 'form-field',
          variant: 'default',
          source: BoxObservationSourceSpec.formFieldLayoutHost,
        ),
        (
          component: 'form-label',
          variant: 'default',
          source: BoxObservationSourceSpec.formLabelRowLayoutHost,
        ),
        (
          component: 'listing',
          variant: 'default',
          source: BoxObservationSourceSpec.listingRowsLayoutHost,
        ),
        (
          component: 'option-list',
          variant: 'default',
          source: BoxObservationSourceSpec.optionListLayoutHost,
        ),
        (
          component: 'disclosure',
          variant: 'default',
          source: BoxObservationSourceSpec.disclosureHeaderContentInset,
        ),
        (
          component: 'disclosure',
          variant: 'chain',
          source: BoxObservationSourceSpec.disclosureHeaderContentInset,
        ),
        (
          component: 'disclosure',
          variant: 'group',
          source: BoxObservationSourceSpec.disclosureGroupLayoutHost,
        ),
        (
          component: 'collapsible',
          variant: 'default',
          source: BoxObservationSourceSpec.collapsibleSectionLayoutHost,
        ),
        (
          component: 'resizable',
          variant: 'default',
          source: BoxObservationSourceSpec.resizablePaneLayoutHost,
        ),
        (
          component: 'breadcrumb',
          variant: 'default',
          source: BoxObservationSourceSpec.breadcrumbTrailLayoutHost,
        ),
      ];
  const nextParameterSources = [
    ...BoxObservationSourceSpec.formCollectionFrames,
    ...BoxObservationSourceSpec.sectionLayoutFrames,
  ];
  test(
    'next parameter units retain the existing quantity and unique tuples',
    () {
      expect(nextParameterSources, hasLength(10));
      expect(
        nextParameterSources.map((s) => s.logicalUnitId).toSet(),
        hasLength(nextParameterSources.length),
      );
      expect(
        nextParameterSources.map((s) => s.nativeAdapterId).toSet(),
        hasLength(nextParameterSources.length),
      );
      expect(
        nextParameterSources.map((s) => s.webAdapterId).toSet(),
        hasLength(nextParameterSources.length),
      );
      for (final source in nextParameterSources) {
        expect(source.quantityId, BoxObservationSourceSpec.quantity);
        expect(source.schemaVersion, 1);
        expect(source.nativeAdapterId, '${source.logicalUnitId}-v1');
        expect(source.webAdapterId, source.nativeAdapterId);
      }
    },
  );
  for (final source in nextParameterSources) {
    test(
      '${source.logicalUnitId} metadata does not grant observation proof',
      () {
        final decoded = BoxObservationSourceSpec.fromJson(source.toJson());
        expect(decoded, source);
        expect(decoded.validationError, isNull);
        final missingCurrentWitness = <String, Object?>{
          'status': 'incomplete',
          'source': source.toJson(),
          'error': 'MISSING_CURRENT_SOURCE_WITNESS',
        };
        final gate = boxObservationPairGate(
          expected: source,
          native: missingCurrentWitness,
          web: missingCurrentWitness,
        );
        expect(gate.nativeComplete, false);
        expect(gate.webComplete, false);
        expect(gate.eligible, false);
        expect(gate.error, 'INCOMPLETE_SOURCE_PAIR');
        expect(missingCurrentWitness.containsKey('value'), false);
        for (final mutation in <Map<String, Object?>>[
          {...source.toJson(), 'schemaVersion': 99},
          {...source.toJson(), 'quantityId': 'unknown-quantity'},
          {
            ...source.toJson(),
            'nativeAdapterId':
                BoxObservationSourceSpec.outlined.nativeAdapterId,
          },
          {
            ...source.toJson(),
            'webAdapterId': BoxObservationSourceSpec.outlined.webAdapterId,
          },
        ]) {
          expect(
            BoxObservationSourceSpec.fromJson(mutation).validationError,
            isNotNull,
          );
        }
      },
    );
  }
  for (final recipe in nextParameterRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme preserves legacy unit',
        () {
          final key =
              '${recipe.component}-${recipe.variant}-$theme-defaultStyle';
          final probes = captureProbes(
            key: key,
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'unchanged-public-constructor',
          );
          expect(probes, hasLength(1));
          final root = probes.single;
          expect(root.boxObservationSource, recipe.source);
          final legacy = rootProbeSpec(
            key: key,
            flutterClassName: 'unchanged-public-constructor',
          );
          final legacyPayload = root.toJson()..remove('boxObservationSource');
          expect(legacyPayload, legacy.toJson());
          expect(
            () => requireCaptureProbes(
              component: recipe.component,
              variant: recipe.variant,
              roles: probes.map((p) => p.role),
              boxObservationSources: probes.map((p) => p.boxObservationSource),
            ),
            returnsNormally,
          );
          for (final foreign in [
            ('stat', 'default'),
            (recipe.component, 'unproved-recipe'),
          ]) {
            expect(
              () => requireCaptureProbes(
                component: foreign.$1,
                variant: foreign.$2,
                roles: ['root'],
                boxObservationSources: [recipe.source],
              ),
              throwsFormatException,
            );
          }
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} key does not select source',
      () {
        for (final key in [
          'without-style-suffix',
          'arbitrary-caller-key',
          'rawStyle:source-fixture',
        ]) {
          expect(
            captureProbes(
              key: key,
              component: recipe.component,
              variant: recipe.variant,
              flutterClassName: 'unchanged-public-constructor',
            ).single.boxObservationSource,
            recipe.source,
          );
        }
      },
    );
  }
  test(
    'Disclosure group and header declarations are separate logical fields',
    () {
      for (final pair in [
        ('default', BoxObservationSourceSpec.disclosureGroupLayoutHost),
        ('chain', BoxObservationSourceSpec.disclosureGroupLayoutHost),
        ('group', BoxObservationSourceSpec.disclosureHeaderContentInset),
      ]) {
        expect(
          () => requireCaptureProbes(
            component: 'disclosure',
            variant: pair.$1,
            roles: ['root'],
            boxObservationSources: [pair.$2],
          ),
          throwsFormatException,
        );
      }
    },
  );
  for (final unsupported in <(String, String)>[
    ('toggle-group', 'disabled'),
    ('form-field', 'unknown'),
    ('form-label', 'unknown'),
    ('listing', 'unknown'),
    ('option-list', 'unknown'),
    ('disclosure', 'unproved-current-branch'),
    ('collapsible', 'unknown'),
    ('resizable', 'unknown'),
    ('breadcrumb', 'unknown'),
  ]) {
    test('${unsupported.$1}/${unsupported.$2} gets no source grant', () {
      final root = captureProbes(
        key: 'unsupported-source-fixture',
        component: unsupported.$1,
        variant: unsupported.$2,
        flutterClassName: 'unchanged-constructor',
      ).single;
      expect(root.boxObservationSource, isNull);
      expect(
        root.toJson(),
        rootProbeSpec(
          key: 'unsupported-source-fixture',
          flutterClassName: 'unchanged-constructor',
        ).toJson(),
      );
    });
  }

  for (final source in [
    BoxObservationSourceSpec.outlined,
    BoxObservationSourceSpec.docsStage,
    BoxObservationSourceSpec.declaredLayout,
    BoxObservationSourceSpec.wholeDocCard,
    BoxObservationSourceSpec.docsSizePreview,
    BoxObservationSourceSpec.docsPlayground,
    ...BoxObservationSourceSpec.componentFrames,
    ...BoxObservationSourceSpec.extendedComponentFrames,
    ...BoxObservationSourceSpec.displayComponentFrames,
    ...BoxObservationSourceSpec.controlShellFrames,
    ...BoxObservationSourceSpec.solidLayoutFrames,
    ...BoxObservationSourceSpec.inlineHostFrames,
    ...BoxObservationSourceSpec.proxyHostFrames,
    ...BoxObservationSourceSpec.documentationBubbleFrames,
    ...BoxObservationSourceSpec.layoutHostFrames,
    ...BoxObservationSourceSpec.contentParameterFrames,
    ...BoxObservationSourceSpec.loadingHostFrames,
    ...BoxObservationSourceSpec.displayParameterFrames,
    ...BoxObservationSourceSpec.explicitContentInsetFrames,
    ...BoxObservationSourceSpec.collectionLayoutHostFrames,
    ...BoxObservationSourceSpec.layoutStructureFrames,
    ...BoxObservationSourceSpec.formCollectionFrames,
    ...BoxObservationSourceSpec.sectionLayoutFrames,
  ]) {
    test('closed source round-trip: ${source.logicalUnitId}', () {
      final decoded = BoxObservationSourceSpec.fromJson(source.toJson());
      expect(decoded, source);
      expect(decoded.validationError, isNull);
    });
  }
  test('unknown versions and mismatched adapters fail closed', () {
    final original = BoxObservationSourceSpec.outlined.toJson();
    expect(
      BoxObservationSourceSpec.fromJson({
        ...original,
        'schemaVersion': 99,
      }).validationError,
      'UNSUPPORTED_BOX_SOURCE_VERSION',
    );
    expect(
      BoxObservationSourceSpec.fromJson({
        ...original,
        'webAdapterId': BoxObservationSourceSpec.docsStage.webAdapterId,
      }).validationError,
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
    );
    expect(
      () => BoxObservationSourceSpec.fromJson({
        ...original,
        'schemaVersion': '1',
      }),
      throwsFormatException,
    );
  });
  for (final source in BoxObservationSourceSpec.layoutStructureFrames) {
    test('${source.logicalUnitId} keeps its exact schema and adapter pair', () {
      expect(
        BoxObservationSourceSpec.fromJson({
          ...source.toJson(),
          'schemaVersion': 99,
        }).validationError,
        'UNSUPPORTED_BOX_SOURCE_VERSION',
      );
      expect(
        BoxObservationSourceSpec.fromJson({
          ...source.toJson(),
          'quantityId': 'unregistered-layout-quantity',
        }).validationError,
        'UNSUPPORTED_BOX_QUANTITY',
      );
      expect(
        BoxObservationSourceSpec.fromJson({
          ...source.toJson(),
          'webAdapterId': BoxObservationSourceSpec.outlined.webAdapterId,
        }).validationError,
        'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      );
    });
  }
  test('a collection does not inherit the single-primitive declaration', () {
    final single = captureProbes(
      key: 'single',
      component: 'outlined-container',
      variant: 'default',
      flutterClassName: 'OutlinedContainer',
    ).single;
    final collection = captureProbes(
      key: 'collection',
      component: 'outlined-container',
      variant: 'chain',
      flutterClassName: 'OutlinedContainer',
    ).single;
    expect(single.boxObservationSource, BoxObservationSourceSpec.outlined);
    expect(collection.boxObservationSource, isNull);
    expect(collection.fields, single.fields);
  });
  test(
    'a display source is bound to its actual closed construction recipe',
    () {
      final probe = captureProbes(
        key: 'avatar',
        component: 'avatar',
        variant: 'rounded',
        flutterClassName: 'Avatar',
      ).single;
      expect(probe.boxObservationSource, BoxObservationSourceSpec.avatarFrame);
      expect(
        () => requireCaptureProbes(
          component: 'avatar',
          variant: 'rounded',
          roles: ['root'],
          boxObservationSources: [probe.boxObservationSource],
        ),
        returnsNormally,
      );
      for (final recipe in [('avatar', 'badge'), ('stat', 'default')]) {
        expect(
          () => requireCaptureProbes(
            component: recipe.$1,
            variant: recipe.$2,
            roles: ['root'],
            boxObservationSources: [probe.boxObservationSource],
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('a control frame declaration cannot authorize another input recipe', () {
    final probe = captureProbes(
      key: 'number-input',
      component: 'number-input',
      variant: 'filled',
      flutterClassName: 'NumberInput',
    ).single;
    expect(
      probe.boxObservationSource,
      BoxObservationSourceSpec.numberInputFrame,
    );
    expect(
      () => requireCaptureProbes(
        component: 'number-input',
        variant: 'filled',
        roles: ['root'],
        boxObservationSources: [probe.boxObservationSource],
      ),
      returnsNormally,
    );
    for (final recipe in [('number-input', 'unknown'), ('chip', 'removable')]) {
      expect(
        () => requireCaptureProbes(
          component: recipe.$1,
          variant: recipe.$2,
          roles: ['root'],
          boxObservationSources: [probe.boxObservationSource],
        ),
        throwsFormatException,
      );
    }
  });
  for (final recipe in [
    (
      component: 'app-bar',
      supported: 'centered',
      unsupported: 'medium',
      source: BoxObservationSourceSpec.appBarSolidContentInset,
    ),
    (
      component: 'empty-state',
      supported: 'failure',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.emptyStateContentInset,
    ),
    (
      component: 'label',
      supported: 'with-icon',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.labelInlineHost,
    ),
    (
      component: 'link',
      supported: 'icons',
      unsupported: 'command',
      source: BoxObservationSourceSpec.linkInlineHost,
    ),
    (
      component: 'mask',
      supported: 'heart',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.maskClipHost,
    ),
    (
      component: 'hover',
      supported: 'fade',
      unsupported: 'scale-down',
      source: BoxObservationSourceSpec.hoverEffectHost,
    ),
    (
      component: 'indicator',
      supported: 'bottom-start',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.indicatorOverlayHost,
    ),
    (
      component: 'chat',
      supported: 'neutral',
      unsupported: 'default',
      source: BoxObservationSourceSpec.docsChatSingleBubble,
    ),
    (
      component: 'steps',
      supported: 'horizontal',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.stepsSequenceHost,
    ),
    (
      component: 'stepper',
      supported: 'vertical',
      unsupported: 'horizontal',
      source: BoxObservationSourceSpec.stepperVerticalSequenceHost,
    ),
    (
      component: 'aspect-ratio-box',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.aspectRatioLayoutHost,
    ),
    (
      component: 'clickable',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.clickableInteractionHost,
    ),
    (
      component: 'focus-outline',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.focusOutlinePassThroughHost,
    ),
    (
      component: 'switch-field',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.switchFieldControlRow,
    ),
    (
      component: 'kbd',
      supported: 'single',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.kbdSingleKeycapContentInset,
    ),
    (
      component: 'app-bar',
      supported: 'medium',
      unsupported: 'glass',
      source: BoxObservationSourceSpec.appBarMediumToolbarContentInset,
    ),
    (
      component: 'refresh-trigger',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.docsRefreshViewportContentInset,
    ),
    (
      component: 'loading',
      supported: 'bar',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.loadingSizeHost,
    ),
    (
      component: 'status',
      supported: 'error',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.statusDotContentInset,
    ),
    (
      component: 'tag',
      supported: 'default',
      unsupported: 'bold',
      source: BoxObservationSourceSpec.tagLabelContentInset,
    ),
    (
      component: 'skeleton',
      supported: 'circle',
      unsupported: 'text',
      source: BoxObservationSourceSpec.skeletonCircularContentInset,
    ),
    (
      component: 'menu-item',
      supported: 'description',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.menuItemRowContentInset,
    ),
    (
      component: 'carousel-banner',
      supported: 'md',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.carouselBannerStripContentInset,
    ),
    (
      component: 'panel-header',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.panelHeaderContentInset,
    ),
    (
      component: 'calendar',
      supported: 'range',
      unsupported: 'default',
      source: BoxObservationSourceSpec.calendarLayoutHost,
    ),
    (
      component: 'definition-list',
      supported: 'columns',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.definitionListLayoutHost,
    ),
    (
      component: 'responsive-row-column',
      supported: 'desktop',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.responsiveFlexLayoutHost,
    ),
    (
      component: 'responsive-container',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.responsiveContainerContentInset,
    ),
    (
      component: 'responsive-grid',
      supported: 'span',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.responsiveGridLayoutHost,
    ),
    (
      component: 'stack-layout',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.stackLayoutOverlapHost,
    ),
    (
      component: 'indexed-switcher',
      supported: 'default',
      unsupported: 'unknown',
      source: BoxObservationSourceSpec.indexedSwitcherLayoutHost,
    ),
    (
      component: 'swap',
      supported: 'rotate',
      unsupported: 'flip',
      source: BoxObservationSourceSpec.swapOverlapLayoutHost,
    ),
    (
      component: 'divider',
      supported: 'with-child',
      unsupported: 'default',
      source: BoxObservationSourceSpec.dividerLabelledSequenceHost,
    ),
  ]) {
    test('${recipe.component} rejects a transplanted content inset source', () {
      final probes = captureProbes(
        key: 'solid-layout-source',
        component: recipe.component,
        variant: recipe.supported,
        flutterClassName: 'unchanged-legacy-finder',
      );
      final probe = probes.firstWhere((probe) => probe.role == 'root');
      expect(probe.boxObservationSource, recipe.source);
      expect(
        probe.flutterFinder,
        recipe.component == 'responsive-container'
            ? 'leadingAlignChild'
            : 'byType:unchanged-legacy-finder',
      );
      expect(
        () => requireCaptureProbes(
          component: recipe.component,
          variant: recipe.supported,
          roles: probes.map((probe) => probe.role),
          boxObservationSources: [probe.boxObservationSource],
        ),
        returnsNormally,
      );
      expect(
        () => requireCaptureProbes(
          component: recipe.component,
          variant: recipe.unsupported,
          roles: ['root'],
          boxObservationSources: [probe.boxObservationSource],
        ),
        throwsFormatException,
      );
    });
  }
  for (final recipe in <(String, String)>[
    ('command', 'dialog'),
    ('code-snippet', 'actions'),
    ('mockup-code', 'default'),
    ('mockup-code', 'tones'),
    ('avatar', 'badge'),
    ('stat', 'unknown'),
    ('validation-badge', 'unknown'),
    ('number-input', 'unknown'),
    ('chip', 'default'),
    ('progress', 'default'),
    ('bottom-action-bar', 'default'),
    ('app-bar', 'glass'),
    ('app-bar', 'foldable'),
    ('empty-state', 'unknown'),
    ('label', 'unknown'),
    ('link', 'command'),
    ('mask', 'unknown'),
    ('hover', 'scale-down'),
    ('indicator', 'unknown'),
    ('chat', 'default'),
    ('chat', 'plain'),
    ('chat', 'tail-corner'),
    ('chat', 'tail-top'),
    ('steps', 'unknown'),
    ('stepper', 'default'),
    ('stepper', 'horizontal'),
    ('stepper', 'disabled'),
    ('aspect-ratio-box', 'unknown'),
    ('clickable', 'unknown'),
    ('focus-outline', 'unknown'),
    ('switch-field', 'unknown'),
    ('kbd', 'unknown'),
    ('refresh-trigger', 'unknown'),
    ('loading', 'unknown'),
    ('status', 'unknown'),
    ('tag', 'bold'),
    ('tag', 'colors'),
    ('tag', 'sizes'),
    ('skeleton', 'default'),
    ('skeleton', 'text-unreviewed'),
    ('menu-item', 'unknown'),
    ('carousel-banner', 'unknown'),
    ('panel-header', 'unknown'),
    ('calendar', 'default'),
    ('definition-list', 'unknown'),
    ('responsive-row-column', 'unknown'),
    ('responsive-container', 'unknown'),
    ('responsive-grid', 'unknown'),
    ('stack-layout', 'unknown'),
    ('indexed-switcher', 'unknown'),
    ('swap', 'flip'),
    ('swap', 'noninteractive'),
    ('divider', 'default'),
    ('divider', 'vertical'),
  ]) {
    test('${recipe.$1}/${recipe.$2} cannot inherit a generated-frame unit', () {
      final probe = captureProbes(
        key: 'unsupported',
        component: recipe.$1,
        variant: recipe.$2,
        flutterClassName: 'sanity-only',
      ).firstWhere((probe) => probe.role == 'root');
      const allocations = {
        ('chat', 'default'),
        ('chat', 'plain'),
        ('chat', 'tail-corner'),
        ('chat', 'tail-top'),
        ('skeleton', 'default'),
      };
      if (allocations.contains(recipe)) {
        expect(probe.boxObservationSource?.toJson(), {
          'schemaVersion': 1,
          'logicalUnitId': 'classic-compound-showcase-allocation-host',
          'quantityId': 'inside-frame-own-content-inset-v1',
          'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
          'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
        });
        expect(
          () => requireCaptureProbes(
            component: recipe.$1,
            variant: recipe.$2,
            roles: ['root'],
            boxObservationSources: [
              BoxObservationSourceSpec.responsiveFlexLayoutHost,
            ],
          ),
          throwsFormatException,
        );
      } else {
        expect(probe.boxObservationSource, isNull);
      }
      expect(probe.fields, isNotEmpty);
      expect(probe.flutterFinder, 'byType:sanity-only');
    });
  }
  // Registration preserves legacy geometry/fields. Runtime ownership still
  // needs the exact producer/current-frame helpers on each backend.
  for (final recipe in [
    (
      component: 'responsive-row-column',
      variant: 'default',
      source: BoxObservationSourceSpec.responsiveFlexLayoutHost,
    ),
    (
      component: 'responsive-row-column',
      variant: 'desktop',
      source: BoxObservationSourceSpec.responsiveFlexLayoutHost,
    ),
    (
      component: 'responsive-container',
      variant: 'default',
      source: BoxObservationSourceSpec.responsiveContainerContentInset,
    ),
    (
      component: 'responsive-grid',
      variant: 'default',
      source: BoxObservationSourceSpec.responsiveGridLayoutHost,
    ),
    (
      component: 'responsive-grid',
      variant: 'span',
      source: BoxObservationSourceSpec.responsiveGridLayoutHost,
    ),
    (
      component: 'stack-layout',
      variant: 'default',
      source: BoxObservationSourceSpec.stackLayoutOverlapHost,
    ),
    (
      component: 'indexed-switcher',
      variant: 'default',
      source: BoxObservationSourceSpec.indexedSwitcherLayoutHost,
    ),
    (
      component: 'swap',
      variant: 'default',
      source: BoxObservationSourceSpec.swapOverlapLayoutHost,
    ),
    (
      component: 'swap',
      variant: 'rotate',
      source: BoxObservationSourceSpec.swapOverlapLayoutHost,
    ),
    (
      component: 'divider',
      variant: 'with-child',
      source: BoxObservationSourceSpec.dividerLabelledSequenceHost,
    ),
  ]) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme keeps legacy probes',
        () {
          final key =
              '${recipe.component}-${recipe.variant}-$theme-defaultStyle';
          final probes = captureProbes(
            key: key,
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'unchanged-legacy-constructor',
          );
          final root = probes.firstWhere((probe) => probe.role == 'root');
          final legacy = rootProbeSpec(
            key: key,
            flutterClassName: 'unchanged-legacy-constructor',
          );
          expect(root.boxObservationSource, recipe.source);
          expect(root.fields, legacy.fields);
          expect(root.nativeBoxSource, legacy.nativeBoxSource);
          if (recipe.component == 'responsive-container') {
            expect(probes.map((probe) => probe.role), ['root', 'stage']);
            expect(root.flutterFinder, 'leadingAlignChild');
            expect(root.webSelector, '[data-parity-key="$key"] > * > *');
            final stage = probes.singleWhere((probe) => probe.role == 'stage');
            expect(stage.flutterFinder, 'previewRoot');
            expect(stage.webSelector, legacy.webSelector);
            expect(stage.boxObservationSource, isNull);
            expect(
              stage.fields.map((field) => field.name),
              unorderedEquals(['widthPx', 'heightPx']),
            );
          } else {
            expect(probes, hasLength(1));
            expect(root.flutterFinder, legacy.flutterFinder);
            expect(root.webSelector, legacy.webSelector);
          }
          expect(
            () => requireCaptureProbes(
              component: 'stat',
              variant: 'default',
              roles: probes.map((probe) => probe.role),
              boxObservationSources: probes.map(
                (probe) => probe.boxObservationSource,
              ),
            ),
            throwsFormatException,
          );
        },
      );
    }
  }
  test(
    'SizeSpec retains its layout root and declares only its preview field',
    () {
      final scene = DocsScene(
        tag: 'SizeSpec',
        attributes: const {'component': 'button'},
        selections: const [],
        origins: const ['source-fixture:SizeSpec'],
      );
      final declared = captureProbes(
        key: 'size-unit',
        component: 'button',
        variant: scene.reference,
        flutterClassName: scene.flutterOwnerType,
        docsScene: scene,
      ).single;
      final withoutSource = captureProbes(
        key: 'size-unit',
        component: 'button',
        variant: scene.reference,
        flutterClassName: scene.flutterOwnerType,
      ).single;
      expect(
        declared.boxObservationSource,
        BoxObservationSourceSpec.docsSizePreview,
      );
      expect(withoutSource.boxObservationSource, isNull);
      expect(declared.webSelector, withoutSource.webSelector);
      expect(declared.flutterFinder, 'byType:FlutterDocsSizeSpec');
      expect(declared.fields, withoutSource.fields);
      expect(declared.nativeBoxSource, withoutSource.nativeBoxSource);
    },
  );
  test(
    'a whole-card declaration requires the actual source scene contract',
    () {
      final card = DocsScene(
        tag: 'Card',
        attributes: const {'component': 'button'},
        selections: const [],
        origins: const ['source-fixture:Card'],
        nativeCardAttributes: const {'component': 'button'},
        nativeCardBody: 'Authored caption',
      );
      final valid = captureProbes(
        key: 'card-unit',
        component: 'button',
        variant: card.reference,
        flutterClassName: card.flutterOwnerType,
        docsScene: card,
      ).single;
      expect(valid.boxObservationSource, BoxObservationSourceSpec.wholeDocCard);
      final nameOnly = captureProbes(
        key: 'name-only',
        component: 'button',
        variant: card.reference,
        flutterClassName: 'FlutterDocsCardView',
      ).single;
      expect(nameOnly.boxObservationSource, isNull);
      expect(nameOnly.webSelector, contains('docs-card'));
      expect(nameOnly.fields, valid.fields);
      expect(
        () => captureProbes(
          key: 'wrong-scene',
          component: 'button',
          variant: 'docs-v2-not-the-source-scene',
          flutterClassName: card.flutterOwnerType,
          docsScene: card,
        ),
        throwsFormatException,
      );
    },
  );
  test('a different card index cannot declare the single source unit', () {
    for (final scene in [
      DocsScene(
        tag: 'Card',
        attributes: const {'component': 'button'},
        selections: const [],
        origins: const ['other-index:Card'],
        cardIndex: 1,
        nativeCardAttributes: const {'component': 'button'},
        nativeCardBody: 'Authored caption',
      ),
    ]) {
      expect(
        captureProbes(
          key: 'unsupported-card',
          component: 'button',
          variant: scene.reference,
          flutterClassName: scene.flutterOwnerType,
          docsScene: scene,
        ).single.boxObservationSource,
        isNull,
      );
    }
  });
  test('eligibility never uses agreement of numeric padding values', () {
    const source = BoxObservationSourceSpec.outlined;
    final native = <String, Object?>{
      'status': 'source-complete',
      'source': source.toJson(),
      'sourceUnitValidated': true,
      'legacyRoleEligible': true,
      'value': [16, 16, 16, 16],
    };
    final web = <String, Object?>{
      'status': 'source-complete',
      'source': source.toJson(),
      'sourceUnitValidated': true,
      'value': [24, 24, 24, 24],
    };
    expect(
      boxObservationPairGate(
        expected: source,
        native: native,
        web: web,
      ).eligible,
      isTrue,
    );
    expect(
      boxObservationPairGate(
        expected: source,
        native: {...native, 'legacyRoleEligible': false},
        web: web,
      ).eligible,
      isFalse,
    );
    expect(
      boxObservationPairGate(
        expected: source,
        native: native,
        web: {'status': 'incomplete'},
      ).eligible,
      isFalse,
    );
  });
  test('missing proof and mismatched sources never become eligible', () {
    const expected = BoxObservationSourceSpec.outlined;
    final complete = <String, Object?>{
      'status': 'source-complete',
      'source': expected.toJson(),
      'sourceUnitValidated': true,
      'legacyRoleEligible': true,
    };
    for (final invalid in <Map<String, Object?>>[
      {...complete, 'sourceUnitValidated': false},
      {...complete, 'source': null},
      {
        ...complete,
        'source': {'schemaVersion': 1},
      },
      {...complete, 'source': BoxObservationSourceSpec.docsStage.toJson()},
    ]) {
      expect(
        boxObservationPairGate(
          expected: expected,
          native: complete,
          web: invalid,
        ).eligible,
        isFalse,
      );
    }
  });
}

const _kRecipes = <(String, String)>[
  ('progress', 'tone'),
  ('chat', 'default'),
  ('chat', 'plain'),
  ('chat', 'tail-corner'),
  ('chat', 'tail-top'),
  ('chip', 'selected'),
  ('chip', 'variant'),
  ('chip', 'shape'),
  ('chip', 'cast-motion'),
  ('chip', 'prefix'),
  ('skeleton', 'default'),
  ('step-item', 'default'),
];

const _kLiteralSource = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'classic-compound-showcase-allocation-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
  'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
};

void _showcaseAllocationTests() {
  test('compound showcase allocation has the independent literal tuple', () {
    const source = BoxObservationSourceSpec.showcaseAllocationHost;
    expect(source.toJson(), _kLiteralSource);
    expect(source.validationError, isNull);
  });
  for (final recipe in _kRecipes) {
    for (final style in CoreSurfaceStyleId.values) {
      test('$recipe/${style.name} declaration stays exact', () {
        final probes = captureProbes(
          key: '${recipe.$1}-${recipe.$2}-light-${style.name}',
          component: recipe.$1,
          variant: recipe.$2,
          flutterClassName: 'actual-canonical',
        );
        expect(probes, hasLength(1));
        expect(probes.single.boxObservationSource?.toJson(), _kLiteralSource);
        expect(
          () => requireCaptureProbes(
            component: recipe.$1,
            variant: recipe.$2,
            roles: const ['root'],
            boxObservationSources: [probes.single.boxObservationSource],
          ),
          returnsNormally,
        );
      });
    }
  }
  test('remaining twelve nullable/product roots remain undeclared', () {
    for (final recipe in [
      ('progress', 'default'),
      ('progress', 'labelled'),
      ('progress', 'segments'),
      ('progress', 'indeterminate'),
      ('progress', 'radial'),
      ('accordion', 'default'),
    ]) {
      final probe = captureProbes(
        key: 'held',
        component: recipe.$1,
        variant: recipe.$2,
        flutterClassName: 'held',
      ).single;
      expect(probe.boxObservationSource, isNull);
      expect(
        () => requireCaptureProbes(
          component: recipe.$1,
          variant: recipe.$2,
          roles: const ['root'],
          boxObservationSources: [
            BoxObservationSourceSpec.showcaseAllocationHost,
          ],
        ),
        throwsFormatException,
      );
    }
  });
  for (final field in [
    'schemaVersion',
    'quantityId',
    'nativeAdapterId',
    'webAdapterId',
  ]) {
    test('allocation rejects malformed $field', () {
      final wire = {
        ..._kLiteralSource,
        field: field == 'schemaVersion' ? 2 : 'foreign',
      };
      expect(
        BoxObservationSourceSpec.fromJson(wire).validationError,
        isNotNull,
      );
    });
  }
}

void _additionalShowcaseAllocationTests() {
  const source = BoxObservationSourceSpec.showcaseAllocationHost;
  test('existing showcase tuple remains exact for additional recipes', () {
    expect(source.toJson(), const {
      'schemaVersion': 1,
      'logicalUnitId': 'classic-compound-showcase-allocation-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
      'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
    });
    expect(source.validationError, isNull);
  });
  const recipes = <(String, String)>[
    ('card-image', 'default'),
    ('hidden', 'default'),
    ('window', 'default'),
    ('draggable-panel', 'default'),
    ('draggable-panel', 'outside'),
    ('scrollable-client', 'default'),
    ('table', 'scrollable'),
    ('mockup-foldable', 'angle'),
    ('mockup-foldable', 'default'),
    ('scaffold', 'default'),
    ('bottom-action-bar', 'scaffold'),
    ('scrollview', 'default'),
    ('app-bar', 'glass'),
    ('app-bar', 'foldable'),
    ('swipe-actions', 'scope'),
  ];
  for (final recipe in recipes) {
    for (final style in CoreSurfaceStyleId.values) {
      for (final theme in ['light', 'dark']) {
        test('$recipe/$theme/${style.name} retains its original root', () {
          final key = '${recipe.$1}-${recipe.$2}-$theme-${style.name}';
          final actual = captureProbes(
            key: key,
            component: recipe.$1,
            variant: recipe.$2,
            flutterClassName: 'UnchangedFinder',
          );
          expect(actual, hasLength(1));
          expect(actual.single.boxObservationSource, source);
          expect(
            actual.single.toJson()..remove('boxObservationSource'),
            rootProbeSpec(
              key: key,
              flutterClassName: 'UnchangedFinder',
            ).toJson(),
          );
        });
      }
    }
  }
  test('additional showcase routes cannot be borrowed or malformed', () {
    for (final recipe in const [
      ('card-image', 'chain'),
      ('hidden', 'chain'),
      ('window', 'chain'),
      ('draggable-panel', 'unreviewed'),
      ('scrollable-client', 'chain'),
      ('chat', 'unreviewed-allocation'),
      ('mockup-foldable', 'unreviewed'),
      ('scaffold', 'unreviewed'),
      ('bottom-action-bar', 'unreviewed'),
      ('scrollview', 'unreviewed'),
      ('app-bar', 'unreviewed-allocation'),
      ('swipe-actions', 'default'),
      ('card', 'default'),
      ('hidden', 'docs-v2-unreviewed'),
    ]) {
      expect(
        () => requireCaptureProbes(
          component: recipe.$1,
          variant: recipe.$2,
          roles: const ['root'],
          boxObservationSources: const [source],
        ),
        throwsFormatException,
      );
    }
    for (final change in <Map<String, Object?>>[
      {'schemaVersion': 2},
      {'quantityId': 'product-padding'},
      {'nativeAdapterId': 'foreign'},
      {'webAdapterId': 'foreign'},
    ]) {
      final wrong = BoxObservationSourceSpec.fromJson({
        ...source.toJson(),
        ...change,
      });
      expect(wrong.validationError, isNotNull);
      expect(
        () => requireCaptureProbes(
          component: 'hidden',
          variant: 'default',
          roles: const ['root'],
          boxObservationSources: [wrong],
        ),
        throwsFormatException,
      );
    }
  });
}
