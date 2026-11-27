import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/probe_spec.dart';

void main() {
  const sources = [
    ...BoxObservationSourceSpec.structuredRootFrames,
    ...BoxObservationSourceSpec.validationViewportFrames,
  ];

  test('structured units reject adapters from another semantic unit', () {
    for (final source in sources) {
      expect(source.validationError, isNull);
      expect(source.quantityId, BoxObservationSourceSpec.quantity);
      for (final other in sources.where((other) => other != source)) {
        expect(
          BoxObservationSourceSpec(
            schemaVersion: source.schemaVersion,
            logicalUnitId: source.logicalUnitId,
            quantityId: source.quantityId,
            nativeAdapterId: other.nativeAdapterId,
            webAdapterId: source.webAdapterId,
          ).validationError,
          'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
        );
        expect(
          BoxObservationSourceSpec(
            schemaVersion: source.schemaVersion,
            logicalUnitId: source.logicalUnitId,
            quantityId: source.quantityId,
            nativeAdapterId: source.nativeAdapterId,
            webAdapterId: other.webAdapterId,
          ).validationError,
          'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
        );
      }
    }
  });

  test('a registered source cannot be attached to an unrelated recipe', () {
    for (final source in sources) {
      expect(
        () => requireCaptureProbes(
          component: 'button',
          variant: 'default',
          roles: const ['root'],
          boxObservationSources: [source],
        ),
        throwsFormatException,
      );
    }
  });

  const recipes = <(String, String, BoxObservationSourceSpec)>[
    ('basic', 'default', BoxObservationSourceSpec.basicContentInset),
    (
      'disclosure-badge',
      'default',
      BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
    ),
    (
      'disclosure-badge',
      'commitment',
      BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
    ),
    (
      'multiple-choice',
      'default',
      BoxObservationSourceSpec.multipleChoiceLayoutHost,
    ),
    ('page-header', 'default', BoxObservationSourceSpec.pageHeaderLayoutHost),
    ('sidebar', 'default', BoxObservationSourceSpec.sidebarOuterLayoutHost),
    ('sidebar', 'two-pane', BoxObservationSourceSpec.sidebarOuterLayoutHost),
    ('sidebar', 'collapsed', BoxObservationSourceSpec.sidebarOuterLayoutHost),
    ('tab-pane', 'default', BoxObservationSourceSpec.tabPaneBarContentInset),
    (
      'tab-pane',
      'editor-strip',
      BoxObservationSourceSpec.tabPaneBarContentInset,
    ),
    ('tree', 'default', BoxObservationSourceSpec.treeOuterLayoutHost),
    ('tree', 'selected', BoxObservationSourceSpec.treeOuterLayoutHost),
    ('tree', 'trailing', BoxObservationSourceSpec.treeOuterLayoutHost),
    (
      'timeline',
      'default',
      BoxObservationSourceSpec.timelineSequenceLayoutHost,
    ),
    (
      'category-breakdown',
      'default',
      BoxObservationSourceSpec.categoryBreakdownLayoutHost,
    ),
    (
      'category-breakdown',
      'donut',
      BoxObservationSourceSpec.categoryBreakdownLayoutHost,
    ),
    (
      'trend-chart',
      'default',
      BoxObservationSourceSpec.trendChartOuterLayoutHost,
    ),
    ('trend-chart', 'bar', BoxObservationSourceSpec.trendChartOuterLayoutHost),
    (
      'window-panel',
      'default',
      BoxObservationSourceSpec.windowPanelFrameContentInset,
    ),
    ('formatter', 'default', BoxObservationSourceSpec.textFieldContentInset),
    ('validated', 'default', BoxObservationSourceSpec.validatedLayoutHost),
    (
      'validator-hint',
      'default',
      BoxObservationSourceSpec.validatorHintMessageLayoutHost,
    ),
    (
      'scroll-area',
      'default',
      BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
    ),
    (
      'fade-scroll',
      'default',
      BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
    ),
    (
      'fade-scroll',
      'horizontal',
      BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
    ),
    (
      'fade-scroll',
      'with-scrollbar',
      BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
    ),
    (
      'overflow-marquee',
      'default',
      BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
    ),
    ('kbd', 'default', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
    ('kbd', 'combo', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
    ('kbd', 'four', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
    ('hover', 'shadow', BoxObservationSourceSpec.hoverEffectHost),
  ];
  test(
    'only the reviewed thirty-one recipes declare the structured sources',
    () {
      expect(recipes, hasLength(31));
      for (final (component, variant, source) in recipes) {
        for (final key in ['caller-owned-key', 'rawStyle:arbitrary']) {
          final probe = captureProbes(
            key: key,
            component: component,
            variant: variant,
            flutterClassName: 'public-constructor',
          ).single;
          expect(probe.boxObservationSource, source);
          final payload = probe.toJson()..remove('boxObservationSource');
          expect(
            payload,
            rootProbeSpec(
              key: key,
              flutterClassName: 'public-constructor',
            ).toJson(),
          );
          expect(
            () => requireCaptureProbes(
              component: component,
              variant: variant,
              roles: [probe.role],
              boxObservationSources: [source],
            ),
            returnsNormally,
          );
        }
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: 'unproved',
            roles: ['root'],
            boxObservationSources: [source],
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('private, callbacks and unproved recipes retain no source grant', () {
    for (final (component, variant) in <(String, String)>[
      ('disclosure-badge', 'private'),
      ('dock', 'chain'),
      ('rich-editor', 'default'),
      ('rich-editor', 'toolbar'),
      ('tree', 'unknown-callback'),
      ('tab-pane', 'unknown'),
      ('formatter', 'unknown'),
      ('kbd', 'unknown'),
      ('hover', 'scale-down'),
      ('hover', 'brighten'),
    ]) {
      expect(
        captureProbes(
          key: 'arbitrary-key',
          component: component,
          variant: variant,
          flutterClassName: 'public-constructor',
        ).single.boxObservationSource,
        isNull,
      );
    }
  });
}
